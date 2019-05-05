DROP FUNCTION IF EXISTS FN_GET_MTM_VENDOR_GROUP_ID;
CREATE FUNCTION FN_GET_MTM_VENDOR_GROUP_ID( PARAM_MASTER_TABLE_ID INT) RETURNS INT

BEGIN 
  
  /**
   * 这个存储过程用来返回 vendor_group_id
   */

  DECLARE V_SUMMARY_VENDOR_NAME VARCHAR(128);
  DECLARE V_VENDOR_NAME VARCHAR(128);

  DECLARE V_RETURNED_VENDOR_GROUP_ID INT;

  DECLARE V_VENDOR_GROUP_NAME_COUNT INT;

  DECLARE V_VENDOR_ID INT;
  DECLARE V_VENDOR_GROUP_ID INT;

  /**
   * 在 vendor_group_vendor 表中是否存在某一个 vendor_group 和 某一个 vendor 的对应关系。
   */
  DECLARE V_MATCH_ITEM_COUNT INT;

  DECLARE V_VENDOR_IDS VARCHAR(256);
  DECLARE V_VENDOR_IDS_ITEM_COUNT INT;

  DECLARE V_CURSOR_DONE_FLAG BOOLEAN DEFAULT FALSE;

  DECLARE V_VENDOR_CURSOR CURSOR FOR
    SELECT id
    FROM vendor
    WHERE summary_vendor_name LIKE CONCAT('%',V_SUMMARY_VENDOR_NAME,'%')
      AND vendor_status_id = 1
      AND rec_active_flag = 'Y';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_CURSOR_DONE_FLAG = TRUE;

  SELECT 
    summary_vendor_name
      INTO
        V_SUMMARY_VENDOR_NAME
  FROM rate_rule_mtm_original
  WHERE id = PARAM_MASTER_TABLE_ID
    AND rec_active_flag = 'Y';

  IF ( V_SUMMARY_VENDOR_NAME IS NOT NULL ) THEN

    IF( POSITION(' OR ' IN V_SUMMARY_VENDOR_NAME) ) THEN

      CALL SP_SPLIT_SUMMARY_VENDOR_MULTIPLE_FIELD_VALUE(
          V_SUMMARY_VENDOR_NAME, 
          V_RETURNED_VENDOR_GROUP_ID
        );

    ELSE

      /**
       * 查看当前 summary_vendor_name 是否存在于 vendor_group 表中。
       */

      SELECT GROUP_CONCAT( CAST(id AS CHAR) ORDER BY id )
        INTO V_VENDOR_IDS
      FROM vendor
      WHERE summary_vendor_name = V_SUMMARY_VENDOR_NAME
        AND vendor_status_id = 1
        AND rec_active_flag = 'Y';

      SELECT COUNT(1) INTO V_VENDOR_IDS_ITEM_COUNT
      FROM vendor_group
      WHERE vendor_ids = V_VENDOR_IDS;

      IF (V_VENDOR_IDS_ITEM_COUNT = 0) THEN

        /**
         * vendor_group 表中不存在此 summary vendor.
         */
        
        INSERT INTO vendor_group (group_name, vendor_ids, notes)
        VALUES (V_SUMMARY_VENDOR_NAME, V_VENDOR_IDS, CONCAT(V_SUMMARY_VENDOR_NAME, ' Summary Vendor') );

        SET V_RETURNED_VENDOR_GROUP_ID = ( SELECT MAX(id) FROM vendor_group );

        /**
         * 循环向 vendor_group_vendor 表中插入记录
         * 这些记录代表的是： vendor 都属于当前 summary_vendor， 但是在 vendor_group_vendor 中不存在
         * 对应关系。
         */
        OPEN V_VENDOR_CURSOR;

          LABEL1:
          WHILE NOT V_CURSOR_DONE_FLAG
          DO
            FETCH V_VENDOR_CURSOR INTO V_VENDOR_ID;

            IF (V_CURSOR_DONE_FLAG) THEN
              LEAVE LABEL1;
            END IF;

            /**
             * 检索 vendor_group_vendor 表中是否有当前的对应关系。
             */
            SELECT COUNT(1) INTO V_MATCH_ITEM_COUNT
            FROM vendor_group_vendor
            WHERE vendor_group_id = V_RETURNED_VENDOR_GROUP_ID
              AND vendor_id = V_VENDOR_ID;

            IF (V_MATCH_ITEM_COUNT = 0) THEN

              /**
               * vendor_group_vendor 表中不存在对应关系， 则执行插入。
               */
              INSERT INTO vendor_group_vendor (vendor_group_id, vendor_id)
              VALUES(V_RETURNED_VENDOR_GROUP_ID, V_VENDOR_ID);

            END IF;

          END WHILE LABEL1;

        CLOSE V_VENDOR_CURSOR;

      ELSE

        /**
         * vendor_group 表中存在此 summary vendor.
         */
        SET V_RETURNED_VENDOR_GROUP_ID = (
            SELECT id
            FROM vendor_group
            WHERE vendor_ids = V_VENDOR_IDS
            LIMIT 1
          );

      END IF;

    END IF;

  END IF;

  RETURN V_RETURNED_VENDOR_GROUP_ID;

END

