DROP PROCEDURE IF EXISTS SP_INSERT_INTO_MTM_RATE_MODULE_TABLES;
CREATE PROCEDURE SP_INSERT_INTO_MTM_RATE_MODULE_TABLES()

BEGIN

  /**
   * 此 SQL 程序的主要逻辑是：
   * 1. 将 rate_rule_mtm_original 表中新插入的数据同步到 rate module 相关的表中。
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

  /**
   * audit_reference_mapping 表中的 key_field 字段。
   */
  DECLARE V_MAPPING_KEY_FIELD VARCHAR(64);
  DECLARE V_REFERENCE_TABLE VARCHAR(64);

  DECLARE V_TARIFF_FILE_ID INT;
  DECLARE V_CONTRACT_FILE_ID INT;
  DECLARE V_TARIFF_ID INT;
  DECLARE V_AUDIT_MTM_ID INT;

  DECLARE V_START_DATE DATE;

  DECLARE V_TARIFF_FILE_ITEM_COUNT INT;
  DECLARE V_CONTRACT_FILE_ITEM_COUNT INT;
  DECLARE V_TARIFF_ITEM_COUNT INT;
  DECLARE V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT INT;
  DECLARE V_AUDIT_RATE_PERIOD_ITEM_COUNT INT;
  DECLARE V_TARIFF_RATE_BY_QUANTITY_ITEM_COUNT INT;
  DECLARE V_CONTRACT_RATE_BY_QUANTITY_ITEM_COUNT INT;

  DECLARE V_AUDIT_RATE_PERIOD_RATE_ANY_ITEM_COUNT INT;

  /**
   * 还没有更新到 rate module 相关表的记录数。
   */
  DECLARE V_NOT_UPDATE_RECORD_COUNT INT;

  DECLARE V_BAN_ID INT;

  SELECT COUNT(1) INTO V_NOT_UPDATE_RECORD_COUNT
  FROM rate_rule_mtm_original
  WHERE sync_flag = 'N';

  IF ( V_NOT_UPDATE_RECORD_COUNT > 0 ) THEN

    /**
     * 查询更新时相关的字段。
     */
    SELECT
      id,
      summary_vendor_name,
      charge_type,
      key_field,
      usoc,
      usoc_description,
      stripped_circuit_number, -- +
      sub_product,
      rate,
      rate_effective_date,
      term, -- +
      item_description,
      line_item_code,
      line_item_code_description
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
          V_ITEM_DESCRIPTIOIN,
          V_LINE_ITEM_CODE,
          V_LINE_ITEM_CODE_DESCRIPTION
    FROM rate_rule_mtm_original
    WHERE sync_flag = 'N'
    ORDER BY id desc
    LIMIT 1;

    /**
     * 获取 rate mode 和 mapping key field.
     *
     * 获取在系统中自定义的 key field.
     */

    CALL SP_GET_AUDIT_KEY_FIELD_AND_RATE_MODE(
        V_KEY_FIELD,
        'mtm',
        V_MAPPING_KEY_FIELD,
        V_RATE_MODE,
        V_REFERENCE_TABLE
      );
    
    /**
     * 查询 audit_reference_mapping 表中是否有满足当前 key_field 的记录。
     */
    CALL SP_GET_MTM_MAPPING_RECORD_ID(
        V_MAPPING_KEY_FIELD,
        V_TABLE_ID,
        V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT,
        V_AUDIT_REFERENCE_MAPPING_ID
      );
    

    IF(V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT = 0) THEN
      /**
       * 需要插入 mapping 数据。
       */

      /**
       * 2. 向 audit_mtm 表中插入相关 field value.
       */
      INSERT INTO audit_mtm (
          charge_type,
          summary_vendor_name,
          key_field,
          usoc,
          usoc_long_description,
          sub_product,
          rate,
          rate_mode,
          effective_date,
          term,
          item_description,
          line_item_code,
          line_item_code_description,
          source,
          created_timestamp
        )
      VALUES (
          V_CHARGE_TYPE,
          V_SUMMARY_VENDOR_NAME,
          V_KEY_FIELD,
          V_USOC,
          V_USOC_DESCRIPTION,
          V_SUB_PRODUCT,
          V_RATE,
          V_RATE_MODE,
          V_RATE_EFFECTIVE_DATE,
          V_TERM,
          V_ITEM_DESCRIPTIOIN,
          V_LINE_ITEM_CODE,
          V_LINE_ITEM_CODE_DESCRIPTION,
          'Rogers',
          NOW()
        );

      SET V_AUDIT_MTM_ID = ( SELECT MAX(id) FROM audit_mtm );

      SET V_VENDOR_GROUP_ID = FN_GET_MTM_VENDOR_GROUP_ID(V_TABLE_ID);
      
      /**
       * 3. 向 audit_reference_mapping 表中插入记录
       */
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
          18,
          V_AUDIT_MTM_ID,
          NOW()
        );

      SET V_AUDIT_REFERENCE_MAPPING_ID =  ( SELECT MAX(id) FROM audit_reference_mapping );

      /**
       * 更新主表中的 audit_reference_mapping_id
       */
      UPDATE rate_rule_mtm_original
      SET audit_reference_mapping_id = V_AUDIT_REFERENCE_MAPPING_ID
      WHERE id = V_TABLE_ID;

    ELSE

      /**
       * 更新主表中的 audit_reference_mapping_id
       */
      UPDATE rate_rule_mtm_original
      SET audit_reference_mapping_id = V_AUDIT_REFERENCE_MAPPING_ID
      WHERE id = V_TABLE_ID;

      SET V_AUDIT_MTM_ID = (
          SELECT audit_reference_id
          FROM audit_reference_mapping
          WHERE id = V_AUDIT_REFERENCE_MAPPING_ID
        );

    END IF; -- V_AUDIT_REFERENCE_MAPPING_ITEM_COUNT

    /**
     * 4. 向 audit_rate_period 表中插入数据。
     */
    IF(V_REFERENCE_TABLE = 'audit_mtm') THEN

      SELECT COUNT(1) INTO V_AUDIT_RATE_PERIOD_ITEM_COUNT
      FROM audit_rate_period
      WHERE 1 = 1
        AND reference_table = 'audit_mtm'
        AND reference_id = V_AUDIT_MTM_ID
        AND end_date IS NULL
        AND rec_active_flag = 'Y';

      IF ( V_AUDIT_RATE_PERIOD_ITEM_COUNT = 0) THEN
        /**
         * 如果在 audit_rate_period 表中没有符合相应条件的记录
         */
        
        INSERT INTO audit_rate_period(
            reference_table, 
            reference_id,
            start_date,
            end_date,
            rate
          )
        VALUES(
            'audit_mtm',
            V_AUDIT_MTM_ID,
            V_RATE_EFFECTIVE_DATE,
            NULL,
            V_RATE
          );

        SET V_AUDIT_RATE_PERIOD_ID = (
            SELECT MAX(id) FROM audit_rate_period
          );

        UPDATE rate_rule_mtm_original
        SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
        WHERE id = V_TABLE_ID
          AND rec_active_flag = 'Y';

      ELSE
        /**
         * 可以在 audit_rate_period 找到符合条件的 contract 记录。
         */
        
        SELECT start_date INTO V_START_DATE
        FROM audit_rate_period
        WHERE reference_table = 'audit_mtm'
          AND reference_id = V_AUDIT_MTM_ID
          AND end_date IS NULL
          AND rec_active_flag = 'Y'
        LIMIT 1;

        IF (V_RATE_EFFECTIVE_DATE > V_START_DATE) THEN

          /**
           * 先更新 end_date
           */
          UPDATE audit_rate_period
          SET end_date = DATE_SUB(V_RATE_EFFECTIVE_DATE, INTERVAL 1 DAY)
          WHERE reference_table = 'audit_mtm'
            AND reference_id = V_AUDIT_MTM_ID
            AND end_date IS NULL
            AND rec_active_flag = 'Y';

          /**
           * 再插入最新的一条记录。
           */
          INSERT INTO audit_rate_period(
              reference_table, 
              reference_id,
              start_date,
              end_date,
              rate
            )
          VALUES(
              'audit_mtm',
              V_AUDIT_MTM_ID,
              V_RATE_EFFECTIVE_DATE,
              NULL,
              V_RATE
            );

          SET V_AUDIT_RATE_PERIOD_ID = (
              SELECT MAX(id) FROM audit_rate_period
            );

          UPDATE rate_rule_mtm_original
          SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
          WHERE id = V_TABLE_ID;

        ELSEIF (V_RATE_EFFECTIVE_DATE < V_START_DATE) THEN


          SELECT start_date INTO V_START_DATE
          FROM audit_rate_period
          WHERE reference_table = 'audit_mtm'
            AND reference_id = V_AUDIT_MTM_ID
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
              'audit_mtm',
              V_AUDIT_MTM_ID,
              V_RATE_EFFECTIVE_DATE,
              DATE_SUB(V_START_DATE, INTERVAL 1 DAY),
              V_RATE
            );

          SET V_AUDIT_RATE_PERIOD_ID = (
              SELECT MAX(id) FROM audit_rate_period
            );

          UPDATE rate_rule_mtm_original
          SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
          WHERE id = V_TABLE_ID;

        ELSE

          SELECT id INTO V_AUDIT_RATE_PERIOD_ID
          FROM audit_rate_period
          WHERE reference_table = 'audit_mtm'
            AND reference_id = V_AUDIT_MTM_ID
            AND end_date IS NULL
            AND rec_active_flag = 'Y'
          LIMIT 1;

          UPDATE rate_rule_mtm_original
          SET audit_rate_period_id = V_AUDIT_RATE_PERIOD_ID
          WHERE id = V_TABLE_ID;


        END IF;
        
      END IF;

    
    END IF;

    /**
     * 更新同步标记
     */
    UPDATE rate_rule_mtm_original
    SET sync_flag = 'Y'
    WHERE id = V_TABLE_ID;

  END IF; -- Not upload count.

END