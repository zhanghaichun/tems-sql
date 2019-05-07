DROP PROCEDURE IF EXISTS SP_GET_MTM_MAPPING_RECORD_ID;
CREATE PROCEDURE SP_GET_MTM_MAPPING_RECORD_ID(
  IN PARAM_AUDIT_KEY_FIELD VARCHAR(64),
  IN PARAM_MASTER_TABLE_ID INT,
  OUT PARAM_MAPPING_ITEM_COUNT VARCHAR(64),
  OUT PARAM_MAPPING_ITEM_ID VARCHAR(64)
)

BEGIN 
  
    DECLARE V_SUMMARY_VENDOR_NAME VARCHAR(128);
    DECLARE V_USOC VARCHAR(16);
    DECLARE V_USOC_DESCRIPTION VARCHAR(255);
    DECLARE V_LINE_ITEM_CODE_DESCRIPTION VARCHAR(255);
    DECLARE V_LINE_ITEM_CODE VARCHAR(64);
    DECLARE V_ITEM_DESCRIPTIOIN VARCHAR(128);
    DECLARE V_STRIPPED_CIRCUIT_NUMBER VARCHAR(64);

    DECLARE CONST_USOC_KEY VARCHAR(64) DEFAULT 'usoc';
    DECLARE CONST_LINE_ITEM_CODE_KEY VARCHAR(64) DEFAULT 'line_item_code';
    DECLARE CONST_LINE_ITEM_CODE_DESCRIPTION_KEY VARCHAR(64) DEFAULT 'line_item_code_description';
    DECLARE CONST_ITEM_DESCRIPTION_KEY VARCHAR(64) DEFAULT 'item_description';
    DECLARE CONST_USOC_STRIPPED_CIRCUIT_NUMBER_KEY VARCHAR(64) DEFAULT 'usoc & stripped_circuit_number';
    DECLARE CONST_STRIPPED_CIRCUIT_NUMBER_KEY VARCHAR(64) DEFAULT 'stripped_circuit_number';
    DECLARE CONST_STRIPPED_CIRCUIT_NUMBER_ITEM_DESCRIPTION_KEY VARCHAR(64) DEFAULT 'stripped_circuit_number & item_description';
    DECLARE CONST_STRIPPED_CIRCUIT_NUMBER_LINE_ITEM_CODE_KEY VARCHAR(64) DEFAULT 'stripped_circuit_number & line_item_code';
    DECLARE CONST_STRIPPED_CIRCUIT_NUMBER_LINE_ITEM_CODE_DESCRIPTION_KEY VARCHAR(64) DEFAULT 'stripped_circuit_number & line_item_code_description';

    SELECT
        summary_vendor_name,
        stripped_circuit_number,
        usoc,
        usoc_description,
        line_item_code_description,
        line_item_code,
        item_description
            INTO
                V_SUMMARY_VENDOR_NAME,
                V_STRIPPED_CIRCUIT_NUMBER,
                V_USOC,
                V_USOC_DESCRIPTION,
                V_LINE_ITEM_CODE_DESCRIPTION,
                V_LINE_ITEM_CODE,
                V_ITEM_DESCRIPTIOIN
    FROM rate_rule_mtm_original
    WHERE id = PARAM_MASTER_TABLE_ID
        AND rec_active_flag = 'Y';


    IF ( PARAM_AUDIT_KEY_FIELD = CONST_USOC_KEY ) THEN

        SELECT 
            COUNT(1), 
            id
                INTO 
                PARAM_MAPPING_ITEM_COUNT,
                PARAM_MAPPING_ITEM_ID
        FROM audit_reference_mapping
        WHERE 1 = 1
            AND audit_reference_type_id = 18
            AND usoc = V_USOC
            AND (
                CASE
                    WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
                        summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    ELSE
                        summary_vendor_name IS NULL
                END
            )
            AND rec_active_flag = 'Y';

    ELSEIF (PARAM_AUDIT_KEY_FIELD = CONST_LINE_ITEM_CODE_KEY) THEN

        SELECT 
            COUNT(1), 
            id
                INTO 
                    PARAM_MAPPING_ITEM_COUNT,
                    PARAM_MAPPING_ITEM_ID
        FROM audit_reference_mapping
        WHERE 1 = 1
            AND audit_reference_type_id = 18
            AND line_item_code = V_LINE_ITEM_CODE
            AND (
                CASE
                    WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
                        summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    ELSE
                        summary_vendor_name IS NULL
                END
            )
            AND rec_active_flag = 'Y';

    ELSEIF (PARAM_AUDIT_KEY_FIELD = CONST_LINE_ITEM_CODE_DESCRIPTION_KEY) THEN

        SELECT 
            COUNT(1), 
            id
                INTO 
                    PARAM_MAPPING_ITEM_COUNT,
                    PARAM_MAPPING_ITEM_ID
        FROM audit_reference_mapping
        WHERE 1 = 1
            AND audit_reference_type_id = 18
            AND line_item_code_description = V_LINE_ITEM_CODE_DESCRIPTION
            AND (
                CASE
                    WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
                        summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    ELSE
                        summary_vendor_name IS NULL
                END
            )
            AND rec_active_flag = 'Y';

    ELSEIF (PARAM_AUDIT_KEY_FIELD = CONST_ITEM_DESCRIPTION_KEY) THEN

        SELECT 
            COUNT(1), 
            id
                INTO 
                    PARAM_MAPPING_ITEM_COUNT,
                    PARAM_MAPPING_ITEM_ID
        FROM audit_reference_mapping
        WHERE 1 = 1
            AND audit_reference_type_id = 18
            AND item_description = V_ITEM_DESCRIPTIOIN
            AND (
                CASE
                    WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
                        summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    ELSE
                        summary_vendor_name IS NULL
                END
            )
            AND rec_active_flag = 'Y';

    ELSEIF (PARAM_AUDIT_KEY_FIELD = CONST_USOC_STRIPPED_CIRCUIT_NUMBER_KEY) THEN

        SELECT 
            COUNT(1), 
            id
                INTO 
                    PARAM_MAPPING_ITEM_COUNT,
                    PARAM_MAPPING_ITEM_ID
        FROM audit_reference_mapping
        WHERE 1 = 1
            AND audit_reference_type_id = 18
            AND usoc = V_USOC
            AND circuit_number = V_STRIPPED_CIRCUIT_NUMBER
            AND (
                CASE
                    WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
                        summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    ELSE
                        summary_vendor_name IS NULL
                END
            )
            AND rec_active_flag = 'Y';

    ELSEIF (PARAM_AUDIT_KEY_FIELD = CONST_STRIPPED_CIRCUIT_NUMBER_KEY) THEN

        SELECT 
            COUNT(1), 
            id
                INTO 
                    PARAM_MAPPING_ITEM_COUNT,
                    PARAM_MAPPING_ITEM_ID
        FROM audit_reference_mapping
        WHERE 1 = 1
            AND audit_reference_type_id = 18
            AND circuit_number = V_STRIPPED_CIRCUIT_NUMBER
            AND (
                CASE
                    WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
                        summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    ELSE
                        summary_vendor_name IS NULL
                END
            )
            AND rec_active_flag = 'Y';

    ELSEIF (PARAM_AUDIT_KEY_FIELD = CONST_STRIPPED_CIRCUIT_NUMBER_ITEM_DESCRIPTION_KEY) THEN

        SELECT 
            COUNT(1), 
            id
                INTO 
                    PARAM_MAPPING_ITEM_COUNT,
                    PARAM_MAPPING_ITEM_ID
        FROM audit_reference_mapping
        WHERE 1 = 1
            AND audit_reference_type_id = 18
            AND circuit_number = V_STRIPPED_CIRCUIT_NUMBER
            AND item_description = V_ITEM_DESCRIPTIOIN
            AND (
                CASE
                    WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
                        summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    ELSE
                        summary_vendor_name IS NULL
                END
            )
            AND rec_active_flag = 'Y';

    ELSEIF (PARAM_AUDIT_KEY_FIELD = CONST_STRIPPED_CIRCUIT_NUMBER_LINE_ITEM_CODE_DESCRIPTION_KEY) THEN

        SELECT 
            COUNT(1), 
            id
                INTO 
                    PARAM_MAPPING_ITEM_COUNT,
                    PARAM_MAPPING_ITEM_ID
        FROM audit_reference_mapping
        WHERE 1 = 1
            AND audit_reference_type_id = 18
            AND circuit_number = V_STRIPPED_CIRCUIT_NUMBER
            AND line_item_code_description = V_LINE_ITEM_CODE_DESCRIPTION
            AND (
                CASE
                    WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
                        summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    ELSE
                        summary_vendor_name IS NULL
                END
            )
            AND rec_active_flag = 'Y';

    ELSEIF (PARAM_AUDIT_KEY_FIELD = CONST_STRIPPED_CIRCUIT_NUMBER_LINE_ITEM_CODE_KEY) THEN

        SELECT 
            COUNT(1), 
            id
                INTO 
                    PARAM_MAPPING_ITEM_COUNT,
                    PARAM_MAPPING_ITEM_ID
        FROM audit_reference_mapping
        WHERE 1 = 1
            AND audit_reference_type_id = 18
            AND circuit_number = V_STRIPPED_CIRCUIT_NUMBER
            AND line_item_code = V_LINE_ITEM_CODE
            AND (
                CASE
                    WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
                        summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    ELSE
                        summary_vendor_name IS NULL
                END
            )
            AND rec_active_flag = 'Y';

    END IF;

END