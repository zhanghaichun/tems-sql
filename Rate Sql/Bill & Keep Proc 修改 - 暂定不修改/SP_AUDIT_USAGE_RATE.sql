DROP PROCEDURE IF EXISTS SP_AUDIT_USAGE_RATE;
CREATE PROCEDURE SP_AUDIT_USAGE_RATE( V_INVOICE_ID INT(11) )

BEGIN

 /**
  * 对系统中的 usage 类型数据进行验证：
  * 但是当 reference_type 为 tariff 时， 要考虑到剔除 bill_keep_ban tariff rules.
  */
  DECLARE V_COUNT INT;

  DECLARE V_PROPOSAL_ID INT;
  DECLARE V_AUDIT_REFERENCE_ID INT;

  DECLARE V_ITEM_NAME VARCHAR(256);
  DECLARE V_AUDIT_REFERENCE_TYPE_ID INT;
  DECLARE V_ACTUAL_AMOUNT DOUBLE(20,5) DEFAULT 0;
  DECLARE V_EXPECT_AMOUNT DOUBLE(20,5) DEFAULT 0;
  DECLARE V_ACTUAL_RATE DOUBLE(20,5) DEFAULT 0;

  DECLARE V_EXPECT_RATE DOUBLE(20,5) DEFAULT 0;
  DECLARE V_RATE_EFFECTIVE_DATE DATE;

  DECLARE V_QUANTITY DOUBLE(20,5) DEFAULT 0;
  DECLARE V_MINUTES DOUBLE(20,5) DEFAULT 0;
  DECLARE V_AMOUNT24 DOUBLE(20,5) DEFAULT 0;
  DECLARE V_AUDIT_STATUS_ID INT;
  DECLARE V_ACTUAL_QUANTITY DOUBLE(20,5) DEFAULT 0;
  DECLARE V_EXPECT_QUANTITY DOUBLE(20,5) DEFAULT 0;
  DECLARE V_DIFFERENCE DOUBLE(20,2) DEFAULT 0.01;
  DECLARE V_DIFFERENCE_RATE DOUBLE(20,2) DEFAULT 0;
  DECLARE V_NOTES VARCHAR(256);

  DECLARE V_NOTFOUND INT DEFAULT FALSE;
  DECLARE cur_proposal_item CURSOR FOR
      SELECT
          p.id,
          arm.audit_reference_id,
          p.item_name,
          p.rate AS actual_rate,
          (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0)),
          p.quantity,
          p.minutes,
          ii.amount24,
          arm.audit_reference_type_id
      FROM proposal p
          LEFT JOIN invoice_item ii ON p.invoice_item_id = ii.id
          LEFT JOIN audit_reference_mapping arm ON arm.id = p.audit_reference_mapping_id

      WHERE
          p.invoice_id = V_INVOICE_ID
          AND (p.item_type_id = 14 OR p.item_type_id LIKE '4%')
          AND p.proposal_flag = 1
          AND p.rec_active_flag = 'Y'
          AND arm.key_field != 'bill_keep_ban' -- 剔除 bill_keep_ban tariff mapping rules。 
          AND arm.audit_reference_type_id IN (2, 3);


  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_NOTFOUND = TRUE;

  INSERT INTO event_journal (
                              event_type,
                              ip_address,
                              message_type,
                              event_message,
                              event_data,
                              created_timestamp,
                              created_by
                            )
    VALUES (
              'SP_AUDIT_USAGE_RATE'
              ,V_INVOICE_ID
              ,'INFO'
              ,'Entering Processing Begin: '
              ,NULL
              ,current_timestamp
              ,0
    );

  OPEN cur_proposal_item;
    loop1: LOOP
      FETCH cur_proposal_item INTO
                                  V_PROPOSAL_ID,
                                  V_AUDIT_REFERENCE_ID,
                                  V_ITEM_NAME,
                                  V_ACTUAL_RATE,
                                  V_ACTUAL_AMOUNT,
                                  V_QUANTITY,
                                  V_MINUTES,
                                  V_AMOUNT24,
                                  V_AUDIT_REFERENCE_TYPE_ID;
      IF V_NOTFOUND THEN
              LEAVE loop1;
      END IF;


        -- 根据不同 reference type 获取 rate 值和 rate_effective_date 值
      IF ( V_AUDIT_REFERENCE_TYPE_ID = 2 ) THEN

        CALL SP_GET_RATE_KEY_FIELDS(
                                    'tariff',
                                    V_AUDIT_REFERENCE_ID,
                                    V_PROPOSAL_ID,
                                    V_EXPECT_RATE,
                                    V_RATE_EFFECTIVE_DATE
                                );

      ELSEIF (V_AUDIT_REFERENCE_TYPE_ID = 3) THEN

        CALL SP_GET_RATE_KEY_FIELDS(
                                    'contract',
                                    V_AUDIT_REFERENCE_ID,
                                    V_PROPOSAL_ID,
                                    V_EXPECT_RATE,
                                    V_RATE_EFFECTIVE_DATE
                                );

      END IF;



      -- 根据不同情况赋值 期望数量
      -- 可能从三个地方取 quantity 值， proposal.quantity
      -- proposal.minutes, invoice_item.amount24
          
      IF ROUND(V_QUANTITY * V_ACTUAL_RATE,2) <= V_ACTUAL_AMOUNT  + V_DIFFERENCE
          AND ROUND(V_QUANTITY * V_ACTUAL_RATE,2) >= V_ACTUAL_AMOUNT - V_DIFFERENCE THEN

        SET V_EXPECT_QUANTITY = V_QUANTITY;

      ELSEIF ROUND(V_MINUTES * V_ACTUAL_RATE,2) <= V_ACTUAL_AMOUNT + V_DIFFERENCE
          AND ROUND(V_MINUTES * V_ACTUAL_RATE,2) >= V_ACTUAL_AMOUNT - V_DIFFERENCE THEN

        SET V_EXPECT_QUANTITY = V_MINUTES;

      ELSEIF ROUND(V_AMOUNT24 * V_ACTUAL_RATE,2) <= V_ACTUAL_AMOUNT + V_DIFFERENCE
          AND ROUND(V_AMOUNT24 * V_ACTUAL_RATE,2) >= V_ACTUAL_AMOUNT - V_DIFFERENCE THEN

        SET V_EXPECT_QUANTITY = V_AMOUNT24;

      END IF;

      SET V_EXPECT_AMOUNT = ROUND(V_EXPECT_QUANTITY * V_EXPECT_RATE,2);

      -- 对比期望金额和实际金额，
      -- 得出验证结果。
      IF V_ACTUAL_AMOUNT <= V_EXPECT_AMOUNT + V_DIFFERENCE
          AND V_ACTUAL_AMOUNT >= V_EXPECT_AMOUNT - V_DIFFERENCE THEN
          SET V_AUDIT_STATUS_ID = 1;
      ELSE
          SET V_AUDIT_STATUS_ID = 2;
      END IF;

      -- 赋值验证结果 notes.
      SET V_NOTES = CONCAT(
                              'Actual Rate : ',
                              V_ACTUAL_RATE,
                              ', Expect Rate : ',
                              V_EXPECT_RATE,
                              '</br></br>The tolerance amount is $',
                              V_DIFFERENCE
                      );

      -- 存储审计结果
      INSERT INTO audit_result (
                                  invoice_id,
                                  proposal_id,
                                  audit_status_id,
                                  audit_source_id,
                                  actual_amount,
                                  expect_amount,
                                  rate,
                                  rate_effective_date,
                                  quantity,
                                  audit_reference_type_id,
                                  audit_reference_id,
                                  notes,
                                  created_timestamp,
                                  created_by
                              )
        VALUES (
                  V_INVOICE_ID,
                  V_PROPOSAL_ID,
                  V_AUDIT_STATUS_ID,
                  8010,
                  V_ACTUAL_AMOUNT,
                  V_EXPECT_AMOUNT,
                  V_EXPECT_RATE,
                  V_RATE_EFFECTIVE_DATE,
                  V_EXPECT_QUANTITY,
                  V_AUDIT_REFERENCE_TYPE_ID,
                  V_AUDIT_REFERENCE_ID,
                  V_NOTES,
                  NOW(),
                  0
                );

    END LOOP loop1;
    CLOSE cur_proposal_item;

    COMMIT;

END