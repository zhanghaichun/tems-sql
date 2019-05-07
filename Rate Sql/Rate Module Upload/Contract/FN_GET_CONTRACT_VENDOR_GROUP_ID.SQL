DROP FUNCTION IF EXISTS FN_GET_CONTRACT_VENDOR_GROUP_ID;
CREATE FUNCTION FN_GET_CONTRACT_VENDOR_GROUP_ID( PARAM_MASTER_TABLE_ID INT) RETURNS INT

BEGIN 
  
    /**
     * Return vendor_group_id
<<<<<<< HEAD
     * local modified
=======
     * remote modified
>>>>>>> master
     */

    DECLARE V_SUMMARY_VENDOR_NAME VARCHAR(128);
    DECLARE V_VENDOR_NAME VARCHAR(128);

    DECLARE V_RETURNED_VENDOR_GROUP_ID INT;

    DECLARE V_VENDOR_GROUP_NAME_COUNT INT;

    DECLARE V_VENDOR_ID INT;
    DECLARE V_VENDOR_GROUP_ID INT;

  
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
    FROM rate_rule_contract_original
    WHERE id = PARAM_MASTER_TABLE_ID
        AND rec_active_flag = 'Y';

    IF ( V_SUMMARY_VENDOR_NAME IS NOT NULL ) THEN

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

            INSERT INTO vendor_group (group_name, vendor_ids, notes)
            VALUES (V_SUMMARY_VENDOR_NAME, V_VENDOR_IDS, CONCAT(V_SUMMARY_VENDOR_NAME, ' Summary Vendor') );

            SET V_RETURNED_VENDOR_GROUP_ID = ( SELECT MAX(id) FROM vendor_group );

            OPEN V_VENDOR_CURSOR;

                LABEL1:
                WHILE NOT V_CURSOR_DONE_FLAG DO
                
                    FETCH V_VENDOR_CURSOR INTO V_VENDOR_ID;

                    IF (V_CURSOR_DONE_FLAG) THEN
                        LEAVE LABEL1;
                    END IF;

                    SELECT COUNT(1) INTO V_MATCH_ITEM_COUNT
                    FROM vendor_group_vendor
                    WHERE vendor_group_id = V_RETURNED_VENDOR_GROUP_ID
                        AND vendor_id = V_VENDOR_ID;

                    IF (V_MATCH_ITEM_COUNT = 0) THEN

                        INSERT INTO vendor_group_vendor (vendor_group_id, vendor_id)
                        VALUES(V_RETURNED_VENDOR_GROUP_ID, V_VENDOR_ID);

                    END IF;

                END WHILE LABEL1;

            CLOSE V_VENDOR_CURSOR;

        ELSE

            SET V_RETURNED_VENDOR_GROUP_ID = (
                SELECT id
                FROM vendor_group
                WHERE vendor_ids = V_VENDOR_IDS
                LIMIT 1
            );

        END IF;

    END IF;

    RETURN V_RETURNED_VENDOR_GROUP_ID;

END

