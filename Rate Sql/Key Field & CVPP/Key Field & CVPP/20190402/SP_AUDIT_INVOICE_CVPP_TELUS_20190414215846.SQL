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
  DECLARE V_ACTIVE_CVPP_DISCOUNT DOUBLE(20, 5);

  DECLARE V_ACTUAL_IDENTIFIER_DESCRIPTION VARCHAR(64) DEFAULT 'CVPP DISCOUNT';

  DECLARE V_CVPP_DISCOUNT_DATE DATE;

  DECLARE V_COUNT INT;
  DECLARE V_SUCCESS_COUNT INT;
  DECLARE V_FAILURE_COUNT INT;
  DECLARE V_CANNOT_VALIDATE_COUNT INT;
  DECLARE V_SUM_AMOUNT DOUBLE(20,5) DEFAULT 0;
  DECLARE V_REVENUE_OR_COST DOUBLE(20,5) DEFAULT 0;
  DECLARE V_NOTES_COST VARCHAR(768);

  DECLARE V_DIFFERENCE DOUBLE(20,5);

  SET V_CVPP_DISCOUNT_DATE = ( 
      SELECT invoice_date
      FROM invoice
      WHERE rec_active_flag = 'Y'
        AND id = V_INVOICE_ID 
    );

  SELECT discount INTO V_ACTIVE_CVPP_DISCOUNT
  FROM rate_rule_contract_original
  WHERE rec_active_flag = 'Y'
    AND key_field LIKE '%CVPP%'
    AND summary_vendor_name = 'TELUS'
    AND rate_effective_date <= V_CVPP_DISCOUNT_DATE
    ORDER BY rate_effective_date DESC
  LIMIT 1;

  SELECT SUM(IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0)) * V_ACTIVE_CVPP_DISCOUNT * -1
    INTO V_TELUS_EXPECT_AMOUNT
  FROM proposal p, invoice_item ii
  WHERE p.invoice_item_id = ii.id
    AND p.invoice_id = V_INVOICE_ID
    AND ( 
          p.item_type_id IN (13, 15)
          OR p.item_type_id LIKE '3%'
          OR p.item_type_id LIKE '5%'
        )
    AND (
          ii.line_item_code IN ('2296M', '232M0', '243M4', '80427', '80428', '80433',
                                '80434', '80435', '84495', '89389', '89574')
          OR 
          ii.usoc = '1HWNS'
        )
    AND p.proposal_flag = 1
    AND p.rec_active_flag = 'Y';

  -- 从系统中检索误差率 （金额）
  SELECT value INTO V_DIFFERENCE
  FROM sys_config WHERE parameter = 'audit_tolerance_amount_cvpp';

  -- 设置验证结果注解
  SET V_NOTE = CONCAT('The tolerance for CVPP validation is +/- $', FORMAT(V_DIFFERENCE,2));

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

  INSERT INTO audit_result (
      invoice_id,
      audit_status_id,
      audit_source_id,
      actual_amount,
      expect_amount,
      audit_reference_type_id,
      notes,
      created_timestamp,
      created_by
    )
  VALUES (
      V_INVOICE_ID,
      V_AUDIT_STATUS_ID,
      9202,
      V_TELUS_ACTUAL_AMOUNT,
      V_TELUS_EXPECT_AMOUNT,
      12, 
      V_NOTE ,
      now(),
      0
    );

      
END;