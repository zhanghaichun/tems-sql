DROP PROCEDURE IF EXISTS SP_AUDIT_MTM_RATE;
CREATE PROCEDURE `SP_AUDIT_MTM_RATE`(val_mtm_id int, val_proposal_id int)
BEGIN

    
    DECLARE v_rate_mode_mtm_tb VARCHAR(128) DEFAULT 'rate';
    
    DECLARE v_rate_mtm_tb DOUBLE(20,5) DEFAULT '0';
    
    DECLARE v_payment_amount DOUBLE(20,5) DEFAULT '0';
  DECLARE v_rate_effective_date DATE;
    
    DECLARE val_expect_amount DOUBLE(20,5);
    DECLARE val_expect_rate DOUBLE(20,5);

  
    DECLARE val_note VARCHAR(768);
    
    DECLARE v_audit_status_id INT(32) DEFAULT 3;
    
    DECLARE v_product_id INT(32) DEFAULT 0;
    
    DECLARE v_invoice_id INT(32) DEFAULT 0;
    
    DECLARE v_audit_source_id INT(32) DEFAULT 1;
    
    DECLARE v_quantity INT(32) DEFAULT 1;
  
    DECLARE v_province_id INT(11);

    SELECT invoice_id,product_id
        INTO v_invoice_id,v_product_id
    FROM proposal
    WHERE id = val_proposal_id;

    SELECT rate_mode INTO v_rate_mode_mtm_tb
    FROM audit_mtm
    WHERE id = val_mtm_id;

    SELECT (IFNULL(payment_amount,0)+IFNULL(credit_amount,0)), IFNULL(quantity,1), province_id 
        INTO v_payment_amount, v_quantity, v_province_id
    FROM proposal WHERE id = val_proposal_id;

    CALL SP_GET_RATE_KEY_FIELDS(
                            'audit_mtm',
                            val_mtm_id,
                            val_proposal_id,
                            v_rate_mtm_tb,
                            v_rate_effective_date
    );

    SET val_expect_rate = null;
    SET val_note = null;
    IF ( v_quantity = 0 ) THEN
        SET v_quantity = 1;
    END IF;
  
    IF (v_rate_mode_mtm_tb = 'rate') THEN
        
        SET val_expect_rate =  v_rate_mtm_tb;
         SET v_audit_source_id = 18001;
        SET val_note = CONCAT('The rate is $', FN_TRANSFORM_NOTES_RATE(val_expect_rate) );

    

    END IF;
    
  
    IF (val_expect_rate IS NULL)
    THEN
        SET v_audit_status_id = 3;
        SET v_rate_effective_date = NULL;
    ELSE

        SET val_expect_amount = val_expect_rate * v_quantity;

        IF ( ROUND( v_payment_amount, 2) = ROUND(val_expect_amount,2) ) THEN
          SET v_audit_status_id = 1;
        ELSE
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
            v_payment_amount,
            val_expect_amount,
            18,
            val_mtm_id,
            v_product_id,
            val_note,
            val_expect_rate,
            v_rate_effective_date,
            v_quantity,
            NOW());

END