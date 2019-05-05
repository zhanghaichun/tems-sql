DROP PROCEDURE IF EXISTS SP_AUDIT_MRC_OCC;
CREATE PROCEDURE SP_AUDIT_MRC_OCC( V_INVOICE_ID INT )
BEGIN

  
  DECLARE v_audit_reference_type_id INT DEFAULT 0;
  
  DECLARE v_audit_reference_id INT DEFAULT 0;
  
  DECLARE v_proposal_id INT DEFAULT 0;

  DECLARE done BOOLEAN DEFAULT FALSE;
  DECLARE v_commit_count INT DEFAULT 0;

  -- 查询某一条账单下的明细数据， 前提是验证的源是 Master Inventory Validation.
  -- 也就是 audit source id 是 3.
  DECLARE cur_proposal CURSOR FOR 
    SELECT 
      p.id, 
      p.audit_reference_type_id, 
      p.audit_reference_id

    FROM proposal p 
      LEFT JOIN audit_reference_mapping arm ON p.audit_reference_mapping_id = arm.id
    WHERE p.invoice_id = V_INVOICE_ID
        AND ( 
              p.item_type_id IN (13, 15)
              OR p.item_type_id LIKE '3%'
              OR p.item_type_id LIKE '5%'
            )
        AND arm.key_field <> 'bill_keep_ban'
        AND p.audit_reference_type_id IN (2, 3, 5,18)
        AND (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0)) <> 0
        AND p.proposal_flag = 1
        AND p.rec_active_flag = 'Y';


  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
  
  set autocommit = 0;

  OPEN cur_proposal;
    
    read_loop: LOOP
      FETCH cur_proposal INTO v_proposal_id, v_audit_reference_type_id, v_audit_reference_id;
      IF done THEN
        LEAVE read_loop;
      END IF;
      SET v_commit_count = v_commit_count + 1;
      
      
      -- Tariff 验证
      IF(v_audit_reference_type_id = 2) THEN
        CALL SP_AUDIT_TARIFF_RATE(v_audit_reference_id,v_proposal_id);

      

      -- Contract 验证
      ELSEIF(v_audit_reference_type_id = 3) THEN
      

        IF v_audit_reference_id is not null and v_audit_reference_id != ''
        THEN
        CALL SP_AUDIT_CONTRACT_RATE(v_audit_reference_id,v_proposal_id);
        end if;
        
      -- Price List 验证 (deprecated)
      ELSEIF(v_audit_reference_type_id = 5) THEN
      
        CALL SP_AUDIT_PRICE_LIST_RATE(v_audit_reference_id,v_proposal_id);

      -- MtM 验证。
      ELSEIF(v_audit_reference_type_id = 18) THEN
        
        IF v_audit_reference_id is not null and v_audit_reference_id != ''
        THEN
        CALL SP_AUDIT_MTM_RATE(v_audit_reference_id,v_proposal_id);
        
        end if;

      END IF;

      IF (v_commit_count % 100 = 0) THEN
        commit;
      END IF;
      
    END LOOP;
  
  CLOSE cur_proposal;

  commit;
  set autocommit = 1;

END