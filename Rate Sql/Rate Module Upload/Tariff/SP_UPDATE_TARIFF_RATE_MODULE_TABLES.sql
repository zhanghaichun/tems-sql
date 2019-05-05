DROP PROCEDURE IF EXISTS SP_UPDATE_TARIFF_RATE_MODULE_TABLES;
CREATE PROCEDURE SP_UPDATE_TARIFF_RATE_MODULE_TABLES(
  PARAM_SYSTEM_RATE_RULE_ID INT,
  PARAM_BATCH_NO VARCHAR(64)
)

BEGIN
  /**
   * 此 SQL 程序的主要逻辑是：
   * 1. 将 rate_rule_tariff_original 表中更新后的数据同步到 rate module 相关的表中。
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

  DECLARE V_DISOCUNT DOUBLE(20, 5);
  DECLARE V_EXCLUSION_BAN VARCHAR(128);
  DECLARE V_EXCLUSION_ITEM_DESCRIPTION VARCHAR(255);
  DECLARE V_NOTES VARCHAR(500);

  /**
   * Tariff Master 表的相关原始字段
   */
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

  DECLARE V_TARIFF_FILE_ITEM_COUNT INT;

  DECLARE V_RATE_MODE VARCHAR(64);
  DECLARE V_VENDOR_GROUP_ID INT;

  DECLARE V_REFERENCE_TABLE VARCHAR(64);

  DECLARE V_START_DATE DATE;
  DECLARE V_END_DATE DATE;

  DECLARE V_AUDIT_PERIOD_ITEM_COUNT INT;

  DECLARE V_TARIFF_RATE_BY_QUANTITY_ID INT;

  /**
   * audit_reference_mapping 表中的 key_field 字段。
   */
  DECLARE V_MAPPING_KEY_FIELD VARCHAR(64);

  DECLARE V_TARIFF_FILE_ID INT;
  DECLARE V_TARIFF_ID INT;

  DECLARE V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT INT;

  /**
   * 用来标记在更新的时候是否字段有改动。
   */
  DECLARE V_UPDATED_FLAG BOOLEAN DEFAULT FALSE;

  DECLARE V_BAN_ID INT;

  /**
   * 首先更新状态为 '未同步' 状态。
   */
  UPDATE rate_rule_tariff_original
  SET sync_flag = 'N', modified_timestamp = NOW()
  WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

  /**
   * 上传数据
   */
  SELECT
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
  FROM rate_rule_tariff_master_batch
  WHERE batch_no = PARAM_BATCH_NO
    AND rate_id = PARAM_SYSTEM_RATE_RULE_ID;

  /**
   * 主表中的原始数据。
   */
  SELECT
    audit_reference_mapping_id,
    audit_rate_period_id,
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
        V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID,
        V_ORIGIN_AUDIT_RATE_PERIOD_ID,
        V_ORIGIN_CHARGE_TYPE,
        V_ORIGIN_KEY_FIELD,
        V_ORIGIN_RATE_EFFECTIVE_DATE,
        V_ORIGIN_SUMMARY_VENDOR_NAME,
        V_ORIGIN_VENDOR_NAME,
        V_ORIGIN_USOC,
        V_ORIGIN_USOC_DESCRIPTION,
        V_ORIGIN_SUB_PRODUCT,
        V_ORIGIN_LINE_ITEM_CODE_DESCRIPTION,
        V_ORIGIN_LINE_ITEM_CODE,
        V_ORIGIN_ITEM_TYPE,
        V_ORIGIN_ITEM_DESCRIPTIOIN,
        V_ORIGIN_QUANTITY_BEGIN,
        V_ORIGIN_QUANTITY_END,
        V_ORIGIN_TARIFF_FILE_NAME,
        V_ORIGIN_TARIFF_NAME,
        V_ORIGIN_BASE_AMOUNT,
        V_ORIGIN_MULTIPLIER,
        V_ORIGIN_RATE,
        V_ORIGIN_RULES_DETAILS,
        V_ORIGIN_TARIFF_PAGE,
        V_ORIGIN_PART_SECTION,
        V_ORIGIN_ITEM_NUMBER,
        V_ORIGIN_CRTC_NUMBER,
        V_ORIGIN_DISOCUNT,
        V_ORIGIN_EXCUSION_BAN,
        V_ORIGIN_EXCLUSION_ITEM_DESCRIPTION,
        V_ORIGIN_NOTES
  FROM rate_rule_tariff_original
  WHERE id = PARAM_SYSTEM_RATE_RULE_ID
    AND rec_active_flag = 'Y';

  CONTRAST_FIELDS: BEGIN

      IF( IFNULL(V_CHARGE_TYPE, '') != IFNULL(V_ORIGIN_CHARGE_TYPE, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_KEY_FIELD, '') != IFNULL(V_ORIGIN_KEY_FIELD, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_RATE_EFFECTIVE_DATE, '') != IFNULL(V_ORIGIN_RATE_EFFECTIVE_DATE, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_SUMMARY_VENDOR_NAME, '') != IFNULL(V_ORIGIN_SUMMARY_VENDOR_NAME, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_VENDOR_NAME, '') != IFNULL(V_ORIGIN_VENDOR_NAME, '') ) THEN
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

      IF( IFNULL(V_SUB_PRODUCT, '') != IFNULL(V_ORIGIN_SUB_PRODUCT, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_LINE_ITEM_CODE_DESCRIPTION, '') != IFNULL(V_ORIGIN_LINE_ITEM_CODE_DESCRIPTION, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_LINE_ITEM_CODE, '') != IFNULL(V_ORIGIN_LINE_ITEM_CODE, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_ITEM_TYPE, '') != IFNULL(V_ORIGIN_ITEM_TYPE, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_ITEM_DESCRIPTIOIN, '') != IFNULL(V_ORIGIN_ITEM_DESCRIPTIOIN, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_QUANTITY_BEGIN, '') != IFNULL(V_ORIGIN_QUANTITY_BEGIN, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_QUANTITY_END, '') != IFNULL(V_ORIGIN_QUANTITY_END, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_TARIFF_FILE_NAME, '') != IFNULL(V_ORIGIN_TARIFF_FILE_NAME, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_TARIFF_NAME, '') != IFNULL(V_ORIGIN_TARIFF_NAME, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_BASE_AMOUNT, '') != IFNULL(V_ORIGIN_BASE_AMOUNT, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_MULTIPLIER, '') != IFNULL(V_ORIGIN_MULTIPLIER, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_RATE, '') != IFNULL(V_ORIGIN_RATE, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_RULES_DETAILS, '') != IFNULL(V_ORIGIN_RULES_DETAILS, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_TARIFF_PAGE, '') != IFNULL(V_ORIGIN_TARIFF_PAGE, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_PART_SECTION, '') != IFNULL(V_ORIGIN_PART_SECTION, '')  ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_ITEM_NUMBER, '') != IFNULL(V_ORIGIN_ITEM_NUMBER, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_CRTC_NUMBER, '') != IFNULL(V_ORIGIN_CRTC_NUMBER, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_DISOCUNT, '') != IFNULL(V_ORIGIN_DISOCUNT, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_EXCLUSION_BAN, '') != IFNULL(V_ORIGIN_EXCUSION_BAN, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_EXCLUSION_ITEM_DESCRIPTION, '') != IFNULL(V_ORIGIN_EXCLUSION_ITEM_DESCRIPTION, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

      IF( IFNULL(V_NOTES, '') != IFNULL(V_ORIGIN_NOTES, '') ) THEN
        SET V_UPDATED_FLAG = TRUE;
        LEAVE CONTRAST_FIELDS;
      END IF;

  END CONTRAST_FIELDS;

  /**
   * 如果字段有更新， 那么执行更新操作， 如果字段没有更新，
   * 就只修改同步状态即可。 
   */
  IF(V_UPDATED_FLAG = TRUE) THEN

    /**
     * 更新操作
     */
    UPDATE rate_rule_tariff_original
    SET charge_type = V_CHARGE_TYPE,
      key_field = V_KEY_FIELD,
      rate_effective_date = V_RATE_EFFECTIVE_DATE,
      summary_vendor_name = V_SUMMARY_VENDOR_NAME,
      vendor_name = V_VENDOR_NAME,
      usoc = V_USOC,
      usoc_description = V_USOC_DESCRIPTION,
      sub_product = V_SUB_PRODUCT,
      line_item_code_description = V_LINE_ITEM_CODE_DESCRIPTION,
      line_item_code = V_LINE_ITEM_CODE,
      item_type = V_ITEM_TYPE,
      item_description = V_ITEM_DESCRIPTIOIN,
      quantity_begin = V_QUANTITY_BEGIN,
      quantity_end = V_QUANTITY_END,
      tariff_file_name = V_TARIFF_FILE_NAME,
      tariff_name = V_TARIFF_NAME,
      base_amount = V_BASE_AMOUNT,
      multiplier = V_MULTIPLIER,
      rate = V_RATE,
      rules_details = V_RULES_DETAILS,
      tariff_page = V_TARIFF_PAGE,
      part_section = V_PART_SECTION,
      item_number = V_ITEM_NUMBER,
      crtc_number = V_CRTC_NUMBER,
      discount = V_DISOCUNT,
      exclusion_ban = V_EXCLUSION_BAN,
      exclusion_item_description = V_EXCLUSION_ITEM_DESCRIPTION,
      notes = V_NOTES
    WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

    /**
     * 1. 更新 audit_reference_mapping 表
     *   - 先分析的是 rate mode 为 rate 的情况：
     *     - 根据 audit_reference_mapping_id 到 audit_reference_mapping 表中查找对应的 audit_reference_id,
     *       这个 audit_reference_id 的值就是 tariff_id. 将这个值存储起来。
     *     - 更新 audit_reference_mapping 表中对应的字段
     *       
     */
    
    CALL SP_GET_AUDIT_KEY_FIELD_AND_RATE_MODE(
        V_KEY_FIELD,
        'tariff',
        V_MAPPING_KEY_FIELD,
        V_RATE_MODE,
        V_REFERENCE_TABLE
      );
    

    SET V_VENDOR_GROUP_ID = FN_GET_TARIFF_VENDOR_GROUP_ID(PARAM_SYSTEM_RATE_RULE_ID);


    /**
     * 更新 audit_reference_mapping 表
     */
    UPDATE audit_reference_mapping
    SET 
      vendor_group_id = V_VENDOR_GROUP_ID, 
      summary_vendor_name = V_SUMMARY_VENDOR_NAME, 
      vendor_name = V_VENDOR_NAME, 
      key_field = V_MAPPING_KEY_FIELD,
      key_field_original = V_KEY_FIELD, 
      charge_type = V_CHARGE_TYPE, 
      usoc = V_USOC, 
      usoc_description = V_USOC_DESCRIPTION,
      sub_product = V_SUB_PRODUCT, 
      line_item_code = V_LINE_ITEM_CODE, 
      line_item_code_description = V_LINE_ITEM_CODE_DESCRIPTION, 
      usage_item_type = V_ITEM_TYPE, 
      item_description = V_ITEM_DESCRIPTIOIN, 
      modified_timestamp = NOW()
    WHERE id = V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID
      AND rec_active_flag = 'Y';

    SET V_TARIFF_ID = (
        SELECT audit_reference_id
        FROM audit_reference_mapping
        WHERE id = V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID
          AND rec_active_flag = 'Y'
      );

    /**
     * 如果有 mapping exclusion 情况， 那么像 audit_reference_mapping_exclusion 表中插入数据。
     */
    
    /**
     * Ban exclusion
     */
    IF(V_EXCLUSION_BAN IS NOT NULL OR V_EXCLUSION_BAN != '') THEN

      SELECT id INTO V_BAN_ID
      FROM ban
      WHERE account_number = V_EXCLUSION_BAN
        AND rec_active_flag = 'Y'
        AND ban_status_id = 1
        AND master_ban_flag = 'Y'
      LIMIT 1;


      UPDATE audit_reference_mapping_exclusion
      SET ban_id = V_BAN_ID
      WHERE audit_reference_mapping_id = V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID
        AND exclude_key_field = 'ban';

    END IF;

    /**
     * Item description.
     */
    IF(V_EXCLUSION_ITEM_DESCRIPTION IS NOT NULL OR V_EXCLUSION_ITEM_DESCRIPTION != '') THEN

      UPDATE audit_reference_mapping_exclusion
      SET item_description = V_EXCLUSION_ITEM_DESCRIPTION
      WHERE audit_reference_mapping_id = V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID
        AND exclude_key_field = 'item_description';

    END IF;


    /**
     * 2. 更新 tariff_file 表
     *   - 首先查询 tariff_file 表中是否包含当前 tariff file name.
     *     - 如果包含， 将 tariff_file_id 的值更新到
     *       对应的 tariff 表中的记录上。上文已经获取到了 tariff_id
     *     - 如果不包含， 那么向 tariff_file 表中插入一条记录， 并将最新的 
     *       tariff_file_id 返回， 更新到 tariff 表中。
     */
    
    SELECT COUNT(1) INTO V_TARIFF_FILE_ITEM_COUNT
    FROM tariff_file
    WHERE tariff_name = V_TARIFF_FILE_NAME
      AND rec_active_flag = 'Y';

    IF (V_TARIFF_FILE_ITEM_COUNT = 0) THEN

      /**
       * tariff_file 表中没有相应记录。
       */
      INSERT INTO tariff_file(tariff_name, created_timestamp)
      VALUES(V_TARIFF_FILE_NAME, NOW());

      SET V_TARIFF_FILE_ID = ( SELECT MAX(id) FROM tariff_file );

    ELSE

      /**
       * tariff_file 表中有相应记录。
       */
      
      SELECT id INTO V_TARIFF_FILE_ID
      FROM tariff_file
      WHERE tariff_name = V_TARIFF_FILE_NAME
        AND rec_active_flag = 'Y'
      LIMIT 1;

    END IF;
    

    /**
     * 3. 更新 tariff 表
     * TODO: 如果 rate mode 或者是 rate effective date 发生改变，
     *  那么也会影响其他表的更新。
     */
    
    UPDATE tariff
    SET 
      tariff_file_id = V_TARIFF_FILE_ID, 
      name = V_TARIFF_NAME, 
      rate_mode = V_RATE_MODE,
      multiplier = V_MULTIPLIER, 
      discount = V_DISOCUNT,
      page = V_TARIFF_PAGE, 
      part_section = V_PART_SECTION, 
      item_number = V_ITEM_NUMBER, 
      modified_timestamp = NOW()
    WHERE id = V_TARIFF_ID
      AND rec_active_flag = 'Y';



    /**
     * 4. 更新 audit_rate_period 表
     */
    IF(V_REFERENCE_TABLE = 'tariff') THEN

      /**
       * Inactive 数据
       */
      SELECT COUNT(1) INTO V_AUDIT_PERIOD_ITEM_COUNT
      FROM audit_rate_period
      WHERE reference_table = 'tariff'
        AND reference_id = V_TARIFF_ID
        AND end_date IS NOT NULL;

      IF (V_AUDIT_PERIOD_ITEM_COUNT = 0) THEN

        UPDATE audit_rate_period
        SET
          rate = V_RATE,
          start_date = V_RATE_EFFECTIVE_DATE,
          rules_details = V_RULES_DETAILS
        WHERE id = V_ORIGIN_AUDIT_RATE_PERIOD_ID
          AND rec_active_flag = 'Y';

      ELSE

        UPDATE audit_rate_period
        SET
          rate = V_RATE,
          start_date = V_RATE_EFFECTIVE_DATE,
          rules_details = V_RULES_DETAILS
        WHERE id = V_ORIGIN_AUDIT_RATE_PERIOD_ID
          AND rec_active_flag = 'Y';

        SELECT start_date INTO V_START_DATE
        FROM audit_rate_period
        WHERE rec_active_flag = 'Y'
          AND start_date < V_RATE_EFFECTIVE_DATE
          AND reference_table = 'tariff'
          AND reference_id = V_TARIFF_ID
        GROUP BY start_date
        ORDER BY start_date DESC
        LIMIT 1;

        UPDATE audit_rate_period
        SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
        WHERE rec_active_flag = 'Y'
          AND start_date = V_START_DATE
          AND reference_table = 'tariff'
          AND reference_id = V_TARIFF_ID;

      END IF;


    ELSEIF(V_REFERENCE_TABLE = 'tariff_rate_by_quantity') THEN

      -- SELECT COUNT(1) INTO V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT
      -- FROM tariff_rate_by_quantity
      -- WHERE 1 = 1
      --   AND tariff_id = V_TARIFF_ID
      --   AND quantity_begin = V_QUANTITY_BEGIN
      --   AND (quantity_end IS NULL OR quantity_end = V_QUANTITY_END);

      -- IF(V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT = 0) THEN

        --   /**
        --    * 如果更新的 quantity range 在 tariff_rate_by_quantity 表中没有记录， 那么需要执行插入操作。
        --    * 向 tariff_rate_by_quantity 表中插入记录。
        --    */
        --   INSERT INTO tariff_rate_by_quantity(
        --       tariff_id,
        --       quantity_begin,
        --       quantity_end,
        --       rate,
        --       base_amount
        --     )
        --   VALUES(
        --       V_TARIFF_ID,
        --       V_QUANTITY_BEGIN,
        --       V_QUANTITY_END,
        --       V_RATE,
        --       V_BASE_AMOUNT
        --     );

        --   SET V_TARIFF_RATE_BY_QUANTITY_ID = (
        --       SELECT MAX(id) FROM tariff_rate_by_quantity
        --     );

        --   UPDATE audit_rate_period
        --   SET reference_id = V_TARIFF_RATE_BY_QUANTITY_ID
        --   WHERE 1 = 1
        --     AND id = V_ORIGIN_AUDIT_RATE_PERIOD_ID;

      -- ELSE

        /**
         * 更新 tariff_rate_by_quantity 表中数据
         */
        SELECT reference_id INTO V_TARIFF_RATE_BY_QUANTITY_ID
        FROM audit_rate_period
        WHERE id = V_ORIGIN_AUDIT_RATE_PERIOD_ID
          AND rec_active_flag = 'Y';

        UPDATE tariff_rate_by_quantity
        SET
          rate = V_RATE,
          quantity_begin = V_QUANTITY_BEGIN,
          quantity_end = V_QUANTITY_END,
          base_amount = V_BASE_AMOUNT
        WHERE id = V_TARIFF_RATE_BY_QUANTITY_ID;

        SELECT COUNT(1) INTO V_AUDIT_PERIOD_ITEM_COUNT
        FROM audit_rate_period
        WHERE reference_table = 'tariff_rate_by_quantity'
          AND reference_id = V_TARIFF_RATE_BY_QUANTITY_ID
          AND end_date IS NOT NULL;

        IF (V_AUDIT_PERIOD_ITEM_COUNT = 0) THEN

          UPDATE audit_rate_period
          SET
            rate = V_RATE,
            start_date = V_RATE_EFFECTIVE_DATE,
            rules_details = V_RULES_DETAILS
          WHERE id = V_ORIGIN_AUDIT_RATE_PERIOD_ID
            AND rec_active_flag = 'Y';

        ELSE

          UPDATE audit_rate_period
          SET
            rate = V_RATE,
            start_date = V_RATE_EFFECTIVE_DATE,
            rules_details = V_RULES_DETAILS
          WHERE id = V_ORIGIN_AUDIT_RATE_PERIOD_ID
            AND rec_active_flag = 'Y';

          SELECT start_date INTO V_START_DATE
          FROM audit_rate_period
          WHERE rec_active_flag = 'Y'
            AND start_date < V_RATE_EFFECTIVE_DATE
            AND reference_table = 'tariff_rate_by_quantity'
            AND reference_id = V_TARIFF_RATE_BY_QUANTITY_ID
          GROUP BY start_date
          ORDER BY start_date DESC
          LIMIT 1;

          UPDATE audit_rate_period
          SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
          WHERE rec_active_flag = 'Y'
            AND start_date = V_START_DATE
            AND reference_table = 'tariff_rate_by_quantity'
            AND reference_id = V_TARIFF_RATE_BY_QUANTITY_ID;

        END IF;

      -- END IF;
      
    END IF;

    /**
     * 最后更新同步标记。
     */
    UPDATE rate_rule_tariff_original
    SET sync_flag = 'Y'
    WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

  ELSE

    UPDATE rate_rule_tariff_original
    SET sync_flag = 'Y'
    WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

  END IF;

END