DROP PROCEDURE IF EXISTS SP_AUDIT_INVOICE_CVPP_TELUS;
CREATE PROCEDURE `SP_AUDIT_INVOICE_CVPP_TELUS`(V_INVOICE_ID INT(11))
BEGIN
      -- 主要验证的是折扣金额是否相等
      -- cursor flag
      DECLARE done                            INT DEFAULT FALSE;
      DECLARE V_PAYMENT_AMOUNT                DOUBLE(20, 5);
      DECLARE V_PROPOSAL_ID                   INT(11);
      DECLARE V_PROPOSAL_ID_ACTUAL_DISCOUNT   INT(11);
      DECLARE V_TELUS_EXPECT_AMOUNT           DOUBLE(20, 5) DEFAULT 0;
      DECLARE V_TELUS_ACTUAL_AMOUNT           DOUBLE(20, 5) DEFAULT 0;
      DECLARE V_AUDIT_STATUS_ID               INT(11);
      DECLARE V_AUDIT_SOURCE_ID               INT(11);
      DECLARE V_NOTE                          VARCHAR(128) DEFAULT '';

      -- 新旧折扣率和期望折扣率
      DECLARE V_OLD_DISCOUNT_RATE DOUBLE(20, 5) DEFAULT 0.13;
      DECLARE V_NEW_DISCOUNT_RATE DOUBLE(20, 5) DEFAULT 0.11;
      DECLARE V_ACTUAL_DISCOUNT_RATE DOUBLE(20, 5);

      -- 新旧的标识符 （检索实际折扣金额的描述信息）
      DECLARE V_OLD_IDENTIFIER_DESCRIPTION VARCHAR(64) DEFAULT 'CVPP DISCOUNT 13%';
      DECLARE V_NEW_IDENTIFIER_DESCRIPTION VARCHAR(64) DEFAULT 'CVPP DISCOUNT 11%';
      DECLARE V_ACTUAL_IDENTIFIER_DESCRIPTION VARCHAR(64);

      DECLARE V_INVOICE_DATE DATE;
      -- Separate rate 用来决定采用的折扣率是
      -- 哪一个。
      DECLARE V_SEPARATE_INVOICE_DATE DATE DEFAULT '2018-08-31';
      
      DECLARE V_COUNT INT;
      DECLARE V_SUCCESS_COUNT INT;
      DECLARE V_FAILURE_COUNT INT;
      DECLARE V_CANNOT_VALIDATE_COUNT INT;
      DECLARE V_SUM_AMOUNT DOUBLE(20,5) DEFAULT 0;
      DECLARE V_REVENUE_OR_COST DOUBLE(20,5) DEFAULT 0;
      DECLARE V_NOTES_COST VARCHAR(768);

      DECLARE V_DIFFERENCE DOUBLE(20,5);

      -- 期望折扣金额， 相应的明细记录金额的合计。
      DECLARE cur_telus CURSOR FOR 
                              SELECT SUM(IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0)) * V_ACTUAL_DISCOUNT_RATE * -1
                              FROM proposal p, invoice_item ii
                              WHERE p.invoice_item_id = ii.id
                                AND p.invoice_id = V_INVOICE_ID
                                AND ( 
                                      p.item_type_id IN (13, 15)
                                      OR p.item_type_id LIKE '3%'
                                      OR p.item_type_id LIKE '5%'
                                    )
                                AND (
                                      ii.line_item_code IN ('2296M',
                                                            '232M0',
                                                            '243M4',
                                                            '80427',
                                                            '80428',
                                                            '80433',
                                                            '80434',
                                                            '80435',
                                                            '84495',
                                                            '89389',
                                                            '89574')
                                      OR ii.usoc = '1HWNS'
                                    )
                                AND p.proposal_flag = 1
                                AND p.rec_active_flag = 'Y';

      DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
      
      -- 设置验证源标识符
      SET V_AUDIT_SOURCE_ID = 9201;

      -- 检索invoice date
      SET V_INVOICE_DATE = (
                              SELECT invoice_date from invoice
                              WHERE id = V_INVOICE_ID
                          );

      -- 根据 invoice date 条件来赋值不同的 discount rate (折扣率)
      -- 和不同的描述信息。
      IF (V_INVOICE_DATE > V_SEPARATE_INVOICE_DATE) THEN

        SET V_ACTUAL_DISCOUNT_RATE = V_NEW_DISCOUNT_RATE;
        SET V_ACTUAL_IDENTIFIER_DESCRIPTION = V_NEW_IDENTIFIER_DESCRIPTION;

      ELSE
        SET V_ACTUAL_DISCOUNT_RATE = V_OLD_DISCOUNT_RATE;
        SET V_ACTUAL_IDENTIFIER_DESCRIPTION = V_OLD_IDENTIFIER_DESCRIPTION;
      END IF;

      -- 从系统中检索误差率 （金额）
      SELECT value INTO V_DIFFERENCE
      FROM sys_config WHERE parameter = 'audit_tolerance_amount_cvpp';

      -- 设置验证结果注解
      SET V_NOTE = CONCAT('The tolerance for CVPP validation is +/- $', FORMAT(V_DIFFERENCE,2));

      OPEN cur_telus;

     read_loop:
      LOOP
         FETCH cur_telus INTO V_TELUS_EXPECT_AMOUNT;

         IF done
         THEN
            LEAVE read_loop;
         END IF;

          -- 检索计算实际折扣额
          SELECT SUM(IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0))
                 INTO V_TELUS_ACTUAL_AMOUNT
          FROM proposal p
          WHERE p.invoice_id = V_INVOICE_ID
              AND p.description LIKE CONCAT('%', V_ACTUAL_IDENTIFIER_DESCRIPTION, '%')
              AND p.proposal_flag = 1
              AND p.rec_active_flag = 'Y'
              AND p.payment_amount <= 0
              AND p.credit_amount <= 0;

          -- 对 `期望折扣金额` 和 `实际折扣金额` 进行格式化
          SET V_TELUS_EXPECT_AMOUNT = IFNULL(ROUND(V_TELUS_EXPECT_AMOUNT,2),0);
          SET V_TELUS_ACTUAL_AMOUNT = IFNULL(ROUND(V_TELUS_ACTUAL_AMOUNT,2),0);
         
          -- 对比折扣金额， 得出验证结果
          IF ABS(V_TELUS_EXPECT_AMOUNT - V_TELUS_ACTUAL_AMOUNT) <= V_DIFFERENCE THEN
            SET V_AUDIT_STATUS_ID = 1;
          ELSE
            SET V_AUDIT_STATUS_ID = 2;
          END IF;

          -- 插入期望金额明细
          INSERT INTO audit_result(invoice_id,
                                      proposal_id,
                                      audit_status_id,
                                      audit_source_id,
                                      actual_amount,
                                      expect_amount,
                                      audit_reference_type_id,
                                      notes,
                                      created_timestamp)
          SELECT p.invoice_id,
                p.id,
                V_AUDIT_STATUS_ID,
                V_AUDIT_SOURCE_ID,
                V_TELUS_ACTUAL_AMOUNT,
                V_TELUS_EXPECT_AMOUNT,
                12,
                V_NOTE,
                NOW()
          FROM proposal p, invoice_item ii
          WHERE p.invoice_item_id = ii.id
            AND p.invoice_id = V_INVOICE_ID
            AND (
                  ii.line_item_code IN ('2296M',
                                        '232M0',
                                        '243M4',
                                        '80427',
                                        '80428',
                                        '80433',
                                        '80434',
                                        '80435',
                                        '84495',
                                        '89389',
                                        '89574')
                  OR ii.usoc = '1HWNS'
                )
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y';
        
          -- 插入实际折扣额明细结果   
          INSERT INTO audit_result(invoice_id,
                                    proposal_id,
                                    audit_status_id,
                                    audit_source_id,
                                    actual_amount,
                                    expect_amount,
                                    audit_reference_type_id,
                                    notes,
                                    created_timestamp)
          SELECT p.invoice_id,
                 p.id,
                 V_AUDIT_STATUS_ID,
                 V_AUDIT_SOURCE_ID,
                 p.payment_amount,
                 V_TELUS_EXPECT_AMOUNT,
                 12,
                 V_NOTE,
                 NOW()
          FROM proposal p, invoice_item ii
          WHERE p.invoice_item_id = ii.id
              AND p.invoice_id = V_INVOICE_ID
              AND p.description LIKE CONCAT('%', V_ACTUAL_IDENTIFIER_DESCRIPTION, '%')
              AND p.proposal_flag = 1
              AND p.rec_active_flag = 'Y';
    END LOOP;

  -- ????
  CLOSE cur_telus;
      
      
      
      SET V_COUNT = 0;
      SET V_SUCCESS_COUNT = 0;
      SET V_FAILURE_COUNT = 0;
      SET V_CANNOT_VALIDATE_COUNT = 0;
      SET V_SUM_AMOUNT = 0;
      SET V_REVENUE_OR_COST = 0;
      
      SELECT COUNT(1),
       COUNT(CASE WHEN t.audit_status_id = 1 THEN 1 ELSE NULL END),
       COUNT(CASE WHEN t.audit_status_id = 2 THEN 2 ELSE NULL END),
       COUNT(CASE WHEN t.audit_status_id = 3 THEN 3 ELSE NULL END),
       SUM(t.actual_amount),
       SUM(t.expect_amount)
      INTO V_COUNT,
              V_SUCCESS_COUNT,
              V_FAILURE_COUNT,
              V_CANNOT_VALIDATE_COUNT,
              V_SUM_AMOUNT,
              V_REVENUE_OR_COST
      FROM (SELECT a.audit_status_id,
                  a.actual_amount AS actual_amount,
                  a.expect_amount AS expect_amount
              FROM proposal p LEFT JOIN audit_result a ON p.id = a.proposal_id
            WHERE p.invoice_id = V_INVOICE_ID AND a.audit_source_id = '9201'
            GROUP BY p.circuit_number) AS t;
      
      IF V_CANNOT_VALIDATE_COUNT = 0 THEN 
      
        IF V_FAILURE_COUNT = 0 AND V_SUCCESS_COUNT > 0 THEN
          SET V_AUDIT_STATUS_ID = 1;
        ELSEIF V_FAILURE_COUNT > 0 THEN
          SET V_AUDIT_STATUS_ID = 2;
        END IF;
        
        SET V_NOTES_COST = CONCAT('Discount Item Cost Valiadation Passed: ',V_SUCCESS_COUNT,' record(s).</br>     Discount Item Cost Valiadation Failed: '
                      ,V_FAILURE_COUNT,' record(s). </br>     For more information, see the invoice item tab below.');
      ELSE
        SET V_AUDIT_STATUS_ID = 3;
        SET V_REVENUE_OR_COST = NULL;
        IF V_CANNOT_VALIDATE_COUNT = 1 THEN
          SET V_NOTES_COST = 'There is 1 record that cannot be validated because there is no reference in discount report.';
        ELSE 
          SET V_NOTES_COST = CONCAT('There are ', V_CANNOT_VALIDATE_COUNT, ' records that cannot be validated because there is no reference in discount report.');
        END IF;
      END IF;
      
      INSERT INTO audit_result (invoice_id,
                              audit_status_id,
                              audit_source_id,
                              actual_amount,
                              expect_amount,
                              audit_reference_type_id,
                              notes,
                              created_timestamp,
                              created_by)
      VALUES (V_INVOICE_ID,V_AUDIT_STATUS_ID,9202,V_TELUS_ACTUAL_AMOUNT,V_TELUS_EXPECT_AMOUNT,12, V_NOTES_COST ,now(),0);
      
   END