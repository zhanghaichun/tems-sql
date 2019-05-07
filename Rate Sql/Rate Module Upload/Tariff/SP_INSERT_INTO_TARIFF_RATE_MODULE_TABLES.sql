DROP PROCEDURE IF EXISTS SP_INSERT_INTO_TARIFF_RATE_MODULE_TABLES;
CREATE PROCEDURE SP_INSERT_INTO_TARIFF_RATE_MODULE_TABLES()

BEGIN

  /**
   * Insert Tariff rate rule.
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
    DECLARE V_USOC_DESCRIPTION VARCHAR(255);
    DECLARE V_SUB_PRODUCT VARCHAR(128);
    DECLARE V_LINE_ITEM_CODE_DESCRIPTION VARCHAR(255);
    DECLARE V_LINE_ITEM_CODE VARCHAR(64);
    DECLARE V_ITEM_TYPE VARCHAR(64);
    DECLARE V_ITEM_DESCRIPTIOIN VARCHAR(128);
    DECLARE V_QUANTITY_BEGIN INT;
    DECLARE V_QUANTITY_END INT;
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

    DECLARE V_MAPPING_KEY_FIELD VARCHAR(64);
    DECLARE V_REFERENCE_TABLE VARCHAR(64);

    DECLARE V_TARIFF_FILE_ID INT;
    DECLARE V_TARIFF_ID INT;

    DECLARE V_START_DATE DATE;

    DECLARE V_TARIFF_FILE_ITEM_COUNT INT;
    DECLARE V_TARIFF_ITEM_COUNT INT;
    DECLARE V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT INT;
    DECLARE V_AUDIT_RATE_PERIOD_ITEM_COUNT INT;
    DECLARE V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT INT;

    DECLARE V_AUDIT_RATE_PERIOD_RATE_ANY_ITEM_COUNT INT;

    DECLARE V_NOT_UPDATE_RECORD_COUNT INT;

    DECLARE V_BAN_ID INT;

    SELECT COUNT(1) INTO V_NOT_UPDATE_RECORD_COUNT
    FROM rate_rule_tariff_original
    WHERE sync_flag = 'N';

    IF ( V_NOT_UPDATE_RECORD_COUNT > 0 ) THEN

        SELECT
            id,
            charge_type,
            key_field,
            rate_effective_date,
            summary_vendor_name,
            vendor_name,
            usoc,
            usoc_description,
            sub_product,
            line_item_code_description,
            line_item_code,
            item_type,
            item_description,
            quantity_begin,
            quantity_end,
            tariff_file_name,
            tariff_name,
            base_amount,
            multiplier,
            rate,
            rules_details,
            tariff_page,
            part_section,
            item_number,
            crtc_number,
            discount,
            exclusion_ban,
            exclusion_item_description,
            notes
                INTO
                    V_TABLE_ID,
                    V_CHARGE_TYPE,
                    V_KEY_FIELD,
                    V_RATE_EFFECTIVE_DATE,
                    V_SUMMARY_VENDOR_NAME,
                    V_VENDOR_NAME,
                    V_USOC,
                    V_USOC_DESCRIPTION,
                    V_SUB_PRODUCT,
                    V_LINE_ITEM_CODE_DESCRIPTION,
                    V_LINE_ITEM_CODE,
                    V_ITEM_TYPE,
                    V_ITEM_DESCRIPTIOIN,
                    V_QUANTITY_BEGIN,
                    V_QUANTITY_END,
                    V_TARIFF_FILE_NAME,
                    V_TARIFF_NAME,
                    V_BASE_AMOUNT,
                    V_MULTIPLIER,
                    V_RATE,
                    V_RULES_DETAILS,
                    V_TARIFF_PAGE,
                    V_PART_SECTION,
                    V_ITEM_NUMBER,
                    V_CRTC_NUMBER,
                    V_DISOCUNT,
                    V_EXCLUSION_BAN,
                    V_EXCLUSION_ITEM_DESCRIPTION,
                    V_NOTES
        FROM rate_rule_tariff_original
        WHERE sync_flag = 'N'
        ORDER BY id desc
        LIMIT 1;

        CALL SP_GET_AUDIT_KEY_FIELD_AND_RATE_MODE(
            V_KEY_FIELD,
            'tariff',
            V_MAPPING_KEY_FIELD,
            V_RATE_MODE,
            V_REFERENCE_TABLE
        );

        CALL SP_GET_TARIFF_MAPPING_RECORD_ID(
            V_MAPPING_KEY_FIELD,
            V_TABLE_ID,
            V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT,
            V_AUDIT_REFERENCE_MAPPING_ID
        );

        IF(V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT = 0) THEN

            SELECT COUNT(1) INTO V_TARIFF_FILE_ITEM_COUNT
            FROM tariff_file
            WHERE tariff_name = V_TARIFF_FILE_NAME
                AND rec_active_flag = 'Y';

            IF (V_TARIFF_FILE_ITEM_COUNT = 0) THEN

                INSERT INTO tariff_file(tariff_name, created_timestamp)
                VALUES(V_TARIFF_FILE_NAME, NOW());

                SET V_TARIFF_FILE_ID = ( SELECT MAX(id) FROM tariff_file );

            ELSE

                SELECT id INTO V_TARIFF_FILE_ID
                FROM tariff_file
                WHERE tariff_name = V_TARIFF_FILE_NAME
                    AND rec_active_flag = 'Y';

            END IF;

            INSERT INTO tariff (
                tariff_file_id, 
                name, 
                rate_mode, 
                rate_effective_date, 
                rate, 
                multiplier, 
                discount,
                page, 
                part_section, 
                item_number, 
                source, 
                created_timestamp
            )
            VALUES (
                V_TARIFF_FILE_ID,
                V_TARIFF_NAME,
                V_RATE_MODE,
                V_RATE_EFFECTIVE_DATE,
                V_RATE,
                V_MULTIPLIER,
                V_DISOCUNT,
                V_TARIFF_PAGE,
                V_PART_SECTION,
                V_ITEM_NUMBER,
                'Rogers',
                NOW()
            );

            SET V_TARIFF_ID = ( SELECT MAX(id) FROM tariff );

            SET V_VENDOR_GROUP_ID = FN_GET_TARIFF_VENDOR_GROUP_ID(V_TABLE_ID);
          
            INSERT INTO audit_reference_mapping(
                vendor_group_id, 
                summary_vendor_name, 
                vendor_name, 
                key_field,
                key_field_original, 
                charge_type, 
                usoc, 
                usoc_description,
                sub_product, 
                line_item_code, 
                line_item_code_description, 
                usage_item_type, 
                item_description, 
                audit_reference_type_id,  
                audit_reference_id,
                created_timestamp
            )
            VALUES (
                V_VENDOR_GROUP_ID,
                V_SUMMARY_VENDOR_NAME,
                V_VENDOR_NAME,
                V_MAPPING_KEY_FIELD,
                V_KEY_FIELD,
                V_CHARGE_TYPE,
                V_USOC,
                V_USOC_DESCRIPTION,
                V_SUB_PRODUCT,
                V_LINE_ITEM_CODE,
                V_LINE_ITEM_CODE_DESCRIPTION,
                V_ITEM_TYPE,
                V_ITEM_DESCRIPTIOIN,
                2,
                V_TARIFF_ID,
                NOW()
            );

            SET V_AUDIT_REFERENCE_MAPPING_ID =  ( SELECT MAX(id) FROM audit_reference_mapping );

            UPDATE rate_rule_tariff_original
            SET audit_reference_mapping_id = V_AUDIT_REFERENCE_MAPPING_ID
            WHERE id = V_TABLE_ID;

        ELSE

            UPDATE rate_rule_tariff_original
            SET audit_reference_mapping_id = V_AUDIT_REFERENCE_MAPPING_ID
            WHERE id = V_TABLE_ID;

            SET V_TARIFF_ID = (
                SELECT audit_reference_id
                FROM audit_reference_mapping
                WHERE id = V_AUDIT_REFERENCE_MAPPING_ID
            );

        END IF; -- /.V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT

        -- Ban exclusion
        IF(V_EXCLUSION_BAN IS NOT NULL OR V_EXCLUSION_BAN != '') THEN

            SELECT id INTO V_BAN_ID
            FROM ban
            WHERE account_number = V_EXCLUSION_BAN
                AND rec_active_flag = 'Y'
                AND ban_status_id = 1
                AND master_ban_flag = 'Y';

            INSERT INTO audit_reference_mapping_exclusion(
                audit_reference_mapping_id,
                exclude_key_field,
                ban_id 
            )
            VALUES(
                V_AUDIT_REFERENCE_MAPPING_ID,
                'ban',
                V_BAN_ID
            );

        END IF;

        -- Item description.
        IF(V_EXCLUSION_ITEM_DESCRIPTION IS NOT NULL OR V_EXCLUSION_ITEM_DESCRIPTION != '') THEN

            INSERT INTO audit_reference_mapping_exclusion(
                audit_reference_mapping_id,
                exclude_key_field,
                item_description 
            )
            VALUES(
                V_AUDIT_REFERENCE_MAPPING_ID,
                'item_description',
                V_EXCLUSION_ITEM_DESCRIPTION
            );

        END IF;

        IF(V_REFERENCE_TABLE = 'tariff') THEN

            SELECT COUNT(1) INTO V_AUDIT_RATE_PERIOD_ITEM_COUNT
            FROM audit_rate_period
            WHERE 1 = 1
                AND reference_table = 'tariff'
                AND reference_id = V_TARIFF_ID
                AND end_date IS NULL;

            IF ( V_AUDIT_RATE_PERIOD_ITEM_COUNT = 0) THEN

                INSERT INTO audit_rate_period(
                    reference_table, 
                    reference_id,
                    start_date,
                    end_date,
                    rate,
                    rules_details
                )
                VALUES(
                    'tariff',
                    V_TARIFF_ID,
                    V_RATE_EFFECTIVE_DATE,
                    NULL,
                    V_RATE,
                    V_RULES_DETAILS
                );

                SET V_AUDIT_RATE_PERIOD_ID = (
                    SELECT MAX(id) FROM audit_rate_period
                );

                UPDATE rate_rule_tariff_original
                SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                WHERE id = V_TABLE_ID;

            ELSE

                IF(V_RATE_MODE = 'rate_any') THEN

                    SELECT COUNT(1) INTO V_AUDIT_RATE_PERIOD_RATE_ANY_ITEM_COUNT
                    FROM audit_rate_period
                    WHERE 1 = 1
                        AND reference_table = 'tariff'
                        AND reference_id = V_TARIFF_ID
                        AND start_date = V_RATE_EFFECTIVE_DATE
                        AND rate = V_RATE
                        AND rec_active_flag = 'Y';

                    IF(V_AUDIT_RATE_PERIOD_RATE_ANY_ITEM_COUNT = 0) THEN

                        SELECT start_date INTO V_START_DATE
                        FROM audit_rate_period
                        WHERE 1 = 1
                            AND reference_table = 'tariff'
                            AND reference_id = V_TARIFF_ID
                            AND end_date IS NULL
                            AND rec_active_flag = 'Y'
                        LIMIT 1;

                        IF (V_RATE_EFFECTIVE_DATE > V_START_DATE) THEN

                            UPDATE audit_rate_period
                            SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
                            WHERE reference_table = 'tariff'
                                AND reference_id = V_TARIFF_ID
                                AND end_date IS NULL;

                            INSERT INTO audit_rate_period(
                                reference_table, 
                                reference_id,
                                start_date,
                                end_date,
                                rate,
                                rules_details
                            )
                            VALUES(
                                'tariff',
                                V_TARIFF_ID,
                                V_RATE_EFFECTIVE_DATE,
                                NULL,
                                V_RATE,
                                V_RULES_DETAILS
                            );

                            SET V_AUDIT_RATE_PERIOD_ID = (
                                SELECT MAX(id) FROM audit_rate_period
                            );

                            UPDATE rate_rule_tariff_original
                            SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                            WHERE id = V_TABLE_ID;

                        ELSEIF (V_RATE_EFFECTIVE_DATE < V_START_DATE) THEN

                            SELECT start_date INTO V_START_DATE
                            FROM audit_rate_period
                            WHERE 1 = 1
                                AND reference_table = 'tariff'
                                AND reference_id = V_TARIFF_ID
                                AND start_date > V_RATE_EFFECTIVE_DATE
                                AND rec_active_flag = 'Y'
                            ORDER BY start_date 
                            LIMIT 1;

                            INSERT INTO audit_rate_period(
                                reference_table, 
                                reference_id,
                                start_date,
                                end_date,
                                rate,
                                rules_details
                            )
                            VALUES(
                                'tariff',
                                V_TARIFF_ID,
                                V_RATE_EFFECTIVE_DATE,
                                DATE_SUB(V_START_DATE, INTERVAL 1 DAY),
                                V_RATE,
                                V_RULES_DETAILS
                            );

                            SET V_AUDIT_RATE_PERIOD_ID = (
                                SELECT MAX(id) FROM audit_rate_period
                            );

                            UPDATE rate_rule_tariff_original
                            SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                            WHERE id = V_TABLE_ID;

                        ELSE

                            INSERT INTO audit_rate_period(
                                reference_table, 
                                reference_id,
                                start_date,
                                end_date,
                                rate,
                                rules_details
                            )
                            VALUES(
                                'tariff',
                                V_TARIFF_ID,
                                V_RATE_EFFECTIVE_DATE,
                                NULL,
                                V_RATE,
                                V_RULES_DETAILS
                            );

                            SET V_AUDIT_RATE_PERIOD_ID = (
                                SELECT MAX(id) FROM audit_rate_period
                            );

                            UPDATE rate_rule_tariff_original
                            SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                            WHERE id = V_TABLE_ID;

                        END IF;

                    ELSE 

                        SELECT id INTO V_AUDIT_RATE_PERIOD_ID
                        FROM audit_rate_period
                        WHERE 1 = 1
                            AND reference_table = 'tariff'
                            AND reference_id = V_TARIFF_ID
                            AND start_date = V_RATE_EFFECTIVE_DATE
                            AND rate = V_RATE
                            AND rec_active_flag = 'Y'
                        LIMIT 1;

                        UPDATE rate_rule_tariff_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    END IF;

                ELSE

                    SELECT start_date INTO V_START_DATE
                    FROM audit_rate_period
                    WHERE reference_table = 'tariff'
                        AND reference_id = V_TARIFF_ID
                        AND end_date IS NULL
                    LIMIT 1;

                    IF (V_RATE_EFFECTIVE_DATE > V_START_DATE) THEN

                        UPDATE audit_rate_period
                        SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
                        WHERE reference_table = 'tariff'
                            AND reference_id = V_TARIFF_ID
                            AND end_date IS NULL;

                        INSERT INTO audit_rate_period(
                            reference_table, 
                            reference_id,
                            start_date,
                            end_date,
                            rate,
                            rules_details
                        )
                        VALUES(
                            'tariff',
                            V_TARIFF_ID,
                            V_RATE_EFFECTIVE_DATE,
                            NULL,
                            V_RATE,
                            V_RULES_DETAILS
                        );

                        SET V_AUDIT_RATE_PERIOD_ID = (
                            SELECT MAX(id) FROM audit_rate_period
                        );

                        UPDATE rate_rule_tariff_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    ELSEIF (V_RATE_EFFECTIVE_DATE < V_START_DATE) THEN

                        SELECT start_date INTO V_START_DATE
                        FROM audit_rate_period
                        WHERE reference_table = 'tariff'
                            AND reference_id = V_TARIFF_ID
                            AND start_date > V_RATE_EFFECTIVE_DATE
                            AND rec_active_flag = 'Y'
                        ORDER BY start_date
                        LIMIT 1;

                        INSERT INTO audit_rate_period(
                            reference_table, 
                            reference_id,
                            start_date,
                            end_date,
                            rate,
                            rules_details
                        )
                        VALUES(
                            'tariff',
                            V_TARIFF_ID,
                            V_RATE_EFFECTIVE_DATE,
                            DATE_SUB(V_START_DATE, INTERVAL 1 DAY),
                            V_RATE,
                            V_RULES_DETAILS
                        );

                        SET V_AUDIT_RATE_PERIOD_ID = (
                            SELECT MAX(id) FROM audit_rate_period
                        );

                        UPDATE rate_rule_tariff_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    ELSE

                        SELECT id INTO V_AUDIT_RATE_PERIOD_ID
                        FROM audit_rate_period
                        WHERE reference_table = 'tariff'
                            AND reference_id = V_TARIFF_ID
                            AND end_date IS NULL
                        LIMIT 1;

                        UPDATE rate_rule_tariff_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    END IF;

                END IF;

            END IF;

        ELSEIF(V_REFERENCE_TABLE = 'tariff_rate_by_quantity') THEN

            SELECT COUNT(1) INTO V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT
            FROM tariff_rate_by_quantity
            WHERE 1 = 1
                AND tariff_id = V_TARIFF_ID
                AND quantity_begin = V_QUANTITY_BEGIN
                AND (quantity_end IS NULL OR quantity_end = V_QUANTITY_END);

            IF(V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT = 0) THEN
              

                INSERT INTO tariff_rate_by_quantity(
                    tariff_id,
                    quantity_begin,
                    quantity_end,
                    rate,
                    base_amount
                )
                VALUES(
                    V_TARIFF_ID,
                    V_QUANTITY_BEGIN,
                    V_QUANTITY_END,
                    V_RATE,
                    V_BASE_AMOUNT
                );

                SET V_TARIFF_RATE_BY_QUANTITY_ID = (
                    SELECT MAX(id) FROM tariff_rate_by_quantity
                );

                INSERT INTO audit_rate_period(
                    reference_table, 
                    reference_id,
                    start_date,
                    end_date,
                    rate,
                    rules_details
                )
                VALUES(
                    'tariff_rate_by_quantity',
                    V_TARIFF_RATE_BY_QUANTITY_ID,
                    V_RATE_EFFECTIVE_DATE,
                    NULL,
                    V_RATE,
                    V_RULES_DETAILS
                );

                SET V_AUDIT_RATE_PERIOD_ID = (
                    SELECT MAX(id) FROM audit_rate_period
                );

                UPDATE rate_rule_tariff_original
                SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                WHERE id = V_TABLE_ID;

            ELSE
                
                SELECT id INTO V_TARIFF_RATE_BY_QUANTITY_ID
                FROM tariff_rate_by_quantity
                WHERE 1 = 1
                    AND tariff_id = V_TARIFF_ID
                    AND quantity_begin = V_QUANTITY_BEGIN
                    AND (quantity_end IS NULL OR quantity_end = V_QUANTITY_END);

                SELECT COUNT(1) INTO V_AUDIT_RATE_PERIOD_ITEM_COUNT
                FROM audit_rate_period
                WHERE 1 = 1
                    AND reference_table = 'tariff_rate_by_quantity'
                    AND reference_id = V_TARIFF_RATE_BY_QUANTITY_ID
                    AND rec_active_flag = 'Y';

                IF(V_AUDIT_RATE_PERIOD_ITEM_COUNT = 0) THEN
                  
                    INSERT INTO audit_rate_period(
                        reference_table, 
                        reference_id,
                        start_date,
                        end_date,
                        rate,
                        rules_details
                    )
                    VALUES(
                        'tariff_rate_by_quantity',
                        V_TARIFF_RATE_BY_QUANTITY_ID,
                        V_RATE_EFFECTIVE_DATE,
                        NULL,
                        V_RATE,
                        V_RULES_DETAILS
                    );

                    SET V_AUDIT_RATE_PERIOD_ID = (
                        SELECT MAX(id) FROM audit_rate_period
                    );

                    UPDATE rate_rule_tariff_original
                    SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                    WHERE id = V_TABLE_ID;

                ELSE

                    SELECT start_date INTO V_START_DATE
                    FROM audit_rate_period
                    WHERE reference_table = 'tariff_rate_by_quantity'
                        AND reference_id = V_TARIFF_RATE_BY_QUANTITY_ID
                        AND end_date IS NULL
                        AND rec_active_flag = 'Y'
                    LIMIT 1;

                    IF (V_RATE_EFFECTIVE_DATE > V_START_DATE) THEN

                        UPDATE tariff_rate_by_quantity
                        SET 
                            rate = V_RATE,
                            base_amount = V_BASE_AMOUNT
                        WHERE 1 = 1
                            AND id = V_TARIFF_RATE_BY_QUANTITY_ID;

                        UPDATE audit_rate_period
                        SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
                        WHERE reference_table = 'tariff_rate_by_quantity'
                            AND reference_id = V_TARIFF_RATE_BY_QUANTITY_ID
                            AND end_date IS NULL;

                        INSERT INTO audit_rate_period(
                            reference_table, 
                            reference_id,
                            start_date,
                            end_date,
                            rate,
                            rules_details
                        )
                        VALUES(
                            'tariff_rate_by_quantity',
                            V_TARIFF_RATE_BY_QUANTITY_ID,
                            V_RATE_EFFECTIVE_DATE,
                            NULL,
                            V_RATE,
                            V_RULES_DETAILS
                        );

                        SET V_AUDIT_RATE_PERIOD_ID = (
                            SELECT MAX(id) FROM audit_rate_period
                        );

                        UPDATE rate_rule_tariff_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    ELSEIF (V_RATE_EFFECTIVE_DATE < V_START_DATE) THEN

                        SELECT start_date INTO V_START_DATE
                        FROM audit_rate_period
                        WHERE reference_table = 'tariff_rate_by_quantity'
                            AND reference_id = V_TARIFF_RATE_BY_QUANTITY_ID
                            AND start_date > V_RATE_EFFECTIVE_DATE
                            AND rec_active_flag = 'Y'
                        ORDER BY start_date
                        LIMIT 1;

                        INSERT INTO audit_rate_period(
                            reference_table, 
                            reference_id,
                            start_date,
                            end_date,
                            rate,
                            rules_details
                        )
                        VALUES(
                            'tariff_rate_by_quantity',
                            V_TARIFF_RATE_BY_QUANTITY_ID,
                            V_RATE_EFFECTIVE_DATE,
                            DATE_SUB(V_START_DATE, INTERVAL 1 DAY),
                            V_RATE,
                            V_RULES_DETAILS
                        );

                        SET V_AUDIT_RATE_PERIOD_ID = (
                            SELECT MAX(id) FROM audit_rate_period
                        );

                        UPDATE rate_rule_tariff_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    ELSE

                        SELECT id INTO V_AUDIT_RATE_PERIOD_ID
                        FROM audit_rate_period
                        WHERE reference_table = 'tariff_rate_by_quantity'
                            AND reference_id = V_TARIFF_RATE_BY_QUANTITY_ID
                            AND end_date IS NULL
                            AND rec_active_flag = 'Y'
                        LIMIT 1;

                        UPDATE rate_rule_tariff_original
                        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
                        WHERE id = V_TABLE_ID;

                    END IF;

                END IF;

            END IF;

        END IF; -- /.V_REFERENCE_TABLE

        UPDATE rate_rule_tariff_original
        SET sync_flag = 'Y'
        WHERE id = V_TABLE_ID;

    END IF; -- /.V_NOT_UPDATE_RECORD_COUNT

END