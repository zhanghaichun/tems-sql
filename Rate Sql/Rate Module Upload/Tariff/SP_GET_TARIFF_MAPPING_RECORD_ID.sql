DROP PROCEDURE IF EXISTS SP_GET_TARIFF_MAPPING_RECORD_ID;
CREATE PROCEDURE SP_GET_TARIFF_MAPPING_RECORD_ID(
  IN PARAM_AUDIT_KEY_FIELD VARCHAR(64),
  IN PARAM_MASTER_TABLE_ID INT,
  OUT PARAM_MAPPING_ITEM_COUNT VARCHAR(64),
  OUT PARAM_MAPPING_ITEM_ID VARCHAR(64)
)

BEGIN 
  
  /**
   * 获取 tariff_mapping_record_id
   */
  DECLARE V_SUMMARY_VENDOR_NAME VARCHAR(128);
  DECLARE V_VENDOR_NAME VARCHAR(128);
  DECLARE V_USOC VARCHAR(16);
  DECLARE V_USOC_DESCRIPTION VARCHAR(255);
  DECLARE V_LINE_ITEM_CODE_DESCRIPTION VARCHAR(255);
  DECLARE V_LINE_ITEM_CODE VARCHAR(64);
  DECLARE V_ITEM_TYPE VARCHAR(64);
  DECLARE V_ITEM_DESCRIPTIOIN VARCHAR(128);
  DECLARE V_QUANTITY_BEGIN INT;
  DECLARE V_QUANTITY_END INT;

  DECLARE CONST_USOC_KEY VARCHAR(64) DEFAULT 'usoc';
  DECLARE CONST_LINE_ITEM_CODE_KEY VARCHAR(64) DEFAULT 'line_item_code';
  DECLARE CONST_LINE_ITEM_CODE_DESCRIPTION_KEY VARCHAR(64) DEFAULT 'line_item_code_description';
  DECLARE CONST_USAGE_ITEM_TYPE_KEY VARCHAR(64) DEFAULT 'usage_item_type';
  DECLARE CONST_ITEM_DESCRIPTION_KEY VARCHAR(64) DEFAULT 'item_description';
  DECLARE CONST_BILL_KEEP_BAN_KEY VARCHAR(64) DEFAULT 'bill_keep_ban';

  SELECT
    summary_vendor_name,
    vendor_name,
    usoc,
    usoc_description,
    line_item_code_description,
    line_item_code,
    item_type,
    item_description,
    quantity_begin,
    quantity_end
      INTO
        V_SUMMARY_VENDOR_NAME,
        V_VENDOR_NAME,
        V_USOC,
        V_USOC_DESCRIPTION,
        V_LINE_ITEM_CODE_DESCRIPTION,
        V_LINE_ITEM_CODE,
        V_ITEM_TYPE,
        V_ITEM_DESCRIPTIOIN,
        V_QUANTITY_BEGIN,
        V_QUANTITY_END
  FROM rate_rule_tariff_original
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
      AND audit_reference_type_id = 2
      AND usoc = V_USOC
      AND (
          CASE
            WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
              summary_vendor_name = V_SUMMARY_VENDOR_NAME
            ELSE
              summary_vendor_name IS NULL
          END
        )
      AND (
          CASE
            WHEN V_VENDOR_NAME IS NOT NULL THEN
              vendor_name = V_VENDOR_NAME
            ELSE
              vendor_name IS NULL
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
      AND audit_reference_type_id = 2
      AND line_item_code = V_LINE_ITEM_CODE
      AND (
          CASE
            WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
              summary_vendor_name = V_SUMMARY_VENDOR_NAME
            ELSE
              summary_vendor_name IS NULL
          END
        )
      AND (
          CASE
            WHEN V_VENDOR_NAME IS NOT NULL THEN
              vendor_name = V_VENDOR_NAME
            ELSE
              vendor_name IS NULL
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
      AND audit_reference_type_id = 2
      AND line_item_code_description = V_LINE_ITEM_CODE_DESCRIPTION
      AND (
          CASE
            WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
              summary_vendor_name = V_SUMMARY_VENDOR_NAME
            ELSE
              summary_vendor_name IS NULL
          END
        )
      AND (
          CASE
            WHEN V_VENDOR_NAME IS NOT NULL THEN
              vendor_name = V_VENDOR_NAME
            ELSE
              vendor_name IS NULL
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
      AND audit_reference_type_id = 2
      AND item_description = V_ITEM_DESCRIPTIOIN
      AND (
          CASE
            WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
              summary_vendor_name = V_SUMMARY_VENDOR_NAME
            ELSE
              summary_vendor_name IS NULL
          END
        )
      AND (
          CASE
            WHEN V_VENDOR_NAME IS NOT NULL THEN
              vendor_name = V_VENDOR_NAME
            ELSE
              vendor_name IS NULL
          END
        )
      AND rec_active_flag = 'Y';

  ELSEIF (PARAM_AUDIT_KEY_FIELD = CONST_USAGE_ITEM_TYPE_KEY) THEN

    SELECT 
      COUNT(1), 
      id
        INTO 
          PARAM_MAPPING_ITEM_COUNT,
          PARAM_MAPPING_ITEM_ID
    FROM audit_reference_mapping
    WHERE 1 = 1
      AND audit_reference_type_id = 2
      AND usage_item_type = V_ITEM_TYPE
      AND (
          CASE
            WHEN V_SUMMARY_VENDOR_NAME IS NOT NULL THEN
              summary_vendor_name = V_SUMMARY_VENDOR_NAME
            ELSE
              summary_vendor_name IS NULL
          END
        )
      AND (
          CASE
            WHEN V_VENDOR_NAME IS NOT NULL THEN
              vendor_name = V_VENDOR_NAME
            ELSE
              vendor_name IS NULL
          END
        )
      AND rec_active_flag = 'Y';

  END IF;

END