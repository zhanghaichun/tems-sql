DROP PROCEDURE IF EXISTS SP_UPDATE_TARIFF_MASTER_DATA_TO_RATE_MODULE_TABLES;
CREATE PROCEDURE SP_UPDATE_TARIFF_MASTER_DATA_TO_RATE_MODULE_TABLES(PARAM_BATCH_NO VARCHAR(64))

BEGIN
  /**
   * 通过临时表中的 audit_reference_mapping_id 和 audit_rate_period_id 来对 rate module
   * 相关表进行更新。
   *
   * 临时表是 rate_rule_tariff_master_batch
   */
  
  /**
   * 临时表中的相关字段
   */
  DECLARE V_AUDIT_REFERENCE_MAPPING_ID INT;
  DECLARE V_AUDIT_RATE_PERIOD_ID INT;
  DECLARE V_SYSTEM_RULE_ID INT;
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

  -- BILL_KEEP FIELDS
  DECLARE V_BILL_KEEP_BAN VARCHAR(64);
  DECLARE V_BILL_KEEP_BAN_ID INT;
  DECLARE V_PROVINCE VARCHAR(32);
  DECLARE V_PROVIDER VARCHAR(32);
  DECLARE V_IMBALANCE_START DOUBLE(20, 5);
  DECLARE V_IMBALANCE_END DOUBLE(20, 5);


  DECLARE V_TARIFF_FILE_NAME VARCHAR(64);
  
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

  -- BILL_KEEP FIELDS
  DECLARE V_ORIGINAL_BILL_KEEP_BAN VARCHAR(64);
  DECLARE V_ORIGINAL_BILL_KEEP_BAN_ID INT;
  DECLARE V_ORIGINAL_PROVINCE VARCHAR(32);
  DECLARE V_ORIGINAL_PROVIDER VARCHAR(32);
  DECLARE V_ORIGINAL_IMBALANCE_START DOUBLE(20, 5);
  DECLARE V_ORIGINAL_IMBALANCE_END DOUBLE(20, 5);

  /**
   * 用来标记在插入的时候是否， 和表中的数据重复。
   */
  DECLARE V_INSERTED_DUPLICATED_FLAG BOOLEAN DEFAULT TRUE;

  DECLARE V_ORIGIN_ITEM_COUNT INT;


  /**
   * 目前有两种 loading 模式， 更新 或者 插入。
   */
  DECLARE V_LOADING_MODE VARCHAR(12);

  DECLARE V_UPDATE_LOADING_MODE VARCHAR(12) DEFAULT 'UPADTE';
  DECLARE V_INSERT_LOADING_MODE VARCHAR(12) DEFAULT 'INSERT';
  
  DECLARE V_CURSOR_DONE_FLAG BOOLEAN DEFAULT FALSE;

  -- 勇哥还没有在 rate_rule_tariff_master_batch 中加 imbalance_start,
  -- imbalance_end 字段。
  DECLARE V_TARIFF_MASTER_DATA_CURSOR CURSOR FOR
    SELECT
      TRIM( rate_id ),
      TRIM( charge_type ),
      TRIM( key_field ),
      TRIM( rate_effective_date ),
      TRIM( summary_vendor_name ),
      TRIM( vendor_name ),
      TRIM( usoc ),
      TRIM( usoc_description ),
      TRIM( sub_product ),
      TRIM( line_item_code_description ),
      TRIM( line_item_code ),
      TRIM( item_type ),
      TRIM( item_description ),
      TRIM( quantity_begin ),
      TRIM( quantity_end ),
      TRIM( tariff_file_name ),
      TRIM( tariff_name ),
      TRIM( base_amount ),
      TRIM( multiplier ),
      TRIM( rate ),
      TRIM( rules_details ),
      TRIM( tariff_page ),
      TRIM( part_section ),
      TRIM( item_number ),
      TRIM( crtc_number ),
      TRIM( discount ),
      TRIM( exclusion_ban ),
      TRIM( exclusion_item_description ),
      TRIM( bill_keep_ban_id ),
      TRIM( bill_keep_ban ),
      TRIM( province ),
      TRIM( provider ),
      TRIM( imbalance_start ),
      TRIM( imbalance_end ),
      TRIM( notes )
    FROM rate_rule_tariff_master_batch
    WHERE batch_no = PARAM_BATCH_NO;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_CURSOR_DONE_FLAG = TRUE;

  /**
   * 打开游标
   */
  OPEN V_TARIFF_MASTER_DATA_CURSOR;

    LABEL1:
    WHILE NOT V_CURSOR_DONE_FLAG
    DO 
      FETCH V_TARIFF_MASTER_DATA_CURSOR 
        INTO
          V_SYSTEM_RULE_ID,
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
          V_EXCUSION_BAN,
          V_EXCLUSION_ITEM_DESCRIPTION,
          V_BILL_KEEP_BAN_ID,
          V_BILL_KEEP_BAN,
          V_PROVINCE,
          V_PROVIDER,
          V_IMBALANCE_START,
          V_IMBALANCE_END,
          V_NOTES;

      IF (V_CURSOR_DONE_FLAG) THEN
        LEAVE LABEL1;
      END IF;

      /**
       * 根据 rate id, 判断当前数据的处理模式。
       * 目前有两种模式： 插入模式 (inserted), 更新模式 (updated)
       */
      SET V_SYSTEM_RULE_ID = TRIM(V_SYSTEM_RULE_ID);

      IF ( V_SYSTEM_RULE_ID IS NULL OR V_SYSTEM_RULE_ID = '') THEN

        SET V_LOADING_MODE = V_INSERT_LOADING_MODE;

      ELSE
        SET V_LOADING_MODE = V_UPDATE_LOADING_MODE;
      END IF;

      IF (V_LOADING_MODE = V_UPDATE_LOADING_MODE) THEN
        /**
         * Updated 模式
         */
              
        CALL SP_UPDATE_TARIFF_RATE_MODULE_TABLES(V_SYSTEM_RULE_ID, PARAM_BATCH_NO);

      ELSEIF (V_LOADING_MODE = V_INSERT_LOADING_MODE) THEN
        -- Insert mode.
        
        INSERT INTO rate_rule_tariff_original(
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
            bill_keep_ban,
            bill_keep_ban_id,
            province,
            provider,
            imbalance_start,
            imbalance_end,
            notes,
            sync_flag,
            created_timestamp
          )
        VALUES(
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
            V_EXCUSION_BAN,
            V_EXCLUSION_ITEM_DESCRIPTION,
            V_BILL_KEEP_BAN,
            V_BILL_KEEP_BAN_ID,
            V_PROVINCE,
            V_PROVIDER,
            V_IMBALANCE_START,
            V_IMBALANCE_END,
            V_NOTES,
            'N',
            NOW()
          );

        /**
         * 向 rate module 相关表中更新。
         */
        CALL SP_INSERT_INTO_TARIFF_RATE_MODULE_TABLES();

      END IF;

    END WHILE LABEL1;

  /**
   * 关闭游标
   */
  CLOSE V_TARIFF_MASTER_DATA_CURSOR;

  /**
   * 更新 rate_status.
   */
  CALL SP_UPDATE_AUDIT_RATE_STATUS();

  /**
   * 处理完数据之后，执行删除操作。
   */
  -- DELETE FROM rate_rule_tariff_master_batch WHERE batch_no = PARAM_BATCH_NO;
  

END