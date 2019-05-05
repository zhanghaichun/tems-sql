DROP PROCEDURE IF EXISTS SP_FILL_CURRENT_AMOUNT;
CREATE PROCEDURE SP_FILL_CURRENT_AMOUNT()

BEGIN

  DECLARE V_OLD_PROPOSAL_ID INT;
  DECLARE V_NEW_PROPOSAL_ID INT;

  DECLARE V_ACCOUNT_NUMBER VARCHAR(255);
  DECLARE V_STRIPPED_CIRCUIT_NUMBER VARCHAR(255);
  DECLARE V_CURRENT_AMOUNT DOUBLE(20, 5);
  DECLARE V_KEY_FIELD VARCHAR(128); -- 程序中用到的 key field.

  DECLARE V_USOC VARCHAR(32);
  DECLARE V_LINE_ITEM_CODE VARCHAR(32);
  DECLARE V_LINE_ITEM_CODE_DESCRIPTION VARCHAR(255);
  DECLARE V_ITEM_DESCRIPTION VARCHAR(255);

  DECLARE V_BAN_ID INT;

  DECLARE V_SERVICE_TYPE VARCHAR(255);


  
  DECLARE V_DONE BOOLEAN DEFAULT FALSE;

  DECLARE V_FILL_CURRENT_AMOUNT_CURSOR CURSOR FOR 
    SELECT 
      old_proposal_id,
      account_number,
      stripped_circuit_number,
      usoc,
      line_item_code,
      line_item_code_description,
      item_description
    FROM current_amount_fill
    ORDER BY id ASC;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_DONE = TRUE;

  -- 更新 service type.
  /*UPDATE current_amount_fill c
    LEFT JOIN proposal p ON c.old_proposal_id = p.id
    LEFT JOIN invoice_item ii ON p.invoice_item_id = ii.id
  SET c.service_type = ii.service_type
  WHERE  p.rec_active_flag = 'Y'
    AND ii.rec_active_flag = 'Y'
    AND p.proposal_flag = 1;*/


  DROP TABLE IF EXISTS tmp_proposal_current_amount;
  CREATE TEMPORARY TABLE tmp_proposal_current_amount(
      proposal_id INT, 
      new_proposal_id INT,
      current_amount DOUBLE(20, 5),
      service_type VARCHAR(255)
    );

  OPEN V_FILL_CURRENT_AMOUNT_CURSOR;

    READLOOP: LOOP

      FETCH V_FILL_CURRENT_AMOUNT_CURSOR 
        INTO 
          V_OLD_PROPOSAL_ID,
          V_ACCOUNT_NUMBER,
          V_STRIPPED_CIRCUIT_NUMBER,
          V_USOC,
          V_LINE_ITEM_CODE,
          V_LINE_ITEM_CODE_DESCRIPTION,
          V_ITEM_DESCRIPTION;

      IF V_DONE THEN
        LEAVE READLOOP;
      END IF;

      
      SET V_KEY_FIELD = (
          SELECT arm.key_field
          FROM proposal p
            LEFT JOIN invoice_item ii ON ii.id = p.invoice_item_id
            LEFT JOIN audit_reference_mapping arm ON arm.id = p.audit_reference_mapping_id
          WHERE p.rec_active_flag = 'Y'
            AND arm.rec_active_flag =  'Y'
            AND p.id = V_OLD_PROPOSAL_ID
            AND p.proposal_flag = 1
        );

      SET V_BAN_ID = (
          SELECT id FROM ban 
          WHERE rec_active_flag = 'Y'
            AND account_number = V_ACCOUNT_NUMBER
            AND ban_status_id = 1
          LIMIT 1
        );

      INSERT INTO tmp_proposal_current_amount(
          proposal_id,
          new_proposal_id,
          current_amount,
          service_type
        )
      SELECT 
        V_OLD_PROPOSAL_ID, 
        p.id,  
        IF(
          p.invoice_item_id IS NULL , 
          0 , 
          (
            IF(
                p.dispute_id IS NOT NULL ,
                (IFNULL(p.payment_amount,0) + IFNULL(p.dispute_amount,0) ),
                (IFNULL(p.payment_amount,0) + IFNULL(p.credit_amount,0) )
              )
          )
        ),
        ii.service_type
      FROM proposal p
        LEFT JOIN invoice_item ii ON ii.id = p.invoice_item_id
        LEFT JOIN invoice i ON ii.invoice_id = i.id
      WHERE p.rec_active_flag = 'Y'
        AND i.ban_id = V_BAN_ID
        AND ii.stripped_circuit_number = V_STRIPPED_CIRCUIT_NUMBER
        AND i.invoice_date BETWEEN '2019-01-01' AND '2019-01-31'
        AND ( p.item_type_id = 13 OR p.item_type_id LIKE '3%' )
        AND (
            CASE 
              WHEN V_KEY_FIELD = 'usoc' THEN

                p.usoc = V_USOC

              WHEN V_KEY_FIELD = 'line_item_code' THEN

                ii.line_item_code = V_LINE_ITEM_CODE

              WHEN V_KEY_FIELD IN ('line_item_code_description', 'stripped_circuit_number & line_item_code_description') THEN
                
                  ii.line_item_code_description LIKE V_LINE_ITEM_CODE_DESCRIPTION
                  OR 
                  ii.description LIKE V_LINE_ITEM_CODE_DESCRIPTION
                

              WHEN V_KEY_FIELD IN ('item_description', 'stripped_circuit_number & item_description') THEN

                
                  ii.description LIKE CONCAT('%',V_ITEM_DESCRIPTION,'%')
                  OR 
                  ii.item_name LIKE CONCAT('%',V_ITEM_DESCRIPTION,'%')

              ELSE
                1 = 1

            END
          )
        AND p.proposal_flag = 1
      LIMIT 1;

    END LOOP READLOOP;

  CLOSE V_FILL_CURRENT_AMOUNT_CURSOR;


  /*select * from tmp_proposal_current_amount
  order by proposal_id asc;*/

  UPDATE current_amount_fill
  SET 
    new_proposal_id = NULL,
    current_amount = NULL,
    service_type = NULL;

  UPDATE current_amount_fill c, tmp_proposal_current_amount t
  SET
    c.new_proposal_id = t.new_proposal_id,
    c.current_amount = t.current_amount,
    c.service_type = t.service_type

  WHERE c.old_proposal_id = t.proposal_id;

END;

