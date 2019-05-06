
DROP PROCEDURE IF EXISTS SP_UPDATE_CONTRACT_MASTER_DATA_TO_RATE_MODULE_TABLES;
CREATE PROCEDURE SP_UPDATE_CONTRACT_MASTER_DATA_TO_RATE_MODULE_TABLES(PARAM_BATCH_NO VARCHAR(64))

BEGIN
  
    /**
     * Put uploading contract rate rules into rate module tables.
     */
  
    DECLARE V_AUDIT_REFERENCE_MAPPING_ID INT;
    DECLARE V_AUDIT_RATE_PERIOD_ID INT;
    DECLARE V_SYSTEM_RULE_ID INT;
    DECLARE V_CHARGE_TYPE VARCHAR(12);
    DECLARE V_KEY_FIELD VARCHAR(64);
    DECLARE V_RATE_EFFECTIVE_DATE DATE;
    DECLARE V_SUMMARY_VENDOR_NAME VARCHAR(128);
    DECLARE V_RENEWAL_TERM_AFTER_TERM_EXPIRATION VARCHAR(16);
    DECLARE V_USOC VARCHAR(16);
    DECLARE V_USOC_DESCRIPTION VARCHAR(255);
    DECLARE V_SUB_PRODUCT VARCHAR(128);
    DECLARE V_LINE_ITEM_CODE_DESCRIPTION VARCHAR(255);
    DECLARE V_LINE_ITEM_CODE VARCHAR(64);
    DECLARE V_MMBC VARCHAR(64);
    DECLARE V_ITEM_DESCRIPTIOIN VARCHAR(128);
    DECLARE V_TOTAL_VOLUME_BEGIN INT;
    DECLARE V_TOTAL_VOLUME_END INT;

    DECLARE V_EARLY_TERMINATION_FEE VARCHAR(256);

    DECLARE V_CONTRACT_NAME VARCHAR(500);
    DECLARE V_BASE_AMOUNT INT;
    DECLARE V_STRIPPED_CIRCUIT_NUMBER VARCHAR(64);
    DECLARE V_RATE DOUBLE(20, 6);
    DECLARE V_RULES_DETAILS VARCHAR(500);
    DECLARE V_CONTRACT_SERVICE_SCHEDULE_NAME VARCHAR(128);

    DECLARE V_TERM VARCHAR(32);
    DECLARE V_ITEM_NUMBER VARCHAR(12);
    DECLARE V_CRTC_NUMBER VARCHAR(12);

    DECLARE V_DISOCUNT DOUBLE(20, 5);
    DECLARE V_EXCUSION_BAN VARCHAR(128);
    DECLARE V_EXCLUSION_ITEM_DESCRIPTION VARCHAR(255);
    DECLARE V_NOTES VARCHAR(500);

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

   
    DECLARE V_INSERTED_DUPLICATED_FLAG BOOLEAN DEFAULT TRUE;

    DECLARE V_ORIGIN_ITEM_COUNT INT;


    DECLARE V_LOADING_MODE VARCHAR(12);

    DECLARE V_UPDATE_LOADING_MODE VARCHAR(12) DEFAULT 'UPADTE';
    DECLARE V_INSERT_LOADING_MODE VARCHAR(12) DEFAULT 'INSERT';

    DECLARE V_CURSOR_DONE_FLAG BOOLEAN DEFAULT FALSE;

    DECLARE V_CONTRACT_MASTER_DATA_CURSOR CURSOR FOR
        SELECT
            TRIM( rate_id ),
            TRIM( summary_vendor_name ),
            TRIM( charge_type ),
            TRIM( key_field ),
            TRIM( usoc ),
            TRIM( usoc_long_description ),
            TRIM( stripped_circuit_number ),
            TRIM( sub_product ),
            TRIM( rate ),
            TRIM( effective_date ),
            TRIM( term ),
            TRIM( renewal_term_after_term_expiration ),
            TRIM( early_termination_fee ),
            TRIM( item_description ),
            TRIM( contract_name ),
            TRIM( contract_service_schedule_name ),
            TRIM( line_item_code ),
            TRIM( line_item_code_description ),
            TRIM( total_volume_begin ),
            TRIM( total_volume_end ),
            TRIM( mmbc ),
            TRIM( discount ),
            TRIM( notes )
        FROM rate_rule_contact_master_batch
        WHERE batch_no = PARAM_BATCH_NO;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_CURSOR_DONE_FLAG = TRUE;

  
    OPEN V_CONTRACT_MASTER_DATA_CURSOR;

        LABEL1:
        WHILE NOT V_CURSOR_DONE_FLAG DO 
            FETCH V_CONTRACT_MASTER_DATA_CURSOR 
                INTO
                    V_SYSTEM_RULE_ID,
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
                    V_NOTES;

            IF (V_CURSOR_DONE_FLAG) THEN
                LEAVE LABEL1;
            END IF;

            /**
             * Get the mode of modification. (insert or update)
             */
            SET V_SYSTEM_RULE_ID = TRIM(V_SYSTEM_RULE_ID);

            IF ( V_SYSTEM_RULE_ID IS NULL OR V_SYSTEM_RULE_ID = '') THEN

                SET V_LOADING_MODE = V_INSERT_LOADING_MODE;

            ELSE

                SET V_LOADING_MODE = V_UPDATE_LOADING_MODE;

            END IF;

            IF (V_LOADING_MODE = V_UPDATE_LOADING_MODE) THEN

                CALL SP_UPDATE_CONTRACT_RATE_MODULE_TABLES(V_SYSTEM_RULE_ID, PARAM_BATCH_NO);

            ELSEIF (V_LOADING_MODE = V_INSERT_LOADING_MODE) THEN

                INSERT INTO rate_rule_contract_original(
                    sync_flag,
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
                    notes,
                    created_timestamp
                )
                VALUES(
                    'N',
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
                    V_NOTES,
                    NOW()
                );

                CALL SP_INSERT_INTO_CONTRACT_RATE_MODULE_TABLES();

            END IF;

        END WHILE LABEL1;

    CLOSE V_CONTRACT_MASTER_DATA_CURSOR;

    -- Update rate status of rate rules.
    CALL SP_UPDATE_AUDIT_RATE_STATUS();

    DELETE FROM rate_rule_contact_master_batch WHERE batch_no = PARAM_BATCH_NO;

END;