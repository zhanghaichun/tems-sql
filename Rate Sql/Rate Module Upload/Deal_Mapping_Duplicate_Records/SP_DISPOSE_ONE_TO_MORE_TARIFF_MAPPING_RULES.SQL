DROP PROCEDURE IF EXISTS SP_DISPOSE_ONE_TO_MORE_TARIFF_MAPPING_RULES;
CREATE PROCEDURE SP_DISPOSE_ONE_TO_MORE_TARIFF_MAPPING_RULES()

BEGIN
  /**
   * 将 mapping 表中多条数据对应同一个 tariff 的数据拆分成多条对应关系
   */
  
  DECLARE V_AUDIT_REFERENCE_ID INT;
  DECLARE V_MAPPING_RATE_MODE VARCHAR(64); -- 在条件判断的时候使用

  DECLARE V_TOLERANCE_RATE DOUBLE(20, 5);

  DECLARE V_TARIFF_FILE_ID INT;
  DECLARE V_TARIFF_NAME VARCHAR(500);
  DECLARE V_RATE_MODE VARCHAR(64);
  DECLARE V_TARIFF_PAGE VARCHAR(32);
  DECLARE V_PART_SECTION VARCHAR(32);
  DECLARE V_ITEM_NUMBER VARCHAR(32);
  DECLARE V_SOURCE VARCHAR(16);

  DECLARE V_MIN_MAPPING_ID INT;
  DECLARE V_AUDIT_REFERENCE_MAPPING_ID INT;

  DECLARE V_REFERENCE_TABLE VARCHAR(64);
  DECLARE V_REFERENCE_ID INT;
  DECLARE V_START_DATE DATE;
  DECLARE V_END_DATE DATE;
  DECLARE V_RATE DOUBLE(20,5);
  DECLARE V_RULES_DETAILS VARCHAR(500);

  DECLARE V_TARIFF_ID INT;

  DECLARE V_QUANTITY_BEGIN INT;
  DECLARE V_QUANTITY_END INT;
  DECLARE V_BASE_AMOUNT INT;

  DECLARE V_TARIFF_RATE_BY_QUANTITY_ID INT;
  
  DECLARE V_DONE BOOLEAN DEFAULT FALSE;

  /**
   * 查询所有 tariff mapping 的数据
   */
  DECLARE V_MAPPING_RECORDS_CURSOR CURSOR FOR 
    SELECT arm.audit_reference_id, t.rate_mode FROM audit_reference_mapping arm 
    LEFT JOIN tariff t ON arm.audit_reference_id = t.id
    WHERE arm.rec_active_flag = 'Y'
      AND t.rec_active_flag = 'Y'
      AND t.rate_mode IN (
          'rate', 
          'rate_any',
          'tariff_rate_by_quantity',
          'tariff_rate_by_quantity_rate_max',
          'tariff_rate_by_quantity_base_amount'
        )
      AND arm.audit_reference_type_id = 2
    GROUP BY arm.audit_reference_id 
    HAVING COUNT(*) > 1
    ORDER BY arm.audit_reference_id;

  /**
   * 查询 audit_rate_period 表中的数据
   */
  DECLARE V_RATE_PERIOD_RECORDS_CURSOR CURSOR FOR
    SELECT 
      reference_table, 
      reference_id, 
      start_date, 
      end_date, 
      rate, 
      rules_details
    FROM audit_rate_period
    WHERE rec_active_flag = 'Y'
      AND (
          CASE 
            WHEN V_MAPPING_RATE_MODE IN (
                'tariff_rate_by_quantity',
                'tariff_rate_by_quantity_base_amount',
                'tariff_rate_by_quantity_rate_max'
              ) THEN

              reference_table = 'tariff_rate_by_quantity'
              AND reference_id = V_TARIFF_RATE_BY_QUANTITY_ID
            ELSE
              reference_table = 'tariff'
              AND reference_id = V_AUDIT_REFERENCE_ID
            END
        )
    ORDER BY reference_id;

  /**
   * 查询某一条 tariff 对应的 mapping records.
   */
  DECLARE V_CERTAIN_MAPPING_RECORDS_CURSOR CURSOR FOR 
    SELECT arm.id FROM audit_reference_mapping arm 
    WHERE arm.rec_active_flag = 'Y'
      AND arm.audit_reference_type_id = 2
      AND arm.audit_reference_id = V_AUDIT_REFERENCE_ID
      AND arm.id != V_MIN_MAPPING_ID;

  DECLARE V_TARIFF_RATE_BY_QUANTITY_MAPPING_RECORD_CURSOR CURSOR FOR 
    SELECT
      trbq.id,
      trbq.quantity_begin,
      trbq.quantity_end,
      trbq.base_amount 
    FROM tariff_rate_by_quantity trbq
    WHERE 1 = 1
      AND trbq.tariff_id = V_AUDIT_REFERENCE_ID
    ORDER BY trbq.id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_DONE = TRUE;

  OPEN V_MAPPING_RECORDS_CURSOR;

    LABEL1:
    WHILE NOT V_DONE DO 

      FETCH V_MAPPING_RECORDS_CURSOR 
        INTO V_AUDIT_REFERENCE_ID, V_MAPPING_RATE_MODE;

      IF (V_DONE) THEN
        LEAVE LABEL1;
      END IF;
      
      -- 查询 tariff 表中相关数据。
      SELECT 
        tariff_file_id, 
        name, 
        rate_mode, 
        page, 
        part_section,  
        item_number, 
        source,
        tolerance_rate
          INTO
            V_TARIFF_FILE_ID,
            V_TARIFF_NAME,
            V_RATE_MODE,
            V_TARIFF_PAGE,
            V_PART_SECTION,
            V_ITEM_NUMBER,
            V_SOURCE,
            V_TOLERANCE_RATE
      FROM tariff
      WHERE rec_active_flag = 'Y'
        AND id = V_AUDIT_REFERENCE_ID;

      SELECT MIN(id) INTO V_MIN_MAPPING_ID
      FROM audit_reference_mapping
      WHERE rec_active_flag = 'Y'
        AND audit_reference_type_id = 2
        AND audit_reference_id = V_AUDIT_REFERENCE_ID;

      /**
       * 嵌套游标 开启 (循环某一个 audit_reference_id 对应的多条 audit_reference_mapping 记录)
       */
      OPEN V_CERTAIN_MAPPING_RECORDS_CURSOR;

        readLoop: LOOP
          FETCH V_CERTAIN_MAPPING_RECORDS_CURSOR
            INTO 
              V_AUDIT_REFERENCE_MAPPING_ID;

          IF (V_DONE) THEN
            LEAVE readLoop;
          END IF;

          INSERT INTO tariff(
            tariff_file_id, 
            name, 
            rate_mode, 
            page, 
            part_section,  
            item_number, 
            source,
            tolerance_rate,
            created_timestamp
          )
          VALUES(
            V_TARIFF_FILE_ID, 
            V_TARIFF_NAME, 
            V_RATE_MODE, 
            V_TARIFF_PAGE, 
            V_PART_SECTION, 
            V_ITEM_NUMBER, 
            'Rogers', 
            V_TOLERANCE_RATE,
            NOW() 
          );

          SET V_TARIFF_ID = (
              SELECT MAX(id) FROM tariff
            );

          UPDATE audit_reference_mapping
          SET audit_reference_id = V_TARIFF_ID
          WHERE id = V_AUDIT_REFERENCE_MAPPING_ID;

          IF ( V_MAPPING_RATE_MODE IN (
              'tariff_rate_by_quantity',
              'tariff_rate_by_quantity_base_amount',
              'tariff_rate_by_quantity_rate_max'
            ) ) THEN

              /**
               * 嵌套游标 开启 (循环 audit_reference_id 在 tariff_rate_by_quantity 表中对应的多条记录。)
               */
              OPEN V_TARIFF_RATE_BY_QUANTITY_MAPPING_RECORD_CURSOR;

                readLoop3: LOOP
                  FETCH V_TARIFF_RATE_BY_QUANTITY_MAPPING_RECORD_CURSOR
                    INTO
                      V_TARIFF_RATE_BY_QUANTITY_ID,
                      V_QUANTITY_BEGIN,
                      V_QUANTITY_END,
                      V_BASE_AMOUNT;

                  IF (V_DONE) THEN
                    LEAVE readLoop3;
                  END IF;

                  INSERT INTO tariff_rate_by_quantity(
                      tariff_id, 
                      quantity_begin, 
                      quantity_end,
                      base_amount
                    )
                  VALUES(
                      V_TARIFF_ID,
                      V_QUANTITY_BEGIN,
                      V_QUANTITY_END,
                      V_BASE_AMOUNT
                    );

                  /**
                   * 嵌套游标 开启 (循环 audit_reference_id 在 audit_rate_period 表中对应的多条记录。)
                   */
                  OPEN V_RATE_PERIOD_RECORDS_CURSOR;

                    readLoop2: LOOP
                      FETCH V_RATE_PERIOD_RECORDS_CURSOR
                        INTO 
                          V_REFERENCE_TABLE,
                          V_REFERENCE_ID,
                          V_START_DATE,
                          V_END_DATE,
                          V_RATE,
                          V_RULES_DETAILS;

                      IF (V_DONE) THEN
                        LEAVE readLoop2;
                      END IF;

                      SET V_TARIFF_RATE_BY_QUANTITY_ID = (SELECT MAX(id) FROM tariff_rate_by_quantity);

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
                        V_START_DATE,
                        V_END_DATE,
                        V_RATE,
                        V_RULES_DETAILS
                      );

                    END LOOP;

                  CLOSE V_RATE_PERIOD_RECORDS_CURSOR; -- 嵌套游标 结束

                  SET V_DONE = FALSE;

                END LOOP;

              CLOSE V_TARIFF_RATE_BY_QUANTITY_MAPPING_RECORD_CURSOR; -- 嵌套游标 结束

              SET V_DONE = FALSE;

          ELSE


            /**
             * 嵌套游标 开启 (循环 audit_reference_id 在 audit_rate_period 表中对应的多条记录。)
             */
            OPEN V_RATE_PERIOD_RECORDS_CURSOR;

              readLoop2: LOOP
                FETCH V_RATE_PERIOD_RECORDS_CURSOR
                  INTO 
                    V_REFERENCE_TABLE,
                    V_REFERENCE_ID,
                    V_START_DATE,
                    V_END_DATE,
                    V_RATE,
                    V_RULES_DETAILS;

                IF (V_DONE) THEN
                  LEAVE readLoop2;
                END IF;

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
                    V_START_DATE,
                    V_END_DATE,
                    V_RATE,
                    V_RULES_DETAILS
                  );

              END LOOP;

            CLOSE V_RATE_PERIOD_RECORDS_CURSOR; -- 嵌套游标 结束

            SET V_DONE = FALSE;

          END IF;

        END LOOP;

      CLOSE V_CERTAIN_MAPPING_RECORDS_CURSOR; -- 嵌套游标 结束

      SET V_DONE = FALSE;

    END WHILE LABEL1;

  CLOSE V_MAPPING_RECORDS_CURSOR;
END