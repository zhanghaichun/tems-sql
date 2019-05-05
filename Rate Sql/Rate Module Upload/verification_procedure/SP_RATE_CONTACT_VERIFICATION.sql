DROP PROCEDURE IF EXISTS ccm_db.SP_RATE_CONTACT_VERIFICATION;
CREATE PROCEDURE ccm_db.`SP_RATE_CONTACT_VERIFICATION`(V_BATCH_NO VARCHAR(64))
BEGIN
  
  DECLARE V_COUNT INT;
  DECLARE V_USER_ID INT;
  DECLARE V_VENDOR_ID INT;
  DECLARE V_ID INT;
  DECLARE V_ROW_NUMBER INT;
  DECLARE V_RATE_ID VARCHAR(12);

  DECLARE V_MAX_LENGTH INT DEFAULT 10000;

  DECLARE   V_CHARGE_TYPE VARCHAR(12);
  DECLARE   V_KEY_FIELD VARCHAR(64);
  DECLARE   V_EFFECTIVE_DATE  VARCHAR(64);
  DECLARE   V_SUMMARY_VENDOR_NAME VARCHAR(128);
  DECLARE   V_STRIPPED_CIRCUIT_NUMBER VARCHAR(128);
  DECLARE   V_USOC  VARCHAR(16);
  DECLARE   V_USOC_LONG_DESCRIPTION VARCHAR(255);
  DECLARE   V_SUB_PRODUCT VARCHAR(128);
  DECLARE   V_TERM  VARCHAR(32);
  DECLARE   V_LINE_ITEM_CODE_DESCRIPTION  VARCHAR(255);
  DECLARE   V_LINE_ITEM_CODE  VARCHAR(64);
  DECLARE   V_ITEM_DESCRIPTION  VARCHAR(128);
  DECLARE   V_RATE  VARCHAR(64);
  DECLARE   V_RENEWAL_TERM_AFTER_TERM_EXPIRATION  MEDIUMTEXT;
  DECLARE   V_EARLY_TERMINATION_FEE MEDIUMTEXT;
  DECLARE   V_CONTRACT_NAME MEDIUMTEXT;
  DECLARE   V_CONTRACT_SERVICE_SCHEDULE_NAME  MEDIUMTEXT;
  DECLARE   V_TOTAL_VOLUME_BEGIN  MEDIUMTEXT;
  DECLARE   V_TOTAL_VOLUME_END  MEDIUMTEXT;
  DECLARE   V_MMBC  MEDIUMTEXT;
  DECLARE   V_DISCOUNT  MEDIUMTEXT;
  DECLARE   V_NOTES MEDIUMTEXT;


  DECLARE   V_ORIGINAL_KEY_FIELD  VARCHAR(64);
  DECLARE   V_ORIGINAL_EFFECTIVE_DATE VARCHAR(64);
  DECLARE V_ORDER_NUMBER VARCHAR(128);

  DECLARE V_OWNER_EMAIL VARCHAR(128);
  DECLARE V_IS_EMAIL INT DEFAULT 0;
  DECLARE V_EMAIL VARCHAR(255);

  DECLARE V_SPECIAL_DIFFERENCE VARCHAR(768);
  DECLARE V_NOTFOUND INT DEFAULT FALSE;
  DECLARE V_DATE VARCHAR(64);
  DECLARE v_commit_count INT DEFAULT 0;

  DECLARE   V_CHILD_SUMMARY_VENDOR_NAME VARCHAR(128);

  DECLARE V_RATE_STATUS VARCHAR(128);
  DECLARE V_AUDIT_RATE_PERIOD_ID INT;
  DECLARE V_REFERENCE_TABLE VARCHAR(128);
  DECLARE V_REFERENCE_ID INT;
  DECLARE V_INACTIVE_MAX_EFFECTIVE_DATE VARCHAR(128);
  DECLARE V_ACTIVE_EFFECTIVE_DATE VARCHAR(128);
  DECLARE V_IS_NUMERICAL INT;
  DECLARE V_IS_DATE INT;


  /*DECLARE cur_summary_vendor_item CURSOR FOR
    SELECT substring_index(
        substring_index(V_SUMMARY_VENDOR_NAME, 'OR', b.help_topic_id + 1),
                      'OR',
                      -1)
              FROM mysql.help_topic b
             WHERE b.help_topic_id <
                      (  length(V_SUMMARY_VENDOR_NAME)
                       - length(replace(V_SUMMARY_VENDOR_NAME, 'OR', ''))
                       + 1);*/

  DECLARE cur_rate_item CURSOR FOR
      SELECT t.id,
            t.row_no,
            IFNULL(rate_id,''),
            -- replace(IFNULL(summary_vendor_name,''),'or','OR'),
            IFNULL(summary_vendor_name,''),
            IFNULL(charge_type,''),
            IFNULL(key_field,''),
            IFNULL(usoc,''),
            IFNULL(usoc_long_description,''),
            IFNULL(stripped_circuit_number,''),
            IFNULL(sub_product,''),
            IFNULL(rate,''),
            IFNULL(effective_date,''),
            IFNULL(term,''),
            IFNULL(renewal_term_after_term_expiration,''),
            IFNULL(early_termination_fee,''),
            IFNULL(item_description,''),
            IFNULL(contract_name,''),
            IFNULL(contract_service_schedule_name,''),
            IFNULL(line_item_code,''),
            IFNULL(line_item_code_description,''),
            IFNULL(total_volume_begin,''),
            IFNULL(total_volume_end,''),
            IFNULL(mmbc,''),
            IFNULL(discount,''),
            IFNULL(notes,'')
        FROM rate_rule_contact_master_import t
        where t.batch_no = V_BATCH_NO;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_NOTFOUND = TRUE;

  CALL SP_RATE_CONTACT_VERIFICATION_LENGTH(V_BATCH_NO);

  set autocommit = 0; 
  OPEN cur_rate_item;
    read_loop: LOOP
        FETCH cur_rate_item INTO
            V_ID,
            V_ROW_NUMBER,
            V_RATE_ID,
            V_SUMMARY_VENDOR_NAME,
            V_CHARGE_TYPE,
            V_KEY_FIELD,
            V_USOC,
            V_USOC_LONG_DESCRIPTION,
            V_STRIPPED_CIRCUIT_NUMBER,
            V_SUB_PRODUCT,
            V_RATE,
            V_EFFECTIVE_DATE,
            V_TERM,
            V_RENEWAL_TERM_AFTER_TERM_EXPIRATION,
            V_EARLY_TERMINATION_FEE,
            V_ITEM_DESCRIPTION,
            V_CONTRACT_NAME,
            V_CONTRACT_SERVICE_SCHEDULE_NAME,
            V_LINE_ITEM_CODE,
            V_LINE_ITEM_CODE_DESCRIPTION,
            V_TOTAL_VOLUME_BEGIN,
            V_TOTAL_VOLUME_END,
            V_MMBC,
            V_DISCOUNT,
            V_NOTES;
        IF V_NOTFOUND THEN
            LEAVE read_loop;
        END IF;

        -- Rate Id 
        IF V_RATE_ID IS NOT NULL AND V_RATE_ID != '' THEN -- Update

          SELECT (V_RATE_ID REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;

          IF V_IS_NUMERICAL > 0 THEN -- Contains character string

            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'ID','ID must be a numerical type');
            SET V_COUNT = 0;

          ELSE -- Only numeric

            SELECT COUNT(1) INTO V_COUNT FROM rate_rule_contract_original where id = V_RATE_ID AND rec_active_flag = 'Y';

            IF V_COUNT <= 0 THEN
              INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'ID','This key does not exist in rate.');
            END IF;

          END IF;

        ELSE -- insertion

          SET V_COUNT = 1;

        END IF;
        
        /**
         * Other fields verification.
         */
        IF V_COUNT > 0 THEN -- Insertion or Update
          
          IF V_KEY_FIELD IS NULL OR V_KEY_FIELD = '' THEN -- Not including Key Field.

            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Key Field*','Key Field* is required');

          ELSE -- Including Key Field

            IF V_RATE_ID IS NOT NULL AND V_RATE_ID != '' THEN -- Update

              SELECT 
                key_field,
                date_format(rate_effective_date, '%Y-%m-%d') 
                  INTO 
                    V_ORIGINAL_KEY_FIELD ,
                    V_ORIGINAL_EFFECTIVE_DATE
              FROM rate_rule_contract_original 
              WHERE id = V_RATE_ID AND rec_active_flag = 'Y';

              IF V_ORIGINAL_KEY_FIELD != V_KEY_FIELD THEN

                -- Cannot changing the Key Field.
                INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Key Field*','This is Key Filed that cannot be modified.');
              END IF;

              SELECT 
                rate_status, 
                audit_rate_period_id 
                  INTO 
                    V_RATE_STATUS, 
                    V_AUDIT_RATE_PERIOD_ID
              FROM rate_rule_contract_original 
              WHERE rec_active_flag = 'Y'
               AND id = V_RATE_ID;

              SELECT 
                reference_table, 
                reference_id
                  INTO 
                    V_REFERENCE_TABLE,
                    V_REFERENCE_ID
              FROM audit_rate_period
              WHERE rec_active_flag = 'Y'
                AND id = V_AUDIT_RATE_PERIOD_ID;

              IF (V_RATE_STATUS = 'Active') THEN
                
                -- Query the Inactive record count.
                SELECT 
                  COUNT(1) INTO V_COUNT
                FROM audit_rate_period
                WHERE rec_active_flag = 'Y'
                  AND reference_table = V_REFERENCE_TABLE
                  AND reference_id =  V_REFERENCE_ID
                  AND end_date IS NOT NULL;

                IF (V_COUNT > 0) THEN -- There are Inactive Records.

                  -- Query the max effective date of Inactive records.
                  SELECT start_date INTO V_INACTIVE_MAX_EFFECTIVE_DATE
                  FROM audit_rate_period
                  WHERE rec_active_flag = 'Y'
                    AND reference_table = V_REFERENCE_TABLE
                    AND reference_id =  V_REFERENCE_ID
                    AND end_date IS NOT NULL
                  ORDER BY start_date DESC
                  LIMIT 1;

                  IF( IFNULL(STR_TO_DATE(V_EFFECTIVE_DATE, '%m/%d/%Y'),'') <= DATE_FORMAT(V_INACTIVE_MAX_EFFECTIVE_DATE, '%Y-%m-%d')) THEN

                    -- Active effective date must be greater than Inactive effective date.
                    INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date','"Active Rate Effective Date" has to be greater than "Inactive Rate Effective Date"');
                  END IF;

                END IF;

              ELSEIF V_RATE_STATUS = 'Inactive' THEN

                -- Query the Active record count.
                SELECT 
                  COUNT(1) INTO V_COUNT
                FROM audit_rate_period
                WHERE rec_active_flag = 'Y'
                  AND reference_table = V_REFERENCE_TABLE
                  AND reference_id =  V_REFERENCE_ID
                  AND end_date IS NULL;

                IF (V_COUNT > 0) THEN -- There are Active Records.

                  -- Query the max effective date of Inactive records.
                  SELECT start_date INTO V_ACTIVE_EFFECTIVE_DATE
                  FROM audit_rate_period
                  WHERE rec_active_flag = 'Y'
                    AND reference_table = V_REFERENCE_TABLE
                    AND reference_id =  V_REFERENCE_ID
                    AND end_date IS NULL
                  ORDER BY start_date DESC
                  LIMIT 1;

                  IF( IFNULL(STR_TO_DATE(V_EFFECTIVE_DATE, '%m/%d/%Y'),'') >= DATE_FORMAT(V_ACTIVE_EFFECTIVE_DATE, '%Y-%m-%d')) THEN

                    INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date','"Inactive Rate Effective Date" cannot be greater than or equals to "Active Rate Effective Date"');
                  END IF;

                END IF;
                
              END IF; -- Update rate status judgement end. 

            END IF;

            -- Query if the Key Field is exist or not in TEMS database.
            select count(1) INTO V_COUNT 
            from audit_key_field 
            where audit_reference_type_id = 3 
              AND rec_active_flag = 'Y'
              AND key_field_original = V_KEY_FIELD;

            IF V_COUNT = 0 THEN -- Key Field is not exist in TEMS database.

              INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Key Field*',concat(V_KEY_FIELD,' does not exist in TEMS.'));

            ELSE -- Key Field is exist in TEMS database

              IF LOCATE('CVPP',V_KEY_FIELD) > 0 THEN
              -- Key Field is exist in TEMS database and Key Field contains 'CVPP' character string.

                IF V_MMBC IS NULL OR V_MMBC = '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'MMBC',concat('MMBC cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;
                
                IF V_DISCOUNT IS NULL OR V_DISCOUNT = '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Discount %',concat('Discount cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

                IF V_RATE IS NOT NULL AND V_RATE != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate',concat('Rate has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

              ELSE

                IF V_RATE IS NULL OR V_RATE = '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate','Rate is required');
                END IF;

                IF V_DISCOUNT IS NOT NULL AND V_DISCOUNT != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Discount %',concat('Discount has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

                IF V_MMBC IS NOT NULL AND V_MMBC != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'MMBC',concat('MMBC has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

              END IF;

              select locate('USOC',V_KEY_FIELD) INTO V_COUNT;

              IF V_COUNT > 0 THEN

                IF V_USOC IS NULL OR V_USOC = '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'USOC',concat('USOC cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;
              ELSE
                IF V_USOC IS NOT NULL AND V_USOC != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'USOC',concat('USOC has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;
              END IF;

              IF LOCATE('Line Item Code',V_KEY_FIELD) > 0 
                AND LOCATE('Line Item Code Description',V_KEY_FIELD) = 0 THEN 
                -- Key Field 只包含 'Line Item Code' 字样, 不包含 Line Item Code Description.

                IF ( IFNULL(V_LINE_ITEM_CODE, '') = '' ) THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code',concat('Line Item Code cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

              ELSEIF LOCATE('Line Item Code',V_KEY_FIELD) = 0 THEN -- Key Field 不包含 'Line Item Code' 字样

                IF  IFNULL(V_LINE_ITEM_CODE_DESCRIPTION, '') != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code Description',concat('Line Item Code Description has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

                IF ( IFNULL(V_LINE_ITEM_CODE, '') != '' ) THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code',concat('Line Item Code has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

              END IF;

              IF ( LOCATE('Line Item Code Description',V_KEY_FIELD) > 0 ) THEN

                IF IFNULL(V_LINE_ITEM_CODE_DESCRIPTION, '') = ''  THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code Description',concat('Line Item Code Description cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

                IF IFNULL(V_LINE_ITEM_CODE, '') != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code',concat('Line Item Code has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

                IF IFNULL(V_USOC_LONG_DESCRIPTION, '') != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'USOC Description',concat('USOC Description has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

              END IF;
              
              select locate('Item Description',V_KEY_FIELD) INTO V_COUNT;
              IF V_COUNT > 0 THEN
                IF V_ITEM_DESCRIPTION IS NULL OR V_ITEM_DESCRIPTION = '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Item Description',concat('Item Description cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;
              ELSE
                IF V_ITEM_DESCRIPTION IS NOT NULL AND V_ITEM_DESCRIPTION != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Item Description',concat('Item Description has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;
              END IF;

              IF V_CHARGE_TYPE IS NULL OR V_CHARGE_TYPE = '' THEN
                INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Charge Type','Charge Type is required');
              END IF;
        
              

        
              
              select locate('Stripped Circuit Number',V_KEY_FIELD) INTO V_COUNT;

              IF V_COUNT > 0 THEN
                IF V_STRIPPED_CIRCUIT_NUMBER IS NULL OR V_STRIPPED_CIRCUIT_NUMBER = '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Stripped Circuit Number',concat('Stripped Circuit Number cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;
              ELSE
                IF V_STRIPPED_CIRCUIT_NUMBER IS NOT NULL AND V_STRIPPED_CIRCUIT_NUMBER != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Stripped Circuit Number',concat('Stripped Circuit Number has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;
              END IF;


              select locate('Qty',V_KEY_FIELD) INTO V_COUNT;

              IF V_COUNT > 0 THEN

                SELECT (V_TOTAL_VOLUME_BEGIN REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;

                IF V_IS_NUMERICAL > 0 THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty Begin','Qty Begin must be a numerical type');
                END IF;

                SELECT (V_TOTAL_VOLUME_END REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;

                IF V_IS_NUMERICAL > 0 THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty End','Qty End must be a numerical type');
                END IF;

                IF V_TOTAL_VOLUME_BEGIN IS NULL OR V_TOTAL_VOLUME_BEGIN = '' THEN

                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty Begin',concat('Qty Begin cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
                ELSE

                  IF V_TOTAL_VOLUME_END IS NOT NULL AND V_TOTAL_VOLUME_END != '' AND V_TOTAL_VOLUME_BEGIN > V_TOTAL_VOLUME_END THEN
                    INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty End','"Qty End" has to be greater than "Qty Begin".');
                  END IF;

                END IF;

              ELSE

                IF (V_TOTAL_VOLUME_BEGIN IS NOT NULL AND V_TOTAL_VOLUME_BEGIN != '') OR (V_TOTAL_VOLUME_END IS NOT NULL AND V_TOTAL_VOLUME_END != '') THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty End',concat('Qty Begin and Qty End have to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

              END IF;

            END IF;

          END IF;

          IF V_EFFECTIVE_DATE IS NOT NULL AND V_EFFECTIVE_DATE != '' THEN -- There is having a efffective date.

            SELECT IFNULL(str_to_date(V_EFFECTIVE_DATE, '%m/%d/%Y'),'') INTO V_DATE;

            IF V_DATE IS NULL OR V_DATE = '' THEN 
              INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date','Rate Effective Date format must be "MM/DD/YYYY"');
            -- ELSEIF V_RATE_ID IS NOT NULL AND V_RATE_ID != '' AND V_RATE_ID != 0 AND V_DATE != V_ORIGINAL_EFFECTIVE_DATE THEN
              -- INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date',concat('%V_DATE=',V_DATE,'%V_ORIGINAL_EFFECTIVE_DATE=',V_ORIGINAL_EFFECTIVE_DATE));
              -- INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date','Cannot change Rate Effective Date, if you want to change, please contact the development team.');
            END IF;
            SELECT FN_VAIDATE_DATE_FIELD(V_EFFECTIVE_DATE) INTO V_IS_DATE;
            IF V_IS_DATE <= 0 THEN 
              INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date',concat("\"",V_EFFECTIVE_DATE,"\"",'is an invalid date value.'));
            END IF;
          ELSE
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date','Rate Effective Date is required');
          END IF;

          IF V_SUMMARY_VENDOR_NAME IS NULL OR V_SUMMARY_VENDOR_NAME = '' THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Summary Vendor Name (SVN) %Contains%','Summary Vendor Name is required');
          ELSE
            select count(1) INTO V_COUNT from vendor where replace(summary_vendor_name,' ','') like replace(concat('%',V_SUMMARY_VENDOR_NAME,'%'),' ','') and vendor_status_id = 1 and rec_active_flag = 'Y';
            IF V_COUNT = 0 THEN
              INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Summary Vendor Name (SVN) %Contains%',concat(V_SUMMARY_VENDOR_NAME,' does not exist in TEMS.'));
            END IF;
            /*OPEN cur_summary_vendor_item;
              read_loop1: LOOP
              FETCH cur_summary_vendor_item INTO
                    V_CHILD_SUMMARY_VENDOR_NAME;
              IF V_NOTFOUND THEN
                  LEAVE read_loop1;
              END IF;

              select count(1) INTO V_COUNT from vendor where replace(summary_vendor_name,' ','') like replace(concat('%',V_CHILD_SUMMARY_VENDOR_NAME,'%'),' ','') and vendor_status_id = 1 and rec_active_flag = 'Y';
              IF V_COUNT = 0 THEN
                INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Summary Vendor Name (SVN) %Contains%',concat(V_CHILD_SUMMARY_VENDOR_NAME,' is not exist.'));
                LEAVE read_loop1;
              END IF;

            END LOOP;
            CLOSE cur_summary_vendor_item;
            SET V_NOTFOUND = FALSE;*/
          END IF;
          
          SELECT (V_RATE REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate','Rate must be a numerical type');
          END IF;
          
          SELECT (V_DISCOUNT REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Discount %','Discount must be a numerical type');
          END IF;

          SELECT (V_TERM REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Term (Months)','Term (Months) must be a numerical type');
          END IF;
                  
          SELECT COUNT(1) INTO V_COUNT 
                FROM rate_rule_contract_original
               WHERE     rec_active_flag = 'Y'
                     AND id != IF(V_RATE_ID IS NOT NULL AND V_RATE_ID != '',V_RATE_ID,0)
                     AND charge_type = V_CHARGE_TYPE
                     AND key_field = V_KEY_FIELD
                     AND str_to_date(date_format(rate_effective_date, '%m/%d/%Y'), '%m/%d/%Y') = str_to_date(V_EFFECTIVE_DATE, '%m/%d/%Y')
                     AND IFNULL(summary_vendor_name,'') = V_SUMMARY_VENDOR_NAME
                     AND IFNULL(usoc,'') = V_USOC
                     AND IFNULL(usoc_description,'') = V_USOC_LONG_DESCRIPTION
                     AND IFNULL(stripped_circuit_number,'') = V_STRIPPED_CIRCUIT_NUMBER
                     AND IFNULL(sub_product,'') = V_SUB_PRODUCT
                     AND IFNULL(line_item_code_description,'') = V_LINE_ITEM_CODE_DESCRIPTION
                     AND IFNULL(rate,'') = 0+V_RATE
                     AND IFNULL(discount,'') = 0+V_DISCOUNT
                     AND IFNULL(line_item_code,'') = V_LINE_ITEM_CODE
                     AND IFNULL(item_description,'') = V_ITEM_DESCRIPTION;
          IF V_COUNT > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'ID','This record already exists in TEMS.');
          END IF;

          SELECT COUNT(1) INTO V_COUNT 
                FROM rate_rule_contact_master_import
               WHERE     id != V_ID
                     AND batch_no = V_BATCH_NO
                     AND charge_type = V_CHARGE_TYPE
                     AND key_field = V_KEY_FIELD
                     AND str_to_date(date_format(effective_date, '%m/%d/%Y'), '%m/%d/%Y') = str_to_date(V_EFFECTIVE_DATE, '%m/%d/%Y')
                     AND IFNULL(summary_vendor_name,'') = V_SUMMARY_VENDOR_NAME
                     AND IFNULL(usoc,'') = V_USOC
                     AND IFNULL(usoc_long_description,'') = V_USOC_LONG_DESCRIPTION
                     AND IFNULL(stripped_circuit_number,'') = V_STRIPPED_CIRCUIT_NUMBER
                     AND IFNULL(sub_product,'') = V_SUB_PRODUCT
                     AND IFNULL(line_item_code_description,'') = V_LINE_ITEM_CODE_DESCRIPTION
                     AND IFNULL(line_item_code,'') = V_LINE_ITEM_CODE
                     AND IFNULL(item_description,'') = V_ITEM_DESCRIPTION;
          IF V_COUNT > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'ID','This record already exists in TEMS.');
          END IF;

        
        END IF;
        
        
       SET v_commit_count = v_commit_count + 1;
       IF (v_commit_count % 100 = 0) THEN
          commit;
       END IF;

      IF V_ROW_NUMBER % 1000 = 0 THEN
        SELECT COUNT(1) INTO V_COUNT FROM tmp_rate_error;
        IF V_COUNT >= V_MAX_LENGTH THEN
          SET V_NOTFOUND = TRUE;
        END IF;
      END IF;

    END LOOP;
    
  CLOSE cur_rate_item;

   commit;
   set autocommit = 1;
   
  SELECT COUNT(1) INTO V_COUNT
    FROM tmp_rate_error;
  IF V_COUNT = 0 THEN
    INSERT INTO rate_rule_contact_master_batch(rate_id,
                                     batch_no,
                                     row_no,
                                     user_id,
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
                                    notes)
    SELECT IF(rate_id!='',rate_id,NULL),
           batch_no,
           row_no,
           user_id,
           IF(summary_vendor_name!='',summary_vendor_name,NULL),
           IF(charge_type!='',charge_type,NULL),
           IF(key_field!='',key_field,NULL),
           IF(usoc!='',usoc,NULL),
           IF(usoc_long_description!='',usoc_long_description,NULL),
           IF(stripped_circuit_number!='',stripped_circuit_number,NULL),
           IF(sub_product!='',sub_product,NULL),
           IF(rate!='',rate,NULL),
           IF(effective_date!='',str_to_date(effective_date,'%m/%d/%Y'),NULL),
           IF(term!='',term,NULL),
           IF(renewal_term_after_term_expiration!='',renewal_term_after_term_expiration,NULL),
           IF(early_termination_fee!='',early_termination_fee,NULL),
           IF(item_description!='',item_description,NULL),
           IF(contract_name!='',contract_name,NULL),
           IF(contract_service_schedule_name!='',contract_service_schedule_name,NULL),
           IF(line_item_code!='',line_item_code,NULL),
           IF(line_item_code_description!='',line_item_code_description,NULL),
           IF(total_volume_begin!='',total_volume_begin,NULL),
           IF(total_volume_end!='',total_volume_end,NULL),
           IF(mmbc!='',mmbc,NULL),
           IF(discount!='',discount,NULL),
           IF(notes!='',notes,NULL)
     FROM rate_rule_contact_master_import WHERE batch_no = V_BATCH_NO;
     CALL SP_UPDATE_CONTRACT_MASTER_DATA_TO_RATE_MODULE_TABLES(V_BATCH_NO);
  END IF;
  DELETE FROM rate_rule_contact_master_import WHERE batch_no = V_BATCH_NO;
END;
