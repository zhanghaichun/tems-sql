DROP PROCEDURE IF EXISTS SP_SPLIT_SUMMARY_VENDOR_MULTIPLE_FIELD_VALUE;
CREATE PROCEDURE SP_SPLIT_SUMMARY_VENDOR_MULTIPLE_FIELD_VALUE( 
                                                IN PARAM_FIELD_VALUE VARCHAR(128),
                                                OUT PARAM_VENDOR_GROUP_ID INT 
                                              )

BEGIN
  
  DECLARE V_KEYWORD_KEY VARCHAR(2) DEFAULT ' or ';

  DECLARE V_SUMMARY_VENDOR_NAME VARCHAR(64) DEFAULT '';
  DECLARE V_TMP_TABLE_ID INT;
  DECLARE V_COMBINED_VENDOR_IDS VARCHAR(256) DEFAULT '';

  DECLARE V_VENDOR_IDS VARCHAR(256) DEFAULT '';

  DECLARE V_VENDOR_ID INT;

  DECLARE V_IS_EXIST_COUNT INT;

  DECLARE V_TMP_FIELD_VALUE VARCHAR(128);

  DECLARE V_KEYWORD_LOCATION_INDEX INT;

  DECLARE V_VENDOR_GROUP_ITEM_COUNT INT;

  DECLARE V_CURSOR_DONE_FLAG BOOLEAN DEFAULT FALSE;

  DECLARE V_VENDOR_CURSOR CURSOR FOR
    SELECT id
    FROM vendor
    WHERE summary_vendor_name LIKE CONCAT('%',V_SUMMARY_VENDOR_NAME,'%')
      AND vendor_status_id = 1
      AND rec_active_flag = 'Y';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_CURSOR_DONE_FLAG = TRUE;

  SET V_TMP_FIELD_VALUE = REPLACE(PARAM_FIELD_VALUE, ' OR ', ' or ');

  LABEL1:
  WHILE POSITION(V_KEYWORD_KEY IN V_TMP_FIELD_VALUE)
    DO

      SET V_KEYWORD_LOCATION_INDEX = LOCATE(V_KEYWORD_KEY, V_TMP_FIELD_VALUE);

      SET V_SUMMARY_VENDOR_NAME = TRIM( SUBSTRING_INDEX(V_TMP_FIELD_VALUE, V_KEYWORD_KEY, 1) );

      SELECT GROUP_CONCAT( CAST(id AS CHAR) ORDER BY id ) INTO V_VENDOR_IDS FROM vendor 
      WHERE summary_vendor_name = V_SUMMARY_VENDOR_NAME
        AND vendor_status_id = 1
        AND rec_active_flag = 'Y'
      LIMIT 1;

      SET V_COMBINED_VENDOR_IDS = CONCAT(V_COMBINED_VENDOR_IDS, ',', V_VENDOR_IDS);

      SET V_TMP_FIELD_VALUE = 
        TRIM( SUBSTRING(V_TMP_FIELD_VALUE, V_KEYWORD_LOCATION_INDEX + LENGTH(V_KEYWORD_KEY) + 1 ) );

      IF ( LOCATE(V_KEYWORD_KEY, V_TMP_FIELD_VALUE) < 1) THEN

        SET V_SUMMARY_VENDOR_NAME = TRIM(V_TMP_FIELD_VALUE);

        SELECT GROUP_CONCAT( CAST(id AS CHAR) ORDER BY id ) INTO V_VENDOR_IDS FROM vendor 
        WHERE summary_vendor_name = V_SUMMARY_VENDOR_NAME
          AND vendor_status_id = 1
          AND rec_active_flag = 'Y'
        LIMIT 1;

        SET V_COMBINED_VENDOR_IDS = CONCAT(V_COMBINED_VENDOR_IDS, ',', V_VENDOR_IDS);

        LEAVE LABEL1;
      END IF;

  END WHILE LABEL1;

  SET V_COMBINED_VENDOR_IDS = SUBSTRING(V_COMBINED_VENDOR_IDS, 2);
  SET V_TMP_FIELD_VALUE = REPLACE(PARAM_FIELD_VALUE, ' OR ', ' or ');

  SELECT COUNT(1) INTO V_VENDOR_GROUP_ITEM_COUNT
  FROM vendor_group
  WHERE vendor_ids = V_COMBINED_VENDOR_IDS;

  IF(V_VENDOR_GROUP_ITEM_COUNT = 0) THEN

    INSERT INTO vendor_group(group_name, vendor_ids, notes)
    VALUES(PARAM_FIELD_VALUE, V_COMBINED_VENDOR_IDS, CONCAT(PARAM_FIELD_VALUE, 'summary vendor'));

    SELECT MAX(id) INTO PARAM_VENDOR_GROUP_ID
    FROM vendor_group;

    LABEL2:
    WHILE POSITION(V_KEYWORD_KEY IN V_TMP_FIELD_VALUE)
      DO

        SET V_KEYWORD_LOCATION_INDEX = LOCATE(V_KEYWORD_KEY, V_TMP_FIELD_VALUE);

        SET V_SUMMARY_VENDOR_NAME = TRIM( SUBSTRING_INDEX(V_TMP_FIELD_VALUE, V_KEYWORD_KEY, 1) );

        SET V_CURSOR_DONE_FLAG = FALSE;

        /**
         * 循环向 vendor_group_vendor 表中插入数据。
         */
        OPEN V_VENDOR_CURSOR;

          LABEL3:
          WHILE NOT V_CURSOR_DONE_FLAG
          DO
            FETCH V_VENDOR_CURSOR INTO V_VENDOR_ID;

            IF (V_CURSOR_DONE_FLAG) THEN
              LEAVE LABEL3;
            END IF;

            /**
             * 检索 vendor_group_vendor 表中是否有当前的对应关系。
             */
            SELECT COUNT(1) INTO V_IS_EXIST_COUNT
            FROM vendor_group_vendor
            WHERE vendor_group_id = PARAM_VENDOR_GROUP_ID
              AND vendor_id = V_VENDOR_ID;

            IF (V_IS_EXIST_COUNT = 0) THEN

              /**
               * vendor_group_vendor 表中不存在对应关系， 则执行插入。
               */
              INSERT INTO vendor_group_vendor (vendor_group_id, vendor_id)
              VALUES(PARAM_VENDOR_GROUP_ID, V_VENDOR_ID);

            END IF;

          END WHILE LABEL3;

        CLOSE V_VENDOR_CURSOR;

        SET V_TMP_FIELD_VALUE = 
          TRIM( SUBSTRING(V_TMP_FIELD_VALUE, V_KEYWORD_LOCATION_INDEX + LENGTH(V_KEYWORD_KEY) + 1 ) );

        IF ( LOCATE(V_KEYWORD_KEY, V_TMP_FIELD_VALUE) < 1) THEN

          SET V_SUMMARY_VENDOR_NAME = TRIM(V_TMP_FIELD_VALUE);

          SET V_CURSOR_DONE_FLAG = FALSE;

          OPEN V_VENDOR_CURSOR;

            LABEL4:
            WHILE NOT V_CURSOR_DONE_FLAG
            DO
              FETCH V_VENDOR_CURSOR INTO V_VENDOR_ID;

              IF (V_CURSOR_DONE_FLAG) THEN
                LEAVE LABEL4;
              END IF;

              /**
               * 检索 vendor_group_vendor 表中是否有当前的对应关系。
               */
              SELECT COUNT(1) INTO V_IS_EXIST_COUNT
              FROM vendor_group_vendor
              WHERE vendor_group_id = PARAM_VENDOR_GROUP_ID
                AND vendor_id = V_VENDOR_ID;

              IF (V_IS_EXIST_COUNT = 0) THEN

                /**
                 * vendor_group_vendor 表中不存在对应关系， 则执行插入。
                 */
                INSERT INTO vendor_group_vendor (vendor_group_id, vendor_id)
                VALUES(PARAM_VENDOR_GROUP_ID, V_VENDOR_ID);

              END IF;

            END WHILE LABEL4;

          CLOSE V_VENDOR_CURSOR;

          LEAVE LABEL2;
        END IF;

    END WHILE LABEL2;

  ELSE

    SET PARAM_VENDOR_GROUP_ID = (
        SELECT id
        FROM vendor_group
        WHERE vendor_ids = V_COMBINED_VENDOR_IDS
        LIMIT 1
      );



  END IF;


  

END


