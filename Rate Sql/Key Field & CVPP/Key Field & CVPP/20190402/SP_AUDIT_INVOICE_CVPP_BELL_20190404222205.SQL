DROP PROCEDURE IF EXISTS SP_AUDIT_INVOICE_CVPP_BELL;
CREATE PROCEDURE `SP_AUDIT_INVOICE_CVPP_BELL`(V_INVOICE_ID INT(11))
BEGIN
  DECLARE V_SUMMARY_VENDOR_NAME     VARCHAR(128);
  DECLARE V_IS_NRC                  INT(11);

  -- MRC
  DECLARE V_EXPECT_AMOUNT_MRC       DOUBLE(20, 5) DEFAULT 0;

  -- NRC (NOT MRC: OCC,Credit,Adjustment)
  DECLARE V_EXPECT_AMOUNT_NOT_MRC   DOUBLE(20, 5) DEFAULT 0;

 
  DECLARE BELL_EXPECT_AMOUNT        DOUBLE(20, 5) DEFAULT 0;

  DECLARE BELL_ACTUAL_AMOUNT        DOUBLE(20, 5) DEFAULT 0;


  DECLARE V_AUDIT_STATUS_ID         INT(11);

  DECLARE V_NOTE                    VARCHAR(128) DEFAULT '';

	DECLARE V_DIFFERENCE DOUBLE(20,5);

  DECLARE V_ACTIVE_CVPP_DISCOUNT DOUBLE(20, 5);
  DECLARE V_CVPP_DISCOUNT_DATE DATE;

  DROP TABLE IF EXISTS tmp_cvpp_proposal;
  CREATE TEMPORARY TABLE tmp_cvpp_proposal(
    proposal_id bigint,
    discount_flag char(1),
    item_amount DOUBLE(20, 5)
  );
      
	SELECT value 
		INTO V_DIFFERENCE
	FROM sys_config WHERE parameter = 'audit_tolerance_amount_cvpp';
      
  SET V_SUMMARY_VENDOR_NAME = (
      SELECT v.summary_vendor_name
      FROM vendor v, invoice i
      WHERE i.vendor_id = v.id AND i.id = V_INVOICE_ID
    );

  -- MRC : Expect discount sum
  IF V_SUMMARY_VENDOR_NAME = 'BELL CANADA' THEN

    INSERT INTO tmp_cvpp_proposal (proposal_id, discount_flag, item_amount)
    SELECT p.id, 'N', (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0))
    FROM proposal p, invoice i, ban b
    WHERE i.id = p.invoice_id
      AND i.ban_id = b.id
      AND p.invoice_id = V_INVOICE_ID
      AND (p.item_type_id IN (13) OR p.item_type_id LIKE '3%')
      AND (
        (b.account_number = 'B1ES2A5201102' AND p.usoc IN('1HWNS','1HWMS') )
        OR 
        (b.account_number = 'B1ES4A0318555' AND p.usoc = '1HWMS')
        OR 
        (b.account_number = 'B1ES9A8501304' AND p.usoc = '1HWNS')
        OR 
        (b.account_number = 'B1ES9B1616135' AND p.usoc = '1HWMS')
        OR 
        (b.account_number = 'B1FS1Q0911102' AND p.usoc IN('1HWNS','1HWMS'))
        OR 
        (b.account_number = 'B1FS4O1823165' AND p.usoc = '1HWMS')
        OR 
        (b.account_number = 'B1FS7A0031555' AND p.usoc = '1HWMS')
        OR 
        (b.account_number = 'N9550000' AND p.usoc = 'MPDSB')
        OR (
              p.usoc IN ('DTBD1', 'M3ABA', 'MGSD1', 'MGSL4', 'MPAC1', 'MPACD',
                        'MPDS1', 'MPDS3', 'MPDSA', 'MPDSP', 'MPDSR', 'MRSPT', 'MTBPT')
              AND 
              b.account_number = 'T6011329'
            )
      )
      AND p.proposal_flag = 1
      AND p.rec_active_flag = 'Y';
                    
  ELSEIF V_SUMMARY_VENDOR_NAME = 'ALIANT' THEN

    INSERT INTO tmp_cvpp_proposal (proposal_id, discount_flag, item_amount)
    SELECT p.id, 'N', (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0))
    FROM proposal p
    WHERE p.invoice_id = V_INVOICE_ID
      AND (p.item_type_id IN (13) OR p.item_type_id LIKE '3%')
      AND (
        p.description LIKE '%INTER OFFICE DIGITAL CHANNEL DS-0%'
        OR p.description LIKE '%INTER-OFFICE DIGITAL CHANNEL DS-0%'
      )
      AND p.proposal_flag = 1
      AND p.rec_active_flag = 'Y';

  END IF;

  INSERT INTO tmp_cvpp_proposal (proposal_id, discount_flag, item_amount)
  SELECT p.id, 'N', (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0))
  FROM proposal p
  WHERE p.invoice_id = V_INVOICE_ID
    AND (p.item_type_id IN (15) OR p.item_type_id LIKE '5%')
    AND p.usoc IN ('1HWNS','MPDSB','DTBD1','M3ABA','MGSD1','MGSL4','MPAC1',
                    'MPACD','MPDS1','MPDS3','MPDSA','MPDSP','MPDSR','MRSPT','MTBPT')
    AND (
      p.description LIKE '%CREDIT FOR ACCESS SERVICE REMOVED%'
      OR p.description LIKE '%CREDIT FOR SERVICE REMOVED%'
      OR p.description LIKE '%CHARGE FOR ACCESS SERVICE ADDED%'
      OR p.description LIKE '%CHARGE FOR SERVICE ADDED%'
    )
    AND p.proposal_flag = 1
    AND p.rec_active_flag = 'Y';

  -- 获取 discount date, 用这个字段获取有效的 discount 值。
  SET V_CVPP_DISCOUNT_DATE = ( 
      SELECT invoice_date
      FROM invoice
      WHERE rec_active_flag = 'Y'
        AND id = V_INVOICE_ID 
    );

  -- 获取有效的 discount.
  SELECT discount INTO V_ACTIVE_CVPP_DISCOUNT
  FROM rate_rule_contract_original
  WHERE rec_active_flag = 'Y'
    AND key_field LIKE '%CVPP%'
    AND summary_vendor_name = 'BELL CANADA'
    AND rate_effective_date <= V_CVPP_DISCOUNT_DATE
    ORDER BY rate_effective_date DESC
  LIMIT 1;

  -- 计算 Expect Amount.
  /*SET BELL_EXPECT_AMOUNT = IFNULL(
      ( SELECT SUM(item_amount) FROM tmp_cvpp_proposal WHERE discount_flag = 'N' ),
      0
    ) * 0.22 * -1;*/

  -- 计算 Expect Amount.
  SET BELL_EXPECT_AMOUNT = IFNULL(
      ( SELECT SUM(item_amount) FROM tmp_cvpp_proposal WHERE discount_flag = 'N' ),
      0
    ) * V_ACTIVE_CVPP_DISCOUNT * -1;
          
      
  IF V_SUMMARY_VENDOR_NAME = 'BELL CANADA' THEN

    INSERT INTO tmp_cvpp_proposal (proposal_id, discount_flag, item_amount)
    SELECT p.id, 'Y', (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0))
    FROM proposal p, invoice_item ii, invoice i, ban b
    WHERE p.invoice_item_id = ii.id
      AND i.id = ii.invoice_id
      AND i.ban_id = b.id
      AND p.invoice_id = V_INVOICE_ID
      AND (
        (b.account_number IN ('N9550000', 'T6011329') AND p.description LIKE '%CVPP DISCOUNT%')
        OR (
          b.account_number IN ('B1FS1Q0911102', 'B1ES4A0318555', 'B1FS7A0031555',
                                  'B1ES2A5201102', 'B1ES9B1616135', 'B1ES9A8501304', 'B1FS4O1823165')
          AND 
          ii.phrase_code = 'E46'
        )
      )
      AND (p.item_type_id = 15 OR p.item_type_id LIKE '5%')
      AND p.proposal_flag = 1
      AND p.rec_active_flag = 'Y'
      AND p.payment_amount <= 0
      AND p.credit_amount <= 0;
      
  ELSEIF V_SUMMARY_VENDOR_NAME = 'ALIANT' THEN

    INSERT INTO tmp_cvpp_proposal (proposal_id, discount_flag, item_amount)
    SELECT p.id, 'Y', (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0))
    FROM proposal p, invoice_item ii
    WHERE p.invoice_item_id = ii.id
      AND p.invoice_id = V_INVOICE_ID
      AND p.description LIKE '%CVPP DISCOUNT%'
      AND (p.item_type_id = 15 OR p.item_type_id LIKE '5%')
      AND p.proposal_flag = 1
      AND p.rec_active_flag = 'Y'
      AND p.payment_amount <= 0
      AND p.credit_amount <= 0;

  END IF;

  SET BELL_ACTUAL_AMOUNT = (SELECT SUM(item_amount) FROM tmp_cvpp_proposal WHERE discount_flag = 'Y');
  
  SET BELL_EXPECT_AMOUNT = ROUND(IFNULL(BELL_EXPECT_AMOUNT,0),2);
  SET BELL_ACTUAL_AMOUNT = ROUND(IFNULL(BELL_ACTUAL_AMOUNT,0),2);
  
  IF ABS(BELL_EXPECT_AMOUNT - BELL_ACTUAL_AMOUNT) <= V_DIFFERENCE THEN
     SET V_AUDIT_STATUS_ID = 1;
  ELSE
     SET V_AUDIT_STATUS_ID = 2;
  END IF;

  SET V_NOTE = CONCAT('The tolerance for CVPP validation is +/- $',FORMAT(V_DIFFERENCE,2));

  INSERT INTO audit_result(
      invoice_id,
      audit_status_id,
      audit_source_id,
      actual_amount,
      expect_amount,
      audit_reference_type_id,
      notes,
      created_timestamp
    )
  VALUES (
      V_INVOICE_ID,
      V_AUDIT_STATUS_ID,
      9202,
      BELL_ACTUAL_AMOUNT,
      BELL_EXPECT_AMOUNT,
      12,
      V_NOTE,
      NOW()
    );
              
  /*INSERT INTO audit_result(
      invoice_id,
      proposal_id,
      audit_status_id,
      audit_source_id,
      actual_amount,
      expect_amount,
      audit_reference_type_id,
      notes,
      created_timestamp
    )
  SELECT 
    V_INVOICE_ID,
    proposal_id,
    V_AUDIT_STATUS_ID,
    9201,
    BELL_ACTUAL_AMOUNT,
    BELL_EXPECT_AMOUNT,
    12,
    V_NOTE,
    NOW()
  FROM tmp_cvpp_proposal;*/

END;