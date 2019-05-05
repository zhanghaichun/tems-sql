DROP PROCEDURE IF EXISTS SP_AUDIT_CONTRACT_RATE;
CREATE PROCEDURE `SP_AUDIT_CONTRACT_RATE`(IN val_contract_id int, IN val_proposal_id int)
BEGIN

  DECLARE v_rate_mode VARCHAR(64) DEFAULT '';
  DECLARE v_rate_effective_date DATE;

  DECLARE v_has_any_rate INT DEFAULT 0;

  DECLARE v_sum_payment_amount DOUBLE(20,5) DEFAULT 0;
  DECLARE v_circuit_number VARCHAR(128) DEFAULT '';
  DECLARE v_invoice_id INT(32) DEFAULT 0;
  DECLARE v_item_type_id INT(32) DEFAULT 0;
  DECLARE v_contract_rate DOUBLE(20,5) DEFAULT 0;
  DECLARE v_proposal_rate DOUBLE (20, 5) DEFAULT 0;
  DECLARE v_audit_status_id INT(32) DEFAULT 0;
  DECLARE v_audit_source_id INT(32) DEFAULT 0;

  DECLARE v_product_id INT(32) DEFAULT 0;

  DECLARE v_payment_amount DOUBLE(20,5) DEFAULT 0;

  DECLARE v_quantity INT(32) DEFAULT 1;

  DECLARE v_actual_payment_amount DOUBLE(20,5);
  DECLARE v_expect_amount DOUBLE(20,5);

  DECLARE v_total_volume INT;
  -- note
  DECLARE v_note VARCHAR(768) DEFAULT '';

  DECLARE V_IS_T1Z INT(11) DEFAULT 0;


  -- 容错率 References 级
  DECLARE v_references_tolerance_rate DOUBLE(20,5) DEFAULT 0;
  -- 容错率 sys 级
  DECLARE v_sys_tolerance_rate DOUBLE(20,5) DEFAULT 0;
  -- 最终使用的容错率
  DECLARE v_tolerance_rate DOUBLE(20,5) DEFAULT 0;
  -- 查询 references 级 容错率的值
  SELECT tolerance_rate INTO v_references_tolerance_rate FROM contract WHERE id = val_contract_id;
  -- 查询 sys 级 容错率的值
  SELECT value INTO v_sys_tolerance_rate FROM sys_config WHERE parameter = 'audit_tolerance_rate_contract';
  -- 如果 references 容错率 为NULL 那么就取 sys 级的容错率
  SET v_tolerance_rate = IFNULL(v_references_tolerance_rate,v_sys_tolerance_rate);



  
  SELECT circuit_number,
      invoice_id,
      item_type_id,product_id,
      (IFNULL(payment_amount,0)+IFNULL(credit_amount,0)),
      IFNULL(quantity,1),
      rate
    INTO
      v_circuit_number,
      v_invoice_id,
      v_item_type_id,
      v_product_id,
      v_payment_amount,
      v_quantity,
      v_proposal_rate
  FROM 
    proposal 
  WHERE 
    id = val_proposal_id;
  

  SELECT rate_mode INTO  v_rate_mode
  FROM contract WHERE id = val_contract_id;

  CALL SP_GET_RATE_KEY_FIELDS('contract',
                  val_contract_id,
                  val_proposal_id,
                  v_contract_rate,
                  v_rate_effective_date);

  IF (v_quantity = 0) THEN
    SET v_quantity = 1;
  END IF;

  IF v_rate_mode = 'rate' THEN

    SET v_audit_source_id = 3001;
    SET v_note = CONCAT('The rate is $', FN_TRANSFORM_NOTES_RATE(v_contract_rate) );
   
    SET v_actual_payment_amount = v_payment_amount;


  ELSEIF v_rate_mode = 'rate_any' THEN

    SET v_audit_source_id = 3003;
    SET v_actual_payment_amount = v_payment_amount;

    CALL SP_AUDIT_RULE_RATE_BY_ANY(
      val_contract_id,
      val_proposal_id,
      v_proposal_rate,
      'contract',
      v_contract_rate,
      v_note,
      v_rate_effective_date
    );

  ELSEIF v_rate_mode = 'rate_total' THEN
    -- 计算payment_amount 合计
    SELECT 
      SUM((IFNULL(payment_amount, 0) + IFNULL(credit_amount, 0)))
    INTO 
      v_sum_payment_amount 
    FROM 
      proposal 
    WHERE 
      circuit_number = v_circuit_number 
      AND invoice_id = v_invoice_id 
      AND item_type_id = v_item_type_id;
    
    SET v_audit_source_id = 3002;
    SET v_note = CONCAT('The expect total amount of circuit is $',0 + CAST(v_contract_rate AS char));
    
    SET v_actual_payment_amount = v_sum_payment_amount;
    SET v_expect_amount = v_contract_rate;

    IF (v_contract_rate IS NULL) THEN

      SET v_audit_status_id = 3;

    -- 对两个结果做比较
    ELSEIF ( ROUND(v_actual_payment_amount, 2) >= ROUND( (v_expect_amount * (1 - v_tolerance_rate)), 2) 
      AND ROUND(v_actual_payment_amount, 2) <= ROUND( (v_expect_amount * (1 + v_tolerance_rate)), 2) )
    THEN
      -- 验证成功
      SET v_audit_status_id = 1;
    ELSE
      -- 验证失败
      SET v_audit_status_id = 2;
    END IF;

  ELSEIF (v_rate_mode = 'contract_rate_by_quantity' ) 
  THEN

    SET v_audit_source_id = 3004;

    -- 根据 {invoice_id} 和 {description} 对 `proposal` 表中的 {quantity}
    -- 进行求和。
    SELECT SUM(p.quantity) INTO v_total_volume FROM proposal p
    INNER JOIN invoice i ON i.id = p.invoice_id
    WHERE i.id = (
      SELECT t1.id FROM invoice t1
      INNER JOIN proposal t2 ON t2.invoice_id = t1.id
      WHERE t2.id = val_proposal_id
    ) -- 直接使用 invoice_id 作为关联条件是因为同一个vendor 在同一天会来两张账单，
    -- 这两张账单一个是用于 description 是 "SIP Sessions" 而另一个是用于其他的。
    AND p.description LIKE '%SIP Sessions%' 
    AND p.proposal_flag = 1 -- 1, 明细数据 2, 小计数据 (根据 item_type 进行运算)
    AND p.rec_active_flag = 'Y';


    CALL SP_AUDIT_CONTRACT_RATE_BY_QUANTITY(val_contract_id,
                          v_total_volume,
                          val_proposal_id,
                          v_contract_rate,
                          v_note,
                          v_rate_effective_date);

    SET v_actual_payment_amount = v_payment_amount;


  END IF;


  -- 设置最终的值， 包括 audit status
  -- 和 expect amount.
  IF (v_contract_rate IS NULL) THEN

        SET v_audit_status_id = 3;
        SET v_rate_effective_date = NULL;

        IF ( v_rate_mode = 'rate_any' ) THEN

            SET v_audit_status_id = 2;
        END IF;

    -- 对两个结果做比较
    ELSE

    SET v_expect_amount = v_contract_rate * v_quantity;

    IF ( ROUND( v_actual_payment_amount, 2) >= ROUND( (v_expect_amount * (1 - v_tolerance_rate)), 2)
      AND ROUND( v_actual_payment_amount, 2) <= ROUND( (v_expect_amount * (1 + v_tolerance_rate)), 2) ) THEN

      -- 验证成功
      SET v_audit_status_id = 1;

    ELSE
      -- 验证失败
      SET v_audit_status_id = 2;
    END IF;

  END IF;


  INSERT INTO 
    audit_result (
      invoice_id,
      proposal_id,
      audit_status_id,
      audit_source_id,
      actual_amount,
      expect_amount,
      audit_reference_type_id,
      audit_reference_id,
      product_id,
      notes,
      rate,
      rate_effective_date,
      quantity,
      created_timestamp)
    VALUES (v_invoice_id,
      val_proposal_id,
      v_audit_status_id,
      v_audit_source_id,
      v_actual_payment_amount,
      v_expect_amount,
      3,
      val_contract_id,
      v_product_id,
      v_note,
      v_contract_rate,
      v_rate_effective_date,
      v_quantity,
      NOW());

END