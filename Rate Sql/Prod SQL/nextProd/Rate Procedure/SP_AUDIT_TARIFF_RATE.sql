DROP PROCEDURE IF EXISTS SP_AUDIT_TARIFF_RATE;
CREATE PROCEDURE `SP_AUDIT_TARIFF_RATE`(val_tariff_id int, val_proposal_id int)
BEGIN


    DECLARE v_rate_mode_tariff_tb VARCHAR(128) DEFAULT 'order-date';

    DECLARE v_rate_tariff_tb DOUBLE(20,5) DEFAULT '0';
    DECLARE v_rate_effective_date DATE;

    DECLARE v_payment_amount DOUBLE(20,5) DEFAULT '0';

    declare val_proposal_rate double(20,5);


    DECLARE val_expect_amount DOUBLE(20,5);
    DECLARE val_expect_rate DOUBLE(20,5);
    DECLARE val_base_amount DOUBLE(20,5);
    DECLARE val_discount DOUBLE(20,5);
    DECLARE val_multiplier DOUBLE(20,5);

    DECLARE val_note VARCHAR(768);

    DECLARE v_audit_status_id INT(32) DEFAULT 3;

    DECLARE v_product_id INT(32) DEFAULT 0;

    DECLARE v_invoice_id INT(32) DEFAULT 0;

    DECLARE v_audit_source_id INT(32) DEFAULT 1;

    DECLARE v_quantity INT(32) DEFAULT 1;
    DECLARE v_t1zf_quantity INT(32);

    DECLARE v_province_id INT(11);

    DECLARE V_IS_T1Z INT(11) DEFAULT 0;

    DECLARE V_VENDOR_CLLI VARCHAR(32) DEFAULT '';



    DECLARE v_references_tolerance_rate DOUBLE(20,5) DEFAULT 0;

    DECLARE v_sys_tolerance_rate DOUBLE(20,5) DEFAULT 0;

    DECLARE v_tolerance_rate DOUBLE(20,5) DEFAULT 0;

    -- SELECT tolerance_rate INTO v_tolerance_rate FROM tariff WHERE id = val_tariff_id;

    -- SELECT value INTO v_sys_tolerance_rate FROM sys_config WHERE parameter = 'audit_tolerance_rate_tariff';

    -- SET v_tolerance_rate = IFNULL(v_references_tolerance_rate,v_sys_tolerance_rate);

    SELECT invoice_id,product_id INTO v_invoice_id,v_product_id
    FROM proposal
    WHERE id = val_proposal_id;

    SELECT rate_mode, discount, multiplier, tolerance_rate
    INTO v_rate_mode_tariff_tb, val_discount, val_multiplier, v_tolerance_rate
    FROM tariff
    WHERE id = val_tariff_id;

  -- 获取 rate, rate_effective_date.
  -- 但是只应用于部分 rate_mode
  -- 对于 rate_mode 比较复杂的 （如： tariff_rate_by_quantity）
  -- 等，有其它的处理逻辑。
    CALL SP_GET_RATE_KEY_FIELDS('tariff',
                                val_tariff_id,
                                val_proposal_id,
                                v_rate_tariff_tb,
                                v_rate_effective_date);


    SELECT (IFNULL(payment_amount,0)+IFNULL(credit_amount,0)), IFNULL(quantity,1), province_id, rate
    INTO v_payment_amount, v_quantity, v_province_id , val_proposal_rate
    FROM proposal WHERE id = val_proposal_id;

    SET val_expect_rate = null;
    SET val_note = null;
    IF ( v_quantity = 0 ) THEN
        SET v_quantity = 1;
    END IF;

    IF (v_rate_mode_tariff_tb = 'rate')
        THEN

        SET val_expect_rate =  v_rate_tariff_tb;
        SET val_note = CONCAT('The rate is $', FN_TRANSFORM_NOTES_RATE(val_expect_rate));

        -- 添加 tolerance rate notes
        IF ( v_tolerance_rate IS NOT NULL ) THEN
            SET val_note = CONCAT( 
                val_note, 
                ', the tolerance is $', 
                FN_TRANSFORM_NOTES_RATE(v_tolerance_rate) 
            );
        END IF;

        SET v_audit_source_id = 2001;

  ELSEIF (v_rate_mode_tariff_tb = 'tariff_rate_by_distance')
        THEN

        SET v_audit_source_id = 2003;
        CALL SP_AUDIT_TARIFF_RATE_BY_DISTANCE(val_tariff_id, val_proposal_id, val_expect_rate, val_note);
    ELSEIF (v_rate_mode_tariff_tb = 'tariff_rate_by_term')
        THEN

        SET v_audit_source_id = 2004;
        CALL SP_AUDIT_TARIFF_RATE_BY_TERM(val_tariff_id, val_proposal_id, val_expect_rate, val_note);
    ELSEIF (v_rate_mode_tariff_tb = 'tariff_rate_by_province')
        THEN

        SET v_audit_source_id = 2005;
        CALL SP_AUDIT_TARIFF_RATE_BY_PROVINCE(val_tariff_id, val_proposal_id, val_expect_rate, val_note);
    ELSEIF (v_rate_mode_tariff_tb = 'order_date_check')
        THEN

        SET v_audit_source_id = 2002;
      CALL SP_AUDIT_TARIFF_RATE_BY_ORDER_DATE(val_tariff_id, val_proposal_id, val_expect_rate, val_note);

    ELSEIF (v_rate_mode_tariff_tb = 'tariff_rate_by_trunk' or v_rate_mode_tariff_tb = 'tariff_rate_by_trunk_province')
        THEN

        SET v_audit_source_id = 2006;

        SET v_t1zf_quantity = v_quantity;
        CALL SP_AUDIT_GET_SUM_AMOUNT_CIRCUIT_ZITF(v_payment_amount,v_t1zf_quantity,
            V_IS_T1Z,val_proposal_id, V_VENDOR_CLLI);

        CALL SP_AUDIT_TARIFF_RATE_BY_TRUNK(val_tariff_id, v_t1zf_quantity, v_province_id, v_rate_mode_tariff_tb,
            val_proposal_id, val_expect_rate, val_note);

        IF ( V_IS_T1Z = 1 ) THEN

            SET val_note = CONCAT( val_note,
                                    '. The Vendor CLLI is ',
                                    V_VENDOR_CLLI,
                                    ' and the total quantity is ',
                                    v_t1zf_quantity,
                                    '.');
        END IF;

  ELSEIF (v_rate_mode_tariff_tb = 'tariff_rate_discount')
      THEN

      SET val_expect_rate =  ROUND( v_rate_tariff_tb * IFNULL(val_discount,1), 2);
      SET val_note = CONCAT('The rate is $', FN_TRANSFORM_NOTES_RATE(val_expect_rate) );
      SET v_audit_source_id = 2007;

  ELSEIF (v_rate_mode_tariff_tb = 'tariff_rate_multiplier')
      THEN

      SET val_expect_rate =  ROUND( v_rate_tariff_tb * IFNULL(val_multiplier,1), 2);
      SET val_note = CONCAT('The rate is $', FN_TRANSFORM_NOTES_RATE(val_expect_rate) );
      SET v_audit_source_id = 2008;

  ELSEIF (v_rate_mode_tariff_tb in ('tariff_rate_by_quantity','tariff_rate_by_quantity_base_amount'))
        THEN

        SET v_audit_source_id = 2009;
        SET v_t1zf_quantity = v_quantity;

        -- Sum vendor clli count.
        CALL SP_AUDIT_GET_SUM_AMOUNT_CIRCUIT_ZITF(v_payment_amount,
                                                    v_t1zf_quantity,
                                                    V_IS_T1Z,
                                                    val_proposal_id,
                                                    V_VENDOR_CLLI);

        INSERT INTO event_journal (event_type)
      VALUES ('AFTER SP_AUDIT_GET_SUM_AMOUNT_CIRCUIT_ZITF');

        -- 通过 vendor clli quantity 来获取正确的 rate 值。
        CALL SP_AUDIT_TARIFF_RATE_BY_QUANTITY(val_tariff_id,
                                                v_t1zf_quantity,
                                                v_rate_mode_tariff_tb,
                                                val_proposal_id,
                                                val_expect_rate,
                                                val_base_amount,
                                                val_note,
                                                v_rate_effective_date);

        INSERT INTO event_journal (event_type)
      VALUES ('AFTER SP_AUDIT_TARIFF_RATE_BY_QUANTITY');

        -- 添加 VENDOR CLLI notes.
        IF ( V_IS_T1Z = 1 ) THEN

            SET val_note = CONCAT( val_note,
                                    '. The Vendor CLLI is ',
                                    V_VENDOR_CLLI,
                                    ' and the total quantity is ',
                                    v_t1zf_quantity, '.');
        END IF;

    ELSEIF (v_rate_mode_tariff_tb in ('rate_any'))
          THEN

          SET v_audit_source_id = 2010;

          call SP_AUDIT_RULE_RATE_BY_ANY(val_tariff_id,
                                            val_proposal_id,
                                            val_proposal_rate,
                                            'tariff',
                                            val_expect_rate,
                                            val_note,
                                            v_rate_effective_date);

    ELSEIF ( v_rate_mode_tariff_tb = 'rate_max' ) THEN

        SET val_expect_rate =  v_rate_tariff_tb;
        SET val_note = CONCAT('The maximum rate is $', FN_TRANSFORM_NOTES_RATE(val_expect_rate) );
        SET v_audit_source_id = 2011;

    ELSEIF ( v_rate_mode_tariff_tb = 'tariff_rate_by_quantity_rate_max' ) THEN

        SET v_t1zf_quantity = v_quantity;

        -- 通过 vendor clli quantity 来获取正确的 rate 值。
        CALL SP_AUDIT_TARIFF_RATE_BY_QUANTITY(val_tariff_id,
                                                v_t1zf_quantity,
                                                v_rate_mode_tariff_tb,
                                                val_proposal_id,
                                                val_expect_rate,
                                                val_base_amount,
                                                val_note,
                                                v_rate_effective_date);

        SET v_audit_source_id = 2011;

    END IF;

    -- 输出验证结果。
    IF (val_expect_rate IS NULL) THEN

        -- 如果 rate 值为 NULL, 验证结果就是 Cannot validate.
        SET v_audit_status_id = 3; -- Cannot validate.
        SET v_rate_effective_date = NULL;

        -- 如果 rate 值为 NULL, rate mode 是 'rate_any', 验证结果是 Failed.
        IF (v_rate_mode_tariff_tb = 'rate_any') THEN
            SET v_audit_status_id = 2;
        END IF;


    ELSE
        -- 如果 rate 值不为 NULL, 开始计算 rate，
        -- 并得出验证结果。

        -- 通过 rate 和 quantity 来计算 expect amount.
        SET val_expect_amount = val_expect_rate * v_quantity;


        -- 如果 rate mode 是 'tariff_rate_by_quantity_base_amount', 需要在 expect amount 的
        -- 基础上加 base amount.
        IF (v_rate_mode_tariff_tb = 'tariff_rate_by_quantity_base_amount') THEN
          SET val_expect_amount = val_expect_amount + val_base_amount;
        END IF;


        -- 如果 rate mode 是 'rate_max' 那么比较的方式改变
        -- expect amount <= actual amount
        IF ( v_rate_mode_tariff_tb IN ('rate_max', 'tariff_rate_by_quantity_rate_max') ) THEN


            IF ( ROUND(v_payment_amount, 2) <= ROUND( val_expect_amount , 2) ) THEN
              SET v_audit_status_id = 1; -- Passed.
            ELSE
              SET v_audit_status_id = 2; -- Failed.
            END IF;


        ELSE

            -- 比较 payment amount 和 expect amount 来得出最后的验证结果。
            -- 计算结果保留两位小数之后进行比较。
            IF ( ROUND(v_payment_amount, 2) >= ROUND( ( val_expect_amount - IFNULL(v_tolerance_rate, 0) ), 2)
                    AND ROUND(v_payment_amount, 2) <= ROUND( (val_expect_amount + IFNULL(v_tolerance_rate, 0) ), 2) )
            THEN
              SET v_audit_status_id = 1; -- Passed.
            ELSE
              SET v_audit_status_id = 2; -- Failed.
            END IF;


        END IF;



    END IF;




    -- 向 audit_result 表中插入验证结果。
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
            2,
            val_tariff_id,
            v_product_id,
            val_note,
            val_expect_rate,
            v_rate_effective_date,
            v_quantity,
            NOW());

END