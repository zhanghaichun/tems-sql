DROP PROCEDURE IF EXISTS SP_UPDATE_MTM_RATE_MODULE_TABLES;
CREATE PROCEDURE SP_UPDATE_MTM_RATE_MODULE_TABLES(
  PARAM_SYSTEM_RATE_RULE_ID INT,
  PARAM_BATCH_NO VARCHAR(64)
)

BEGIN
  
    /**
     * Dealing with update modifications of month to month rate rules.
     */
    
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

    DECLARE V_TARIFF_FILE_NAME VARCHAR(64);

    DECLARE V_TARIFF_NAME VARCHAR(500);
    DECLARE V_BASE_AMOUNT DOUBLE(20,5);
    DECLARE V_MULTIPLIER DOUBLE(20, 5);
    DECLARE V_RATE DOUBLE(20, 6);
    DECLARE V_RULES_DETAILS VARCHAR(500);
    DECLARE V_TARIFF_PAGE VARCHAR(32);

    DECLARE V_PART_SECTION VARCHAR(32);
    DECLARE V_ITEM_NUMBER VARCHAR(12);
    DECLARE V_CRTC_NUMBER VARCHAR(12);

    DECLARE V_STRIPPED_CIRCUIT_NUMBER VARCHAR(64);
    DECLARE V_TERM VARCHAR(32);
    DECLARE V_CONTRACT_SERVICE_SCHEDULE_NAME VARCHAR(128);
    DECLARE V_TOTAL_VOLUME_BEGIN INT;
    DECLARE V_TOTAL_VOLUME_END INT;
    DECLARE V_EARLY_TERMINATION_FEE VARCHAR(256);
    DECLARE V_MMBC VARCHAR(64);
    DECLARE V_RENEWAL_TERM_AFTER_TERM_EXPIRATION VARCHAR(16);
    DECLARE V_CONTRACT_NAME VARCHAR(500);

    DECLARE V_DISOCUNT DOUBLE(20, 5);
    DECLARE V_EXCLUSION_BAN VARCHAR(128);
    DECLARE V_EXCLUSION_ITEM_DESCRIPTION VARCHAR(255);
    DECLARE V_NOTES VARCHAR(500);

    DECLARE V_AUDIT_MTM_ID INT;

 
    DECLARE V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID VARCHAR(12);
    DECLARE V_ORIGIN_AUDIT_RATE_PERIOD_ID VARCHAR(12);
    DECLARE V_ORIGIN_CHARGE_TYPE VARCHAR(12);
    DECLARE V_ORIGIN_KEY_FIELD VARCHAR(64);
    DECLARE V_ORIGIN_RATE_EFFECTIVE_DATE DATE;
    DECLARE V_ORIGIN_SUMMARY_VENDOR_NAME VARCHAR(128);
    DECLARE V_ORIGIN_VENDOR_NAME VARCHAR(128);
    DECLARE V_ORIGIN_USOC VARCHAR(16);
    DECLARE V_ORIGIN_USOC_DESCRIPTION VARCHAR(255);
    DECLARE V_ORIGIN_SUB_PRODUCT VARCHAR(128);
    DECLARE V_ORIGIN_LINE_ITEM_CODE_DESCRIPTION VARCHAR(255);
    DECLARE V_ORIGIN_LINE_ITEM_CODE VARCHAR(64);
    DECLARE V_ORIGIN_ITEM_TYPE VARCHAR(64);
    DECLARE V_ORIGIN_ITEM_DESCRIPTIOIN VARCHAR(128);
    DECLARE V_ORIGIN_QUANTITY_BEGIN INT;
    DECLARE V_ORIGIN_QUANTITY_END INT;
    DECLARE V_ORIGIN_TARIFF_FILE_NAME VARCHAR(64);
    DECLARE V_ORIGIN_TARIFF_NAME VARCHAR(500);
    DECLARE V_ORIGIN_BASE_AMOUNT DOUBLE(20, 5);
    DECLARE V_ORIGIN_MULTIPLIER DOUBLE(20, 5);
    DECLARE V_ORIGIN_RATE DOUBLE(20, 6);
    DECLARE V_ORIGIN_RULES_DETAILS VARCHAR(500);
    DECLARE V_ORIGIN_TARIFF_PAGE VARCHAR(32);
    DECLARE V_ORIGIN_PART_SECTION VARCHAR(32);
    DECLARE V_ORIGIN_ITEM_NUMBER VARCHAR(12);
    DECLARE V_ORIGIN_CRTC_NUMBER VARCHAR(12);
    DECLARE V_ORIGIN_DISOCUNT DOUBLE(20, 5);
    DECLARE V_ORIGIN_EXCUSION_BAN VARCHAR(128);
    DECLARE V_ORIGIN_EXCLUSION_ITEM_DESCRIPTION VARCHAR(255);
    DECLARE V_ORIGIN_NOTES VARCHAR(500);

    DECLARE V_ORIGIN_STRIPPED_CIRCUIT_NUMBER VARCHAR(64);
    DECLARE V_ORIGIN_TERM VARCHAR(32);
    DECLARE V_ORIIGIN_CONTRACT_SERVICE_SCHEDULE_NAME VARCHAR(128);
    DECLARE V_ORIGIN_TOTAL_VOLUME_BEGIN INT;
    DECLARE V_ORIGIN_TOTAL_VOLUME_END INT;
    DECLARE V_ORIGIN_EARLY_TERMINATION_FEE VARCHAR(256);
    DECLARE V_ORIGIN_MMBC VARCHAR(64);
    DECLARE V_ORIGIN_RENEWAL_TERM_AFTER_TERM_EXPIRATION VARCHAR(16);
    DECLARE V_ORIGIN_CONTRACT_NAME VARCHAR(500);

    DECLARE V_TARIFF_FILE_ITEM_COUNT INT;
    DECLARE V_CONTRACT_FILE_ITEM_COUNT INT;

    DECLARE V_RATE_MODE VARCHAR(64);
    DECLARE V_VENDOR_GROUP_ID INT;

    DECLARE V_REFERENCE_TABLE VARCHAR(64);

    DECLARE V_START_DATE DATE;

    DECLARE V_AUDIT_PERIOD_ITEM_COUNT INT;

    DECLARE V_TARIFF_RATE_BY_QUANTITY_ID INT;
    DECLARE V_CONTRACT_RATE_BY_QUANTITY_ID INT;

    DECLARE V_MAPPING_KEY_FIELD VARCHAR(64);

    DECLARE V_TARIFF_FILE_ID INT;
    DECLARE V_TARIFF_ID INT;

    DECLARE V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT INT;
    DECLARE V_CONTRACT_RATE_BY_QUANTITY_ITEM_COUNT INT;

    DECLARE V_UPDATED_FLAG BOOLEAN DEFAULT FALSE;

    DECLARE V_BAN_ID INT;

    UPDATE rate_rule_mtm_original
    SET sync_flag = 'N', modified_timestamp = NOW()
    WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

    -- Uploaded data.
    SELECT
        summary_vendor_name,
        charge_type,
        key_field,
        usoc,
        usoc_long_description,
        stripped_circuit_number,
        sub_product,
        rate,
        effective_date,
        term,
        item_description,
        line_item_code,
        line_item_code_description
            INTO
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
                V_ITEM_DESCRIPTIOIN,
                V_LINE_ITEM_CODE,
                V_LINE_ITEM_CODE_DESCRIPTION
    FROM rate_rule_mtm_master_batch
    WHERE batch_no = PARAM_BATCH_NO
        AND rate_id = PARAM_SYSTEM_RATE_RULE_ID;

    -- Original data.
    SELECT
        audit_reference_mapping_id,
        audit_rate_period_id,
        summary_vendor_name,
        charge_type,
        key_field,
        usoc,
        usoc_description,
        stripped_circuit_number,
        sub_product,
        rate,
        rate_effective_date,
        term,
        item_description,
        line_item_code,
        line_item_code_description
        notes
            INTO
                V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID,
                V_ORIGIN_AUDIT_RATE_PERIOD_ID,
                V_ORIGIN_SUMMARY_VENDOR_NAME,
                V_ORIGIN_CHARGE_TYPE,
                V_ORIGIN_KEY_FIELD,
                V_ORIGIN_USOC,
                V_ORIGIN_USOC_DESCRIPTION,
                V_ORIGIN_STRIPPED_CIRCUIT_NUMBER,
                V_ORIGIN_SUB_PRODUCT,
                V_ORIGIN_RATE,
                V_ORIGIN_RATE_EFFECTIVE_DATE,
                V_ORIGIN_TERM,
                V_ORIGIN_ITEM_DESCRIPTIOIN,
                V_ORIGIN_LINE_ITEM_CODE,
                V_ORIGIN_LINE_ITEM_CODE_DESCRIPTION
    FROM rate_rule_mtm_original
    WHERE id = PARAM_SYSTEM_RATE_RULE_ID
        AND rec_active_flag = 'Y';

    -- Contrast Fields.
    CONTRAST_FIELDS: BEGIN

        IF( IFNULL(V_RATE, '') != IFNULL(V_ORIGIN_RATE, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_USOC, '') != IFNULL(V_ORIGIN_USOC, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_USOC_DESCRIPTION, '') != IFNULL(V_ORIGIN_USOC_DESCRIPTION, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_STRIPPED_CIRCUIT_NUMBER, '') != IFNULL(V_ORIGIN_STRIPPED_CIRCUIT_NUMBER, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_ITEM_DESCRIPTIOIN, '') != IFNULL(V_ORIGIN_ITEM_DESCRIPTIOIN, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_LINE_ITEM_CODE, '') != IFNULL(V_ORIGIN_LINE_ITEM_CODE, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_LINE_ITEM_CODE_DESCRIPTION, '') != IFNULL(V_ORIGIN_LINE_ITEM_CODE_DESCRIPTION, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_RATE_EFFECTIVE_DATE, '') != IFNULL(V_ORIGIN_RATE_EFFECTIVE_DATE, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_SUMMARY_VENDOR_NAME, '') != IFNULL(V_ORIGIN_SUMMARY_VENDOR_NAME,'') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_CHARGE_TYPE, '') != IFNULL(V_ORIGIN_CHARGE_TYPE, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_SUB_PRODUCT, '') != IFNULL(V_ORIGIN_SUB_PRODUCT, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_TERM, '') != IFNULL(V_ORIGIN_TERM, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_KEY_FIELD, '') != IFNULL(V_ORIGIN_KEY_FIELD, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

    END CONTRAST_FIELDS;

    IF(V_UPDATED_FLAG = TRUE) THEN

        UPDATE rate_rule_mtm_original
        SET 
            summary_vendor_name = V_SUMMARY_VENDOR_NAME,
            charge_type = V_CHARGE_TYPE,
            key_field = V_KEY_FIELD,
            usoc = V_USOC,
            usoc_description = V_USOC_DESCRIPTION,
            sub_product = V_SUB_PRODUCT,
            stripped_circuit_number = V_STRIPPED_CIRCUIT_NUMBER,
            rate = V_RATE,
            rate_effective_date = V_RATE_EFFECTIVE_DATE,
            term = V_TERM,
            item_description = V_ITEM_DESCRIPTIOIN,
            line_item_code = V_LINE_ITEM_CODE,
            line_item_code_description = V_LINE_ITEM_CODE_DESCRIPTION
        WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

        SET V_REFERENCE_TABLE = (

            SELECT arp.reference_table 
            FROM rate_rule_mtm_original r 
                LEFT JOIN audit_rate_period arp ON r.audit_rate_period_id = arp.id
            WHERE r.id = PARAM_SYSTEM_RATE_RULE_ID
            LIMIT 1

        );

        IF ( IFNULL(V_SUMMARY_VENDOR_NAME, '') != IFNULL(V_ORIGIN_SUMMARY_VENDOR_NAME,'') ) THEN

            SET V_VENDOR_GROUP_ID = FN_GET_MTM_VENDOR_GROUP_ID(PARAM_SYSTEM_RATE_RULE_ID);

            UPDATE audit_reference_mapping
            SET 
                vendor_group_id = V_VENDOR_GROUP_ID,
                summary_vendor_name = V_SUMMARY_VENDOR_NAME
            WHERE id = V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID
                AND rec_active_flag = 'Y';

        END IF;

        UPDATE audit_reference_mapping
        SET 
            charge_type = V_CHARGE_TYPE, 
            usoc = V_USOC, 
            usoc_description = V_USOC_DESCRIPTION,
            circuit_number = V_STRIPPED_CIRCUIT_NUMBER,
            sub_product = V_SUB_PRODUCT, 
            line_item_code = V_LINE_ITEM_CODE, 
            line_item_code_description = V_LINE_ITEM_CODE_DESCRIPTION, 
            item_description = V_ITEM_DESCRIPTIOIN, 
            modified_timestamp = NOW()
        WHERE id = V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID
            AND rec_active_flag = 'Y';

        SET V_AUDIT_MTM_ID = (
            SELECT audit_reference_id
            FROM audit_reference_mapping
            WHERE id = V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID
                AND rec_active_flag = 'Y'
        );

        UPDATE audit_mtm
        SET 
            charge_type = V_CHARGE_TYPE, 
            summary_vendor_name = V_SUMMARY_VENDOR_NAME,
            key_field = V_KEY_FIELD,
            usoc = V_USOC,
            usoc_long_description = V_USOC_DESCRIPTION,
            sub_product = V_SUB_PRODUCT, 
            rate = V_RATE, 
            effective_date = V_RATE_EFFECTIVE_DATE, 
            term = V_TERM, 
            item_description = V_ITEM_DESCRIPTIOIN, 
            line_item_code = V_LINE_ITEM_CODE, 
            line_item_code_description = V_LINE_ITEM_CODE_DESCRIPTION
        WHERE id = V_AUDIT_MTM_ID
            AND rec_active_flag = 'Y';

        IF(V_REFERENCE_TABLE = 'audit_mtm') THEN

            SELECT COUNT(1) INTO V_AUDIT_PERIOD_ITEM_COUNT
            FROM audit_rate_period
            WHERE reference_table = 'audit_mtm'
                AND reference_id = V_AUDIT_MTM_ID
                AND end_date IS NOT NULL;

            IF (V_AUDIT_PERIOD_ITEM_COUNT = 0) THEN

                UPDATE audit_rate_period
                SET
                    rate = V_RATE,
                    start_date = V_RATE_EFFECTIVE_DATE
                WHERE id = V_ORIGIN_AUDIT_RATE_PERIOD_ID
                    AND rec_active_flag = 'Y';

            ELSE

                UPDATE audit_rate_period
                SET
                    rate = V_RATE,
                    start_date = V_RATE_EFFECTIVE_DATE
                WHERE id = V_ORIGIN_AUDIT_RATE_PERIOD_ID
                    AND rec_active_flag = 'Y';

                -- Query previous record.
                SELECT start_date INTO V_START_DATE
                FROM audit_rate_period
                WHERE rec_active_flag = 'Y'
                    AND start_date < V_RATE_EFFECTIVE_DATE
                    AND reference_table = 'audit_mtm'
                    AND reference_id = V_AUDIT_MTM_ID
                GROUP BY start_date
                ORDER BY start_date DESC
                LIMIT 1;

                -- Update end_date of previous record.
                UPDATE audit_rate_period
                SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
                WHERE rec_active_flag = 'Y'
                    AND start_date = V_START_DATE
                    AND reference_table = 'audit_mtm'
                    AND reference_id = V_AUDIT_MTM_ID;

            END IF;

        END IF;

        UPDATE rate_rule_mtm_original
        SET sync_flag = 'Y'
        WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

    ELSE

        UPDATE rate_rule_mtm_original
        SET sync_flag = 'Y'
        WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

    END IF;

END