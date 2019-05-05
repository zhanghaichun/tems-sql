DROP PROCEDURE IF EXISTS SP_SPLIT_VENDOR_MULTIPLE_FIELD_VALUE;
CREATE PROCEDURE SP_SPLIT_VENDOR_MULTIPLE_FIELD_VALUE( 
                                                IN PARAM_FIELD_VALUE VARCHAR(128),
                                                OUT PARAM_VENDOR_GROUP_ID INT 
                                              )

BEGIN
  
  DECLARE V_KEYWORD_KEY VARCHAR(2) DEFAULT ' or ';

  DECLARE V_VENDOR_NAME VARCHAR(64) DEFAULT '';
  DECLARE V_TMP_TABLE_ID INT;
  DECLARE V_VENDOR_ID INT;

  DECLARE V_VENDOR_IDS VARCHAR(256) DEFAULT '';

  DECLARE V_IS_EXIST_COUNT INT;

  DECLARE V_TMP_FIELD_VALUE VARCHAR(128);

  DECLARE V_KEYWORD_LOCATION_INDEX INT;

  DECLARE V_VENDOR_GROUP_ITEM_COUNT INT;

  SET V_TMP_FIELD_VALUE = REPLACE(PARAM_FIELD_VALUE, ' OR ', ' or ');

  LABEL1:
  WHILE POSITION(V_KEYWORD_KEY IN V_TMP_FIELD_VALUE)
    DO

      SET V_KEYWORD_LOCATION_INDEX = LOCATE(V_KEYWORD_KEY, V_TMP_FIELD_VALUE);

      SET V_VENDOR_NAME = TRIM( SUBSTRING_INDEX(V_TMP_FIELD_VALUE, V_KEYWORD_KEY, 1) );

      SELECT id INTO V_VENDOR_ID FROM vendor 
      WHERE vendor_name = V_VENDOR_NAME
        AND vendor_status_id = 1
        AND rec_active_flag = 'Y'
      LIMIT 1;

      SET V_VENDOR_IDS = CONCAT(V_VENDOR_IDS, ',', V_VENDOR_ID);

      SET V_TMP_FIELD_VALUE = 
        TRIM( SUBSTRING(V_TMP_FIELD_VALUE, V_KEYWORD_LOCATION_INDEX + LENGTH(V_KEYWORD_KEY) + 1 ) );

      IF ( LOCATE(V_KEYWORD_KEY, V_TMP_FIELD_VALUE) < 1) THEN

        SET V_VENDOR_NAME = TRIM(V_TMP_FIELD_VALUE);

        SELECT id INTO V_VENDOR_ID FROM vendor 
        WHERE vendor_name = V_VENDOR_NAME
          AND vendor_status_id = 1
          AND rec_active_flag = 'Y'
        LIMIT 1;

         SET V_VENDOR_IDS = CONCAT(V_VENDOR_IDS, ',', V_VENDOR_ID);

        LEAVE LABEL1;
      END IF;

  END WHILE LABEL1;

  SET V_VENDOR_IDS = SUBSTRING(V_VENDOR_IDS, 2);
  SET V_TMP_FIELD_VALUE = REPLACE(PARAM_FIELD_VALUE, ' OR ', ' or ');

  SELECT COUNT(1) INTO V_VENDOR_GROUP_ITEM_COUNT
  FROM vendor_group
  WHERE vendor_ids = V_VENDOR_IDS;

  IF(V_VENDOR_GROUP_ITEM_COUNT = 0) THEN

    INSERT INTO vendor_group(group_name, vendor_ids, notes)
    VALUES(PARAM_FIELD_VALUE, V_VENDOR_IDS, PARAM_FIELD_VALUE);

    SELECT MAX(id) INTO PARAM_VENDOR_GROUP_ID
    FROM vendor_group;

    LABEL2:
    WHILE POSITION(V_KEYWORD_KEY IN V_TMP_FIELD_VALUE)
      DO

        SET V_KEYWORD_LOCATION_INDEX = LOCATE(V_KEYWORD_KEY, V_TMP_FIELD_VALUE);

        SET V_VENDOR_NAME = TRIM( SUBSTRING_INDEX(V_TMP_FIELD_VALUE, V_KEYWORD_KEY, 1) );

        SELECT id INTO V_VENDOR_ID FROM vendor 
        WHERE vendor_name = V_VENDOR_NAME
          AND vendor_status_id = 1
          AND rec_active_flag = 'Y'
        LIMIT 1;

        SELECT COUNT(1) INTO V_IS_EXIST_COUNT
        FROM vendor_group_vendor
        WHERE vendor_group_id = PARAM_VENDOR_GROUP_ID
          AND vendor_id = V_VENDOR_ID;

        IF (V_IS_EXIST_COUNT = 0) THEN

          INSERT INTO vendor_group_vendor(vendor_group_id, vendor_id)
          VALUES( PARAM_VENDOR_GROUP_ID, V_VENDOR_ID );

        END IF;

        SET V_TMP_FIELD_VALUE = 
          TRIM( SUBSTRING(V_TMP_FIELD_VALUE, V_KEYWORD_LOCATION_INDEX + LENGTH(V_KEYWORD_KEY) + 1 ) );

        IF ( LOCATE(V_KEYWORD_KEY, V_TMP_FIELD_VALUE) < 1) THEN

          SET V_VENDOR_NAME = TRIM(V_TMP_FIELD_VALUE);

          SELECT id INTO V_VENDOR_ID
          FROM vendor 
          WHERE vendor_name = V_VENDOR_NAME
          LIMIT 1;

          SELECT COUNT(1) INTO V_IS_EXIST_COUNT
          FROM vendor_group_vendor
          WHERE vendor_group_id = PARAM_VENDOR_GROUP_ID
            AND vendor_id = V_VENDOR_ID;

          IF (V_IS_EXIST_COUNT = 0) THEN

            INSERT INTO vendor_group_vendor(vendor_group_id, vendor_id)
            VALUES( PARAM_VENDOR_GROUP_ID, V_VENDOR_ID );
            
          END IF;

          LEAVE LABEL2;
        END IF;

    END WHILE LABEL2;

  ELSE

    SET PARAM_VENDOR_GROUP_ID = (
        SELECT id
        FROM vendor_group
        WHERE vendor_ids = V_VENDOR_IDS
        LIMIT 1
      );



  END IF;


  

END


