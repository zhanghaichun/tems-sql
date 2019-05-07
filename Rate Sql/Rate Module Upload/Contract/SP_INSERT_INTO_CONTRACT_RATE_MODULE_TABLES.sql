DROP PROCEDURE IF EXISTS SP_INSERT_INTO_CONTRACT_RATE_MODULE_TABLES;
CREATE PROCEDURE SP_INSERT_INTO_CONTRACT_RATE_MODULE_TABLES()

BEGIN

  /**
   * Insertation contract rate rules operation.
   */
  
    DECLARE V_TABLE_ID INT;

    DECLARE V_AUDIT_REFERENCE_MAPPING_ID INT;
    DECLARE V_AUDIT_RATE_PERIOD_ID INT;

    DECLARE V_CHARGE_TYPE VARCHAR(12);
    DECLARE V_KEY_FIELD VARCHAR(64);
    DECLARE V_RATE_EFFECTIVE_DATE DATE;
    DECLARE V_SUMMARY_VENDOR_NAME VARCHAR(128);
    DECLARE V_VENDOR_NAME VARCHAR(128);
    DECLARE V_USOC VARCHAR(16);
    DECLARE V_STRIPPED_CIRCUIT_NUMBER VARCHAR(64);
    DECLARE V_USOC_DESCRIPTION VARCHAR(255);
    DECLARE V_SUB_PRODUCT VARCHAR(128);
    DECLARE V_LINE_ITEM_CODE_DESCRIPTION VARCHAR(255);
    DECLARE V_LINE_ITEM_CODE VARCHAR(64);
    DECLARE V_ITEM_TYPE VARCHAR(64);
    DECLARE V_ITEM_DESCRIPTIOIN VARCHAR(128);
    DECLARE V_QUANTITY_BEGIN INT;
    DECLARE V_QUANTITY_END INT;
    DECLARE V_TERM VARCHAR(16);
    DECLARE V_RENEWAL_TERM_AFTER_TERM_EXPIRATION VARCHAR(64);
    DECLARE V_EARLY_TERMINATION_FEE VARCHAR(256);
    DECLARE V_CONTRACT_NAME VARCHAR(256);
    DECLARE V_CONTRACT_SERVICE_SCHEDULE_NAME VARCHAR(256);
    DECLARE V_TOTAL_VOLUME_BEGIN INT;
    DECLARE V_TOTAL_VOLUME_END INT;
    DECLARE V_MMBC VARCHAR(64);
    DECLARE V_TARIFF_FILE_NAME VARCHAR(128);
    DECLARE V_TARIFF_NAME VARCHAR(500);
    DECLARE V_BASE_AMOUNT INT;
    DECLARE V_MULTIPLIER DOUBLE(20, 5);
    DECLARE V_RATE DOUBLE(20, 6);
    DECLARE V_RULES_DETAILS VARCHAR(500);
    DECLARE V_TARIFF_PAGE VARCHAR(32);
    DECLARE V_PART_SECTION VARCHAR(32);
    DECLARE V_ITEM_NUMBER VARCHAR(12);
    DECLARE V_CRTC_NUMBER VARCHAR(12);
    DECLARE V_DISOCUNT DOUBLE(20, 5);
    DECLARE V_EXCLUSION_BAN VARCHAR(128);
    DECLARE V_EXCLUSION_ITEM_DESCRIPTION VARCHAR(255);
    DECLARE V_NOTES VARCHAR(500);

    DECLARE V_RATE_MODE VARCHAR(64);
    DECLARE V_VENDOR_GROUP_ID INT;

    DECLARE V_ORIGIN_RATE_EFFECTIVE_DATE VARCHAR(12);

    DECLARE V_TARIFF_RATE_BY_QUANTITY_ID INT;
    DECLARE V_CONTRACT_RATE_BY_QUANTITY_ID INT;

    DECLARE V_MAPPING_KEY_FIELD VARCHAR(64);
    DECLARE V_REFERENCE_TABLE VARCHAR(64);

    DECLARE V_TARIFF_FILE_ID INT;
    DECLARE V_CONTRACT_FILE_ID INT;
    DECLARE V_TARIFF_ID INT;
    DECLARE V_CONTRACT_ID INT;

    DECLARE V_START_DATE DATE;

    DECLARE V_TARIFF_FILE_ITEM_COUNT INT;
    DECLARE V_CONTRACT_FILE_ITEM_COUNT INT;
    DECLARE V_TARIFF_ITEM_COUNT INT;
    DECLARE V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT INT;
    DECLARE V_AUDIT_RATE_PERIOD_ITEM_COUNT INT;
    DECLARE V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT INT;
    DECLARE V_CONTRACT_RATE_BY_QUANTITY_ITEM_COUNT INT;

    DECLARE V_AUDIT_RATE_PERIOD_RATE_ANY_ITEM_COUNT INT;

    DECLARE V_NOT_UPDATE_RECORD_COUNT INT;

    DECLARE V_BAN_ID INT;

    SELECT COUNT(1) INTO V_NOT_UPDATE_RECORD_COUNT
    FROM rate_rule_contract_original
    WHERE sync_flag = 'N';

    IF ( V_NOT_UPDATE_RECORD_COUNT > 0 ) THEN

        SELECT
            id,
            summary_vendor_name,
            charge_type,
            key_field,
            usoc,
            usoc_description,
            stripped_circuit_number, 
            sub_product,
            rate,
            rate_effective_date,
            term_months, 
            renewal_term_after_term_expiration,
            early_termination_fee,
            item_description,
            contract_name,
            contract_service_schedule_name, 
            line_item_code,
            line_item_code_description,
            total_volume_begin,
            total_volume_end, 
            mmbc,
            discount,
            notes
                INTO
                    V_TABLE_ID,
                    V_SUMMARY_VENDOR_NAME,
                    V_CHARGE_TYPE,
                    V_KEY_FIELD,
                    V_USOC,
                    V_USOC_DESCRIPTION,
                    V_STRIPPED_CIRCUIT_NUMBER,
                    V_SUB_PRODUCT,
                    V_RATE,
                    V_RATE_EFFECTIVE_DATE,
                    V_TERM,
                    V_RENEWAL_TERM_AFTER_TERM_EXPIRATION,
                    V_EARLY_TERMINATION_FEE,
                    V_ITEM_DESCRIPTIOIN,
                    V_CONTRACT_NAME,
                    V_CONTRACT_SERVICE_SCHEDULE_NAME,
                    V_LINE_ITEM_CODE,
                    V_LINE_ITEM_CODE_DESCRIPTION,
                    V_TOTAL_VOLUME_BEGIN,
                    V_TOTAL_VOLUME_END,
                    V_MMBC,
                    V_DISOCUNT,
                    V_NOTES
        FROM rate_rule_contract_original
        WHERE sync_flag = 'N'
        ORDER BY id desc
        LIMIT 1;

        CALL SP_GET_AUDIT_KEY_FIELD_AND_RATE_MODE(
            V_KEY_FIELD,
            'contract',
            V_MAPPING_KEY_FIELD,
            V_RATE_MODE,
            V_REFERENCE_TABLE
        );

        CALL SP_GET_CONTRACT_MAPPING_RECORD_ID(
            V_MAPPING_KEY_FIELD,
            V_TABLE_ID,
            V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT,
            V_AUDIT_REFERENCE_MAPPING_ID
        );

        -- If there are records inside audit_reference_mapping table.
        -- update 4 associated tables.
        -- contract_file, audit_reference_mapping, contract, rate_rule_contract_original
        IF(V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT = 0) THEN
       
            SELECT COUNT(1) INTO V_CONTRACT_FILE_ITEM_COUNT
            FROM contract_file
            WHERE contract_number = V_CONTRACT_NAME
                AND effective_date = V_RATE_EFFECTIVE_DATE
                AND rec_active_flag = 'Y';

            IF (V_CONTRACT_FILE_ITEM_COUNT = 0) THEN

                INSERT INTO contract_file(
                    contract_number,
                    effective_date,
                    term,
                    term_quantity,
                    term_combined,
                    expiry_date,
                    renewal_term_after_term_expiration,
                    created_timestamp
                )
                VALUES(
                    V_CONTRACT_NAME,
                    V_RATE_EFFECTIVE_DATE,
                    'MONTH',
                    V_TERM,
                    CONCAT(V_TERM, ' months'),
                    DATE_SUB(
                        DATE_ADD(effective_date,INTERVAL term_quantity MONTH),
                        INTERVAL 1 DAY
                    ),
                    V_RENEWAL_TERM_AFTER_TERM_EXPIRATION,
                    NOW()
                );

                SET V_CONTRACT_FILE_ID = ( SELECT MAX(id) FROM contract_file );

            ELSE

                SELECT id INTO V_CONTRACT_FILE_ID
                FROM contract_file
                WHERE contract_number = V_CONTRACT_NAME
                    AND effective_date = V_RATE_EFFECTIVE_DATE
                    AND rec_active_flag = 'Y';

            END IF;

            INSERT INTO contract (
                contract_file_id, 
                name,
                schedule,
                mmbc,
                discount,
                source, 
                rate_mode, 
                created_timestamp
            )
            VALUES (
                V_CONTRACT_FILE_ID,
                V_CONTRACT_NAME,
                V_CONTRACT_SERVICE_SCHEDULE_NAME,
                V_MMBC,
                V_DISOCUNT,
                'Rogers',
                V_RATE_MODE,
                NOW()
            );

            SET V_CONTRACT_ID = ( SELECT MAX(id) FROM contract );

            SET V_VENDOR_GROUP_ID = FN_GET_CONTRACT_VENDOR_GROUP_ID(V_TABLE_ID);

            INSERT INTO audit_reference_mapping(
                vendor_group_id, 
                summary_vendor_name, 
                key_field,
                key_field_original, 
                charge_type, 
                usoc, 
                usoc_description,
                sub_product, 
                line_item_code, 
                line_item_code_description, 
                item_description, 
                audit_reference_type_id,  
                audit_reference_id,
                created_timestamp
            )
            VALUES (
                V_VENDOR_GROUP_ID,
                V_SUMMARY_VENDOR_NAME,
                V_MAPPING_KEY_FIELD,
                V_KEY_FIELD,
                V_CHARGE_TYPE,
                V_USOC,
                V_USOC_DESCRIPTION,
                V_SUB_PRODUCT,
                V_LINE_ITEM_CODE,
                V_LINE_ITEM_CODE_DESCRIPTION,
                V_ITEM_DESCRIPTIOIN,
                3,
                V_CONTRACT_ID,
                NOW()
            );

            SET V_AUDIT_REFERENCE_MAPPING_ID =  ( SELECT MAX(id) FROM audit_reference_mapping );

            UPDATE rate_rule_contract_original
            SET audit_reference_mapping_id = V_AUDIT_REFERENCE_MAPPING_ID
            WHERE id = V_TABLE_ID;

        ELSE

            UPDATE rate_rule_contract_original
            SET audit_reference_mapping_id = V_AUDIT_REFERENCE_MAPPING_ID
            WHERE id = V_TABLE_ID;

            SET V_CONTRACT_ID = (
                SELECT audit_reference_id
                FROM audit_reference_mapping
                WHERE id = V_AUDIT_REFERENCE_MAPPING_ID
                LIMIT 1
            );

            SELECT COUNT(1) INTO V_CONTRACT_FILE_ITEM_COUNT
            FROM contract_file
            WHERE contract_number = V_CONTRACT_NAME
                AND effective_date = V_RATE_EFFECTIVE_DATE
                AND term_quantity = V_TERM
                AND rec_active_flag = 'Y';

            IF (V_CONTRACT_FILE_ITEM_COUNT = 0) THEN

                INSERT INTO contract_file(
                    contract_number,
                    effective_date,
                    term,
                    term_quantity,
                    term_combined,
                    expiry_date,
                    renewal_term_after_term_expiration,
                    created_timestamp
                )
                VALUES(
                    V_CONTRACT_NAME,
                    V_RATE_EFFECTIVE_DATE,
                    'MONTH',
                    V_TERM,
                    CONCAT(V_TERM, ' months'),
                    DATE_SUB(
                    DATE_ADD(effective_date,INTERVAL term_quantity MONTH),
                    INTERVAL 1 DAY
                    ),
                    V_RENEWAL_TERM_AFTER_TERM_EXPIRATION,
                    NOW()
                );

                SET V_CONTRACT_FILE_ID = ( SELECT MAX(id) FROM contract_file );

            ELSE

                SELECT id INTO V_CONTRACT_FILE_ID
                FROM contract_file
                WHERE contract_number = V_CONTRACT_NAME
                    AND effective_date = V_RATE_EFFECTIVE_DATE
                    AND term_quantity = V_TERM
                    AND rec_active_flag = 'Y'
                LIMIT 1;

            END IF;

            UPDATE contract
            SET 
                contract_file_id = V_CONTRACT_FILE_ID,
                schedule = V_CONTRACT_SERVICE_SCHEDULE_NAME
            WHERE id = V_CONTRACT_ID
                AND rec_active_flag = 'Y';

        END IF; -- /.V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT

        -- Update audit_rate_period, rate_rule_contract_original tables.
        IF(V_REFERENCE_TABLE = 'contract') THEN

            SELECT COUNT(1) INTO V_AUDIT_RATE_PERIOD_ITEM_COUNT
            FROM audit_rate_period
            WHERE 1 = 1
                AND reference_table = 'contract'
                AND reference_id = V_CONTRACT_ID
                AND end_date IS NULL
                AND rec_active_flag = 'Y';

            IF ( V_AUDIT_RATE_PERIOD_ITEM_COUNT = 0) THEN

                INSERT INTO audit_rate_period(
                    reference_table, 
                    reference_id,
                    start_date,
                    end_date,
                    rate
                )
                VALUES(
                    'contract',
                    V_CONTRACT_ID,
                    V_RATE_EFFECTIVE_DATE,
                    NULL,
                    V_RATE
                );

                SET V_AUDIT_RATE_PERIOD_ID = (
                    SELECT MAX(id) FROM audit_rate_period
                );

                UPDATE rate_rule_contract_original
                SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                WHERE id = V_TABLE_ID;

            ELSE
            
                IF(V_RATE_MODE = 'rate_any') THEN

                    SELECT COUNT(1) INTO V_AUDIT_RATE_PERIOD_RATE_ANY_ITEM_COUNT
                    FROM audit_rate_period
                    WHERE 1 = 1
                        AND reference_table = 'contract'
                        AND reference_id = V_CONTRACT_ID
                        AND start_date = V_RATE_EFFECTIVE_DATE
                        AND rate = V_RATE
                        AND rec_active_flag = 'Y';

                    IF(V_AUDIT_RATE_PERIOD_RATE_ANY_ITEM_COUNT = 0) THEN

                        SELECT start_date INTO V_START_DATE
                        FROM audit_rate_period
                        WHERE 1 = 1
                            AND reference_table = 'contract'
                            AND reference_id = V_CONTRACT_ID
                            AND end_date IS NULL
                            AND rec_active_flag = 'Y'
                        LIMIT 1;

                        IF (V_RATE_EFFECTIVE_DATE > V_START_DATE) THEN
                        
                            UPDATE audit_rate_period
                            SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
                            WHERE reference_table = 'contract'
                                AND reference_id = V_CONTRACT_ID
                                AND end_date IS NULL
                                AND rec_active_flag = 'Y';

                            INSERT INTO audit_rate_period(
                                reference_table, 
                                reference_id,
                                start_date,
                                end_date,
                                rate
                            )
                            VALUES(
                                'contract',
                                V_CONTRACT_ID,
                                V_RATE_EFFECTIVE_DATE,
                                NULL,
                                V_RATE
                            );

                            SET V_AUDIT_RATE_PERIOD_ID = (
                                SELECT MAX(id) FROM audit_rate_period
                            );

                            UPDATE rate_rule_contract_original
                            SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                            WHERE id = V_TABLE_ID;

                        ELSEIF (V_RATE_EFFECTIVE_DATE < V_START_DATE) THEN

                            SELECT start_date INTO V_START_DATE
                            FROM audit_rate_period
                            WHERE 1 = 1
                                AND reference_table = 'contract'
                                AND reference_id = V_CONTRACT_ID
                                AND start_date > V_RATE_EFFECTIVE_DATE
                                AND rec_active_flag = 'Y'
                            ORDER BY start_date 
                            LIMIT 1;

                            INSERT INTO audit_rate_period(
                                reference_table, 
                                reference_id,
                                start_date,
                                end_date,
                                rate
                            )
                            VALUES(
                                'contract',
                                V_CONTRACT_ID,
                                V_RATE_EFFECTIVE_DATE,
                                DATE_SUB(V_START_DATE, INTERVAL 1 DAY),
                                V_RATE
                            );

                            SET V_AUDIT_RATE_PERIOD_ID = (
                                SELECT MAX(id) FROM audit_rate_period
                            );

                            UPDATE rate_rule_contract_original
                            SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                            WHERE id = V_TABLE_ID;

                        ELSE

                            INSERT INTO audit_rate_period(
                                reference_table, 
                                reference_id,
                                start_date,
                                end_date,
                                rate
                            )
                            VALUES(
                                'contract',
                                V_CONTRACT_ID,
                                V_RATE_EFFECTIVE_DATE,
                                NULL,
                                V_RATE
                            );

                            SET V_AUDIT_RATE_PERIOD_ID = (
                                SELECT MAX(id) FROM audit_rate_period
                            );

                            UPDATE rate_rule_contract_original
                            SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                            WHERE id = V_TABLE_ID;

                        END IF;
                    
                    ELSE

                        SELECT id INTO V_AUDIT_RATE_PERIOD_ID
                        FROM audit_rate_period
                        WHERE 1 = 1
                            AND reference_table = 'contract'
                            AND reference_id = V_CONTRACT_ID
                            AND start_date = V_RATE_EFFECTIVE_DATE
                            AND rate = V_RATE
                            AND rec_active_flag = 'Y'
                        LIMIT 1;

                        UPDATE rate_rule_contract_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    END IF; -- /.V_AUDIT_RATE_PERIOD_RATE_ANY_ITEM_COUNT

                ELSE

                    -- Get effective date of active record.
                    SELECT start_date INTO V_START_DATE
                    FROM audit_rate_period
                    WHERE reference_table = 'contract'
                        AND reference_id = V_CONTRACT_ID
                        AND end_date IS NULL
                        AND rec_active_flag = 'Y'
                    LIMIT 1;

                    IF (V_RATE_EFFECTIVE_DATE > V_START_DATE) THEN

                        UPDATE audit_rate_period
                        SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
                        WHERE reference_table = 'contract'
                            AND reference_id = V_CONTRACT_ID
                            AND end_date IS NULL
                            AND rec_active_flag = 'Y';

                        INSERT INTO audit_rate_period(
                            reference_table, 
                            reference_id,
                            start_date,
                            end_date,
                            rate
                        )
                        VALUES(
                            'contract',
                            V_CONTRACT_ID,
                            V_RATE_EFFECTIVE_DATE,
                            NULL,
                            V_RATE
                        );

                        SET V_AUDIT_RATE_PERIOD_ID = (
                            SELECT MAX(id) FROM audit_rate_period
                        );

                        UPDATE rate_rule_contract_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    ELSEIF (V_RATE_EFFECTIVE_DATE < V_START_DATE) THEN

                        SELECT start_date INTO V_START_DATE
                        FROM audit_rate_period
                        WHERE reference_table = 'contract'
                            AND reference_id = V_CONTRACT_ID
                            AND start_date > V_RATE_EFFECTIVE_DATE
                            AND rec_active_flag = 'Y'
                        ORDER BY start_date
                        LIMIT 1;

                        INSERT INTO audit_rate_period(
                            reference_table, 
                            reference_id,
                            start_date,
                            end_date,
                            rate
                        )
                        VALUES(
                            'contract',
                            V_CONTRACT_ID,
                            V_RATE_EFFECTIVE_DATE,
                            DATE_SUB(V_START_DATE, INTERVAL 1 DAY),
                            V_RATE,
                            V_RULES_DETAILS
                        );

                        SET V_AUDIT_RATE_PERIOD_ID = (
                            SELECT MAX(id) FROM audit_rate_period
                        );

                        UPDATE rate_rule_contract_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    ELSE 

                        SELECT id INTO V_AUDIT_RATE_PERIOD_ID
                        FROM audit_rate_period
                        WHERE reference_table = 'contract'
                            AND reference_id = V_CONTRACT_ID
                            AND end_date IS NULL
                            AND rec_active_flag = 'Y'
                        LIMIT 1;

                        UPDATE rate_rule_contract_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    END IF; -- End of compare

                END IF;

            END IF;

        ELSEIF(V_REFERENCE_TABLE = 'contract_rate_by_quantity') THEN
           
            SELECT COUNT(1) INTO V_CONTRACT_RATE_BY_QUANTITY_ITEM_COUNT
            FROM contract_rate_by_quantity
            WHERE 1 = 1
                AND contract_id = V_CONTRACT_ID
                AND quantity_begin = V_TOTAL_VOLUME_BEGIN
                AND (quantity_end IS NULL OR quantity_end = V_TOTAL_VOLUME_END);

            IF(V_CONTRACT_RATE_BY_QUANTITY_ITEM_COUNT = 0) THEN

                INSERT INTO contract_rate_by_quantity(
                    contract_id,
                    quantity_begin,
                    quantity_end,
                    rate
                )
                VALUES(
                    V_CONTRACT_ID,
                    V_QUANTITY_BEGIN,
                    V_QUANTITY_END,
                    V_RATE
                );

                SET V_CONTRACT_RATE_BY_QUANTITY_ID = (
                    SELECT MAX(id) FROM contract_rate_by_quantity
                );

                INSERT INTO audit_rate_period(
                    reference_table, 
                    reference_id,
                    start_date,
                    end_date,
                    rate
                )
                VALUES(
                    'contract_rate_by_quantity',
                    V_CONTRACT_RATE_BY_QUANTITY_ID,
                    V_RATE_EFFECTIVE_DATE,
                    NULL,
                    V_RATE
                );

                SET V_AUDIT_RATE_PERIOD_ID = (
                    SELECT MAX(id) FROM audit_rate_period
                );

                UPDATE rate_rule_contract_original
                SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                WHERE id = V_TABLE_ID;

            ELSE

                SELECT id INTO V_CONTRACT_RATE_BY_QUANTITY_ID
                FROM contract_rate_by_quantity
                WHERE 1 = 1
                    AND contract_id = V_CONTRACT_ID
                    AND quantity_begin = V_TOTAL_VOLUME_BEGIN
                    AND (quantity_end IS NULL OR quantity_end = V_TOTAL_VOLUME_END);

                SELECT COUNT(1) INTO V_AUDIT_RATE_PERIOD_ITEM_COUNT
                FROM audit_rate_period
                WHERE 1 = 1
                    AND reference_table = 'contract_rate_by_quantity'
                    AND reference_id = V_CONTRACT_RATE_BY_QUANTITY_ID
                    AND rec_active_flag = 'Y';

                IF(V_AUDIT_RATE_PERIOD_ITEM_COUNT = 0) THEN

                    INSERT INTO audit_rate_period(
                        reference_table, 
                        reference_id,
                        start_date,
                        end_date,
                        rate
                    )
                    VALUES(
                        'contract_rate_by_quantity',
                        V_CONTRACT_RATE_BY_QUANTITY_ID,
                        V_RATE_EFFECTIVE_DATE,
                        NULL,
                        V_RATE
                    );

                    SET V_AUDIT_RATE_PERIOD_ID = (
                        SELECT MAX(id) FROM audit_rate_period
                    );

                    UPDATE rate_rule_contract_original
                    SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                    WHERE id = V_TABLE_ID;

                ELSE

                    SELECT start_date INTO V_START_DATE
                    FROM audit_rate_period
                    WHERE reference_table = 'contract_rate_by_quantity'
                        AND reference_id = V_CONTRACT_RATE_BY_QUANTITY_ID
                        AND end_date IS NULL
                        AND rec_active_flag = 'Y'
                    LIMIT 1;

                    IF (V_RATE_EFFECTIVE_DATE > V_START_DATE) THEN


                        UPDATE contract_rate_by_quantity
                        SET 
                            rate = V_RATE
                        WHERE 1 = 1
                            AND id = V_CONTRACT_RATE_BY_QUANTITY_ID;

                        UPDATE audit_rate_period
                        SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
                        WHERE reference_table = 'contract_rate_by_quantity'
                            AND reference_id = V_CONTRACT_RATE_BY_QUANTITY_ID
                            AND end_date IS NULL
                            AND rec_active_flag = 'Y';

                        INSERT INTO audit_rate_period(
                            reference_table, 
                            reference_id,
                            start_date,
                            end_date,
                            rate
                        )
                        VALUES(
                            'contract_rate_by_quantity',
                            V_CONTRACT_RATE_BY_QUANTITY_ID,
                            V_RATE_EFFECTIVE_DATE,
                            NULL,
                            V_RATE
                        );

                        SET V_AUDIT_RATE_PERIOD_ID = (
                            SELECT MAX(id) FROM audit_rate_period
                        );

                        UPDATE rate_rule_contract_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    ELSEIF (V_RATE_EFFECTIVE_DATE < V_START_DATE) THEN

                        SELECT start_date INTO V_START_DATE
                        FROM audit_rate_period
                        WHERE reference_table = 'contract_rate_by_quantity'
                            AND reference_id = V_CONTRACT_RATE_BY_QUANTITY_ID
                            AND start_date > V_RATE_EFFECTIVE_DATE
                            AND rec_active_flag = 'Y'
                        ORDER BY start_date
                        LIMIT 1;

                        INSERT INTO audit_rate_period(
                            reference_table, 
                            reference_id,
                            start_date,
                            end_date,
                            rate
                        )
                        VALUES(
                            'contract_rate_by_quantity',
                            V_CONTRACT_RATE_BY_QUANTITY_ID,
                            V_RATE_EFFECTIVE_DATE,
                            DATE_SUB(V_START_DATE, INTERVAL 1 DAY),
                            V_RATE
                        );

                        SET V_AUDIT_RATE_PERIOD_ID = (
                            SELECT MAX(id) FROM audit_rate_period
                        );

                        UPDATE rate_rule_contract_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    ELSE

                        SELECT id INTO V_AUDIT_RATE_PERIOD_ID
                        FROM audit_rate_period
                        WHERE reference_table = 'contract_rate_by_quantity'
                            AND reference_id = V_CONTRACT_RATE_BY_QUANTITY_ID
                            AND end_date IS NULL
                            AND rec_active_flag = 'Y'
                        LIMIT 1;

                        UPDATE rate_rule_contract_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    END IF;

                END IF;

            END IF; -- /.V_CONTRACT_RATE_BY_QUANTITY_ITEM_COUNT

        END IF; -- /.V_REFERENCE_TABLE

        -- Update synchronous flag.
        UPDATE rate_rule_contract_original
        SET sync_flag = 'Y'
        WHERE id = V_TABLE_ID;

    END IF; -- /.V_NOT_UPDATE_RECORD_COUNT.

END