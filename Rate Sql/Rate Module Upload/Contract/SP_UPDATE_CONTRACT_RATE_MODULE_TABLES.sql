DROP PROCEDURE IF EXISTS SP_UPDATE_CONTRACT_RATE_MODULE_TABLES;
CREATE PROCEDURE SP_UPDATE_CONTRACT_RATE_MODULE_TABLES(
  PARAM_SYSTEM_RATE_RULE_ID INT,
  PARAM_BATCH_NO VARCHAR(64)
)

BEGIN
  /**
   * 此 SQL 程序的主要逻辑是：
   * 1. 将 rate_rule_contract_original 表中更新后的数据
   * 同步到 rate module 相关的表中。
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

  DECLARE V_CONTRACT_ID INT;

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

  /**
   * audit_reference_mapping 表中的 key_field 字段。
   */
  DECLARE V_MAPPING_KEY_FIELD VARCHAR(64);

  DECLARE V_CONTRACT_FILE_ID INT;
  DECLARE V_TARIFF_ID INT;

  DECLARE V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT INT;
  DECLARE V_CONTRACT_RATE_BY_QUANTITY_ITEM_COUNT INT;

  /**
   * 用来标记在更新的时候是否字段有改动。
   */
  DECLARE V_UPDATED_FLAG BOOLEAN DEFAULT FALSE;

  DECLARE V_BAN_ID INT;

    /**
    * 首先更新状态为 '未同步' 状态。
    */
    UPDATE rate_rule_contract_original
    SET sync_flag = 'N', modified_timestamp = NOW()
    WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

  /**
   * Uploaded data.
   */
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
  FROM rate_rule_contact_master_batch
  WHERE batch_no = PARAM_BATCH_NO
    AND rate_id = PARAM_SYSTEM_RATE_RULE_ID;

  /**
   * Original data inside master table.
   */
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
        V_ORIGIN_RENEWAL_TERM_AFTER_TERM_EXPIRATION,
        V_ORIGIN_EARLY_TERMINATION_FEE,
        V_ORIGIN_ITEM_DESCRIPTIOIN,
        V_ORIGIN_CONTRACT_NAME,
        V_ORIIGIN_CONTRACT_SERVICE_SCHEDULE_NAME,
        V_ORIGIN_LINE_ITEM_CODE,
        V_ORIGIN_LINE_ITEM_CODE_DESCRIPTION,
        V_ORIGIN_TOTAL_VOLUME_BEGIN,
        V_ORIGIN_TOTAL_VOLUME_END,
        V_ORIGIN_MMBC,
        V_ORIGIN_DISOCUNT,
        V_ORIGIN_NOTES
  FROM rate_rule_contract_original
  WHERE id = PARAM_SYSTEM_RATE_RULE_ID
    AND rec_active_flag = 'Y';

    CONTRAST_FIELDS: BEGIN

        -- Contrast fields.
        IF( IFNULL(V_SUMMARY_VENDOR_NAME, '') != IFNULL(V_ORIGIN_SUMMARY_VENDOR_NAME,'') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_CHARGE_TYPE, '') != IFNULL(V_ORIGIN_CHARGE_TYPE,'') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_KEY_FIELD, '') != IFNULL(V_ORIGIN_KEY_FIELD, '') ) THEN
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

        IF( IFNULL(V_SUB_PRODUCT, '') != IFNULL(V_ORIGIN_SUB_PRODUCT, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_RATE, '') != IFNULL(V_ORIGIN_RATE, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_RATE_EFFECTIVE_DATE, '') != IFNULL(V_ORIGIN_RATE_EFFECTIVE_DATE, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_TERM, '') != IFNULL(V_ORIGIN_TERM, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_RENEWAL_TERM_AFTER_TERM_EXPIRATION, '') != IFNULL(V_ORIGIN_RENEWAL_TERM_AFTER_TERM_EXPIRATION, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_EARLY_TERMINATION_FEE, '') != IFNULL(V_ORIGIN_EARLY_TERMINATION_FEE, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_ITEM_DESCRIPTIOIN, '') != IFNULL(V_ORIGIN_ITEM_DESCRIPTIOIN, '')  ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_CONTRACT_NAME, '') != IFNULL(V_ORIGIN_CONTRACT_NAME, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_CONTRACT_SERVICE_SCHEDULE_NAME, '') != IFNULL(V_ORIIGIN_CONTRACT_SERVICE_SCHEDULE_NAME, '') ) THEN
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

        IF( IFNULL(V_TOTAL_VOLUME_BEGIN, '') != IFNULL(V_ORIGIN_TOTAL_VOLUME_BEGIN, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_TOTAL_VOLUME_END, '') != IFNULL(V_ORIGIN_TOTAL_VOLUME_END, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_MMBC, '') != IFNULL(V_ORIGIN_MMBC, '') ) THEN
            SET V_UPDATED_FLAG = TRUE;
            LEAVE CONTRAST_FIELDS;
        END IF;

        IF( IFNULL(V_DISOCUNT, '') != IFNULL(V_ORIGIN_DISOCUNT, '') ) THEN
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
        UPDATE rate_rule_contract_original
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
          term_months = V_TERM,
          renewal_term_after_term_expiration = V_RENEWAL_TERM_AFTER_TERM_EXPIRATION,
          early_termination_fee = V_EARLY_TERMINATION_FEE,
          item_description = V_ITEM_DESCRIPTIOIN,
          contract_name = V_CONTRACT_NAME,
          contract_service_schedule_name = V_CONTRACT_SERVICE_SCHEDULE_NAME,
          line_item_code = V_LINE_ITEM_CODE,
          line_item_code_description = V_LINE_ITEM_CODE_DESCRIPTION,
          total_volume_begin = V_TOTAL_VOLUME_BEGIN,
          total_volume_end = V_TOTAL_VOLUME_END,
          mmbc = V_MMBC,
          discount = V_DISOCUNT,
          notes = V_NOTES
        WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

        CALL SP_GET_AUDIT_KEY_FIELD_AND_RATE_MODE(
            V_KEY_FIELD,
            'contract',
            V_MAPPING_KEY_FIELD,
            V_RATE_MODE,
            V_REFERENCE_TABLE
          );

        SET V_VENDOR_GROUP_ID = FN_GET_CONTRACT_VENDOR_GROUP_ID(PARAM_SYSTEM_RATE_RULE_ID);

        /**
         * 更新 audit_reference_mapping 表
         */
        UPDATE audit_reference_mapping
        SET 
          vendor_group_id = V_VENDOR_GROUP_ID, 
          summary_vendor_name = V_SUMMARY_VENDOR_NAME, 
          key_field = V_MAPPING_KEY_FIELD,
          key_field_original = V_KEY_FIELD, 
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

        SET V_CONTRACT_ID = (
            SELECT audit_reference_id
            FROM audit_reference_mapping
            WHERE id = V_ORIGIN_AUDIT_REFERENCE_MAPPING_ID
              AND rec_active_flag = 'Y'
          );


        /**
         * 2. 更新 contract_file 表
         */

        SELECT COUNT(1) INTO V_CONTRACT_FILE_ITEM_COUNT
        FROM contract_file
        WHERE contract_number = V_TARIFF_FILE_NAME
          AND effective_date = V_RATE_EFFECTIVE_DATE
          AND rec_active_flag = 'Y';

        IF (V_CONTRACT_FILE_ITEM_COUNT = 0) THEN

          /**
           * contract_file 表中没有相应记录。
           */
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

          /**
           * 如果 contract_file 表中有相应记录。
           */
          
          SELECT id INTO V_CONTRACT_FILE_ID
          FROM contract_file
          WHERE contract_number = V_CONTRACT_NAME
            AND effective_date = V_RATE_EFFECTIVE_DATE
            AND rec_active_flag = 'Y';

        END IF;


    /**
     * 3. 更新 contract 表。
     */

    UPDATE contract
    SET 
      contract_file_id = V_CONTRACT_FILE_ID, 
      name = V_CONTRACT_NAME,
      schedule = V_CONTRACT_SERVICE_SCHEDULE_NAME,
      mmbc = V_MMBC,
      discount = V_DISOCUNT,
      rate_mode = V_RATE_MODE, 
      modified_timestamp = NOW()
    WHERE id = V_CONTRACT_ID
      AND rec_active_flag = 'Y';

    /**
     * 4. 更新 audit_rate_period 表
     */
    IF(V_REFERENCE_TABLE = 'contract') THEN

      SELECT COUNT(1) INTO V_AUDIT_PERIOD_ITEM_COUNT
      FROM audit_rate_period
      WHERE reference_table = 'contract'
        AND reference_id = V_CONTRACT_ID
        AND end_date IS NOT NULL; -- Either Rate 类型的数据可能一个 date 对应多条记录。

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

        SELECT start_date INTO V_START_DATE
        FROM audit_rate_period
        WHERE rec_active_flag = 'Y'
          AND start_date < V_RATE_EFFECTIVE_DATE
          AND reference_table = 'contract'
          AND reference_id = V_CONTRACT_ID
        GROUP BY start_date
        ORDER BY start_date DESC
        LIMIT 1;

        UPDATE audit_rate_period
        SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
        WHERE rec_active_flag = 'Y'
          AND start_date = V_START_DATE
          AND reference_table = 'contract'
          AND reference_id = V_CONTRACT_ID;

      END IF;

    ELSEIF(V_REFERENCE_TABLE = 'contract_rate_by_quantity') THEN

      -- SELECT COUNT(1) INTO V_CONTRACT_RATE_BY_QUANTITY_ITEM_COUNT
      -- FROM contract_rate_by_quantity
      -- WHERE 1 = 1
      --   AND contract_id = V_CONTRACT_ID
      --   AND quantity_begin = V_TOTAL_VOLUME_BEGIN
        -- AND (quantity_end IS NULL OR quantity_end = V_TOTAL_VOLUME_END);

      -- IF(V_CONTRACT_RATE_BY_QUANTITY_ITEM_COUNT = 0) THEN

        -- INSERT INTO contract_rate_by_quantity(
        --     contract_id,
        --     quantity_begin,
        --     quantity_end,
        --     rate
        --   )
        -- VALUES(
        --     V_CONTRACT_ID,
        --     V_TOTAL_VOLUME_BEGIN,
        --     V_TOTAL_VOLUME_END,
        --     V_RATE
        --   );

        -- SET V_CONTRACT_RATE_BY_QUANTITY_ID = (
        --     SELECT MAX(id) FROM contract_rate_by_quantity
        --   );

        -- UPDATE audit_rate_period
        -- SET reference_id = V_CONTRACT_RATE_BY_QUANTITY_ID
        -- WHERE 1 = 1
        --   AND id = V_ORIGIN_AUDIT_RATE_PERIOD_ID;

      -- ELSE

        /**
         * 更新 contract_rate_by_quantity 表中数据
         */
        SELECT reference_id INTO V_CONTRACT_RATE_BY_QUANTITY_ID
        FROM audit_rate_period
        WHERE id = V_ORIGIN_AUDIT_RATE_PERIOD_ID
          AND rec_active_flag = 'Y';

        UPDATE contract_rate_by_quantity
        SET
          rate = V_RATE,
          quantity_begin = V_TOTAL_VOLUME_BEGIN,
          quantity_end = V_TOTAL_VOLUME_END
        WHERE id = V_CONTRACT_RATE_BY_QUANTITY_ID;

        SELECT COUNT(1) INTO V_AUDIT_PERIOD_ITEM_COUNT
        FROM audit_rate_period
        WHERE reference_table = 'contract_rate_by_quantity'
          AND reference_id = V_CONTRACT_RATE_BY_QUANTITY_ID
          AND end_date IS NOT NULL; -- Either Rate 类型的数据可能一个 date 对应多条记录。

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

          SELECT start_date INTO V_START_DATE
          FROM audit_rate_period
          WHERE rec_active_flag = 'Y'
            AND start_date < V_RATE_EFFECTIVE_DATE
            AND reference_table = 'contract_rate_by_quantity'
            AND reference_id = V_CONTRACT_RATE_BY_QUANTITY_ID
          GROUP BY start_date
          ORDER BY start_date DESC
          LIMIT 1;

          UPDATE audit_rate_period
          SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
          WHERE rec_active_flag = 'Y'
            AND start_date = V_START_DATE
            AND reference_table = 'contract_rate_by_quantity'
            AND reference_id = V_CONTRACT_RATE_BY_QUANTITY_ID;

        END IF;

      -- END IF;
      
    END IF;

    /**
     * 最后更新同步标记。
     */
    UPDATE rate_rule_contract_original
    SET sync_flag = 'Y'
    WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

    ELSE

    UPDATE rate_rule_contract_original
    SET sync_flag = 'Y'
    WHERE id = PARAM_SYSTEM_RATE_RULE_ID;

    END IF;
END