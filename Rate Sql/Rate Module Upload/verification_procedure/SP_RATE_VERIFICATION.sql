DROP PROCEDURE IF EXISTS ccm_db.SP_RATE_VERIFICATION;
CREATE PROCEDURE ccm_db.`SP_RATE_VERIFICATION`(V_BATCH_NO VARCHAR(64))
BEGIN
  
  DECLARE V_COUNT INT;
  DECLARE V_USER_ID INT;
  DECLARE V_VENDOR_ID INT;
  DECLARE V_ID INT;
  DECLARE V_ROW_NUMBER INT;
  DECLARE V_RATE_ID	VARCHAR(12);

  DECLARE V_MAX_LENGTH INT DEFAULT 10000;
  DECLARE 	V_CHARGE_TYPE	VARCHAR(12);
	DECLARE 	V_KEY_FIELD	VARCHAR(64);
	DECLARE 	V_RATE_EFFECTIVE_DATE	VARCHAR(64);
	DECLARE 	V_SUMMARY_VENDOR_NAME	VARCHAR(128);
	DECLARE 	V_VENDOR_NAME	VARCHAR(128);
	DECLARE 	V_USOC	VARCHAR(16);
	DECLARE 	V_USOC_DESCRIPTION	VARCHAR(255);
	DECLARE 	V_SUB_PRODUCT	VARCHAR(128);
	DECLARE 	V_LINE_ITEM_CODE_DESCRIPTION	VARCHAR(255);
	DECLARE 	V_LINE_ITEM_CODE	VARCHAR(64);
	DECLARE 	V_ITEM_TYPE	VARCHAR(64);
	DECLARE 	V_ITEM_DESCRIPTION	VARCHAR(128);
	DECLARE 	V_QUANTITY_BEGIN	VARCHAR(64);
	DECLARE 	V_QUANTITY_END	VARCHAR(64);
	DECLARE 	V_TARIFF_FILE_NAME	VARCHAR(42);
	DECLARE 	V_TARIFF_REFERENCE	VARCHAR(500);
	DECLARE 	V_BASE_AMOUNT	VARCHAR(64);
	DECLARE 	V_MULTIPLIER	VARCHAR(64);
	DECLARE 	V_RATE	VARCHAR(64);
	DECLARE 	V_RULES_DETAILS	VARCHAR(500);
	DECLARE 	V_TARIFF_PAGE	VARCHAR(32);
	DECLARE 	V_PDF_PAGE	VARCHAR(16);
	DECLARE 	V_PART_SECTION	VARCHAR(32);
	DECLARE 	V_ITEM_NUMBER	VARCHAR(32);
	DECLARE 	V_CRTC_NUMBER	VARCHAR(12);
	DECLARE 	V_DISCOUNT	VARCHAR(64);
	DECLARE 	V_EXCLUSION_BAN	VARCHAR(32);
	DECLARE 	V_EXCLUSION_ITEM_DESCRIPTON	VARCHAR(256);
	DECLARE 	V_NOTES	VARCHAR(500);

	DECLARE 	V_KEY_FIELD_IS_VN INT DEFAULT 0;
	DECLARE 	V_CHILD_VENDOR_NAME	VARCHAR(128);
	DECLARE 	V_CHILD_SUMMARY_VENDOR_NAME	VARCHAR(128);
	DECLARE 	V_ORIGINAL_KEY_FIELD	VARCHAR(64);
	DECLARE 	V_ORIGINAL_EFFECTIVE_DATE	VARCHAR(64);
	DECLARE 	V_ORIGINAL_TARIFF_PAGE	VARCHAR(32);
	DECLARE 	V_ORIGINAL_PART_SECTION	VARCHAR(32);
	DECLARE 	V_ORIGINAL_ITEM_NUMBER	VARCHAR(32);
	DECLARE 	V_ORIGINAL_CRTC_NUMBER	VARCHAR(32);
	DECLARE 	V_ORIGINAL_TARIFF_NAME	VARCHAR(500);



  DECLARE V_ORDER_NUMBER VARCHAR(128);

  DECLARE V_OWNER_EMAIL VARCHAR(128);
  DECLARE V_IS_EMAIL INT DEFAULT 0;
  DECLARE V_EMAIL VARCHAR(255);

  DECLARE V_SPECIAL_DIFFERENCE VARCHAR(768);
  DECLARE V_NOTFOUND INT DEFAULT FALSE;
	DECLARE V_DATE VARCHAR(64);
	DECLARE v_commit_count INT DEFAULT 0;

	DECLARE V_RATE_STATUS VARCHAR(128);
	DECLARE V_AUDIT_RATE_PERIOD_ID INT;
	DECLARE V_REFERENCE_TABLE VARCHAR(128);
	DECLARE V_REFERENCE_ID INT;
	DECLARE V_INACTIVE_MAX_EFFECTIVE_DATE VARCHAR(128);
	DECLARE V_ACTIVE_EFFECTIVE_DATE VARCHAR(128);
  DECLARE V_IS_NUMERICAL INT;
  DECLARE V_IS_DATE INT;


	/*DECLARE cur_vendor_item CURSOR FOR
		SELECT substring_index(
				substring_index(V_VENDOR_NAME, 'OR', b.help_topic_id + 1),
											'OR',
											-1)
							FROM mysql.help_topic b
						 WHERE b.help_topic_id <
											(  length(V_VENDOR_NAME)
											 - length(replace(V_VENDOR_NAME, 'OR', ''))
											 + 1);

	DECLARE cur_summary_vendor_item CURSOR FOR
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
						IFNULL(charge_type,''),
						IFNULL(key_field,''),
						IFNULL(rate_effective_date,''),
						-- replace(IFNULL(summary_vendor_name,''),'or','OR'),
						-- replace(IFNULL(vendor_name,''),'or','OR'),
						IFNULL(summary_vendor_name,''),
						IFNULL(vendor_name,''),
						IFNULL(usoc,''),
						IFNULL(usoc_description,''),
						IFNULL(sub_product,''),
						IFNULL(line_item_code_description,''),
						IFNULL(line_item_code,''),
						IFNULL(item_type,''),
						IFNULL(item_description,''),
						IFNULL(quantity_begin,''),
						IFNULL(quantity_end,''),
						IFNULL(tariff_file_name,''),
						IFNULL(tariff_reference,''),
						IFNULL(base_amount,''),
						IFNULL(multiplier,''),
						IFNULL(rate,''),
						IFNULL(rules_details,''),
						IFNULL(tariff_page,''),
						IFNULL(pdf_page,''),
						IFNULL(part_section,''),
						IFNULL(item_number,''),
						IFNULL(crtc_number,''),
						IFNULL(discount,''),
						IFNULL(exclusion_ban,''),
						IFNULL(exclusion_item_descripton,''),
						IFNULL(notes,'')
        FROM rate_rule_tariff_master_import t
        where t.batch_no = V_BATCH_NO;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_NOTFOUND = TRUE;

  CALL SP_RATE_VERIFICATION_LENGTH(V_BATCH_NO);

  set autocommit = 0; 
  OPEN cur_rate_item;
    read_loop: LOOP
        FETCH cur_rate_item INTO
            V_ID,
						V_ROW_NUMBER,
						V_RATE_ID,
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
						V_ITEM_DESCRIPTION,
						V_QUANTITY_BEGIN,
						V_QUANTITY_END,
						V_TARIFF_FILE_NAME,
						V_TARIFF_REFERENCE,
						V_BASE_AMOUNT,
						V_MULTIPLIER,
						V_RATE,
						V_RULES_DETAILS,
						V_TARIFF_PAGE,
						V_PDF_PAGE,
						V_PART_SECTION,
						V_ITEM_NUMBER,
						V_CRTC_NUMBER,
						V_DISCOUNT,
						V_EXCLUSION_BAN,
						V_EXCLUSION_ITEM_DESCRIPTON,
						V_NOTES;
        IF V_NOTFOUND THEN
            LEAVE read_loop;
        END IF;

        IF V_RATE_ID IS NOT NULL AND V_RATE_ID != '' THEN
					SELECT (V_RATE_ID REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'ID','ID must be a numerical type');
						SET V_COUNT = 0;
					ELSE
						SELECT COUNT(1) INTO V_COUNT FROM rate_rule_tariff_original where id = V_RATE_ID AND rec_active_flag = 'Y';
          END IF;
        ELSE
          SET V_COUNT = 1;
        END IF;

        IF V_COUNT > 0 THEN
          
					IF V_KEY_FIELD IS NULL OR V_KEY_FIELD = '' THEN
						INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Key Field*','Key Field* is required');
					ELSE
						IF V_RATE_ID IS NOT NULL AND V_RATE_ID != '' THEN

							SELECT key_field,date_format(rate_effective_date, '%Y-%m-%d'),
											IFNULL(tariff_page,''),IFNULL(part_section,''),
											IFNULL(item_number,''),IFNULL(crtc_number,''),IFNULL(tariff_name,'') 
								INTO V_ORIGINAL_KEY_FIELD ,V_ORIGINAL_EFFECTIVE_DATE,V_ORIGINAL_TARIFF_PAGE,V_ORIGINAL_PART_SECTION,V_ORIGINAL_ITEM_NUMBER,V_ORIGINAL_CRTC_NUMBER,V_ORIGINAL_TARIFF_NAME
							FROM rate_rule_tariff_original WHERE id = V_RATE_ID AND rec_active_flag = 'Y';

							IF V_ORIGINAL_KEY_FIELD != V_KEY_FIELD THEN
								INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Key Field*','This is Key Filed that cannot be modified.');
							END IF;

							/*IF (V_ORIGINAL_TARIFF_PAGE != V_TARIFF_PAGE OR V_ORIGINAL_PART_SECTION != V_PART_SECTION OR V_ORIGINAL_ITEM_NUMBER != V_ITEM_NUMBER OR V_ORIGINAL_CRTC_NUMBER != V_CRTC_NUMBER) 
									AND V_ORIGINAL_TARIFF_NAME = V_TARIFF_REFERENCE THEN
								INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Tariff Name','Tariff Page, Part Section, Item # or CRTC #  is not consistent with Tariff Name.');
							END IF;

							IF V_ORIGINAL_TARIFF_PAGE = V_TARIFF_PAGE AND V_ORIGINAL_PART_SECTION = V_PART_SECTION AND V_ORIGINAL_ITEM_NUMBER = V_ITEM_NUMBER AND V_ORIGINAL_CRTC_NUMBER = V_CRTC_NUMBER
									AND V_ORIGINAL_TARIFF_NAME != V_TARIFF_REFERENCE THEN
								INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Tariff Name','Tariff Page, Part Section, Item # or CRTC #  is not consistent with Tariff Name.');
							END IF;*/

							
							SELECT 
                rate_status, 
                audit_rate_period_id 
                  INTO 
                    V_RATE_STATUS, 
                    V_AUDIT_RATE_PERIOD_ID
              FROM rate_rule_tariff_original 
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

                  IF( IFNULL(STR_TO_DATE(V_RATE_EFFECTIVE_DATE, '%m/%d/%Y'),'') <= DATE_FORMAT(V_INACTIVE_MAX_EFFECTIVE_DATE, '%Y-%m-%d')) THEN

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

                  IF( IFNULL(STR_TO_DATE(V_RATE_EFFECTIVE_DATE, '%m/%d/%Y'),'') >= DATE_FORMAT(V_ACTIVE_EFFECTIVE_DATE, '%Y-%m-%d')) THEN

                    INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date','"Inactive Rate Effective Date" cannot be greater than or equals to "Active Rate Effective Date"');
                  END IF;

                END IF;
                
              END IF; -- Update rate status judgement end. 

						END IF;

						select count(1) INTO V_COUNT 
            from audit_key_field 
            where 
              audit_reference_type_id = 2 
              AND rec_active_flag = 'Y'
              AND key_field_original = V_KEY_FIELD;

						IF V_COUNT = 0 THEN
							INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Key Field*',concat(V_KEY_FIELD,' does not exist in TEMS.'));
						ELSE
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

							ELSEIF (LOCATE('Line Item Code',V_KEY_FIELD) = 0) THEN -- Key Field 不包含 'Line Item Code' 字样

							  IF ( IFNULL(V_LINE_ITEM_CODE_DESCRIPTION, '') != '' ) THEN
							    INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code Description',concat('Line Item Code Description has to be blank when Key Field is ',V_KEY_FIELD,'.'));
							  END IF;

							  IF ( IFNULL(V_LINE_ITEM_CODE, '') != '' ) THEN
							    INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code',concat('Line Item Code has to be blank when Key Field is ',V_KEY_FIELD,'.'));
							  END IF;

							END IF;

							IF ( LOCATE('Line Item Code Description',V_KEY_FIELD) > 0 ) THEN

							  IF ( IFNULL(V_LINE_ITEM_CODE_DESCRIPTION, '') = '' ) THEN
							    INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code Description',concat('Line Item Code Description cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
							  END IF;

							  IF ( IFNULL(V_LINE_ITEM_CODE, '') != '' ) THEN
							    INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code',concat('Line Item Code has to be blank when Key Field is ',V_KEY_FIELD,'.'));
							  END IF;

							  IF IFNULL(V_USOC_DESCRIPTION, '') != '' THEN
                  INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'USOC Description',concat('USOC Description has to be blank when Key Field is ',V_KEY_FIELD,'.'));
                END IF;

							END IF;



							select locate('Item Type',V_KEY_FIELD) INTO V_COUNT;
							IF V_COUNT > 0 THEN
								IF V_ITEM_TYPE IS NULL OR V_ITEM_TYPE = '' THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Item Type',concat('Item Type cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
								END IF;
							ELSE
								IF V_ITEM_TYPE IS NOT NULL AND V_ITEM_TYPE != '' THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Item Type',concat('Item Type has to be blank when Key Field is ',V_KEY_FIELD,'.'));
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


							select locate('Qty',V_KEY_FIELD) INTO V_COUNT;
							IF V_COUNT > 0 THEN
								SELECT (V_QUANTITY_BEGIN REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
								IF V_IS_NUMERICAL > 0 THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty Begin','ID must be a numerical type');
								END IF;
								SELECT (V_QUANTITY_END REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
								IF V_IS_NUMERICAL > 0 THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty End','ID must be a numerical type');
								END IF;
								IF V_QUANTITY_BEGIN IS NULL OR V_QUANTITY_BEGIN = '' THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty Begin',concat('Qty Begin cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
								ELSE
									IF V_QUANTITY_END IS NOT NULL AND V_QUANTITY_END != '' AND V_QUANTITY_BEGIN > V_QUANTITY_END THEN
										INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty End','"Qty End" has to be greater than "Qty Begin".');
									END IF;
								END IF;
							ELSE
								IF (V_QUANTITY_BEGIN IS NOT NULL AND V_QUANTITY_BEGIN != '') OR (V_QUANTITY_END IS NOT NULL AND V_QUANTITY_END != '') THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty End',concat('Qty Begin and Qty End have to be blank when Key Field is ',V_KEY_FIELD,'.'));
								END IF;
							END IF;

							select locate('Base Amount',V_KEY_FIELD) INTO V_COUNT;
							IF V_COUNT > 0 THEN
								SELECT (V_BASE_AMOUNT REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
								IF V_IS_NUMERICAL > 0 THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Base Amount','Base Amount must be a numerical type');
								END IF;

								IF V_BASE_AMOUNT IS NULL OR V_BASE_AMOUNT = '' THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Base Amount',concat('Base Amount cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
								END IF;
							ELSE
								IF V_BASE_AMOUNT IS NOT NULL AND V_BASE_AMOUNT != '' THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Base Amount',concat('Base Amount has to be blank when Key Field is ',V_KEY_FIELD,'.'));
								END IF;
							END IF;

							select locate('Multiplier',V_KEY_FIELD) INTO V_COUNT;
							IF V_COUNT > 0 THEN
								SELECT (V_MULTIPLIER REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
								IF V_IS_NUMERICAL > 0 THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Multiplier','Multiplier must be a numerical type');
								END IF;

								IF V_MULTIPLIER IS NULL OR V_MULTIPLIER = '' THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Multiplier',concat('Multiplier cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
								END IF;
							ELSE
								IF V_MULTIPLIER IS NOT NULL AND V_MULTIPLIER != '' THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Multiplier',concat('Multiplier has to be blank when Key Field is ',V_KEY_FIELD,'.'));
								END IF;
							END IF;

							select locate('Discount',V_KEY_FIELD) INTO V_COUNT;
							IF V_COUNT > 0 THEN
								SELECT (V_DISCOUNT REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
								IF V_IS_NUMERICAL > 0 THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Discount','Discount must be a numerical type');
								END IF;
								IF V_DISCOUNT IS NULL OR V_DISCOUNT = '' THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Discount',concat('Discount cannot be blank when Key Field is ',V_KEY_FIELD,'.'));
								END IF;
							ELSE
								IF V_DISCOUNT IS NOT NULL AND V_DISCOUNT != '' THEN
									INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Discount',concat('Discount has to be blank when Key Field is ',V_KEY_FIELD,'.'));
								END IF;
							END IF;

						END IF;
					END IF;

          IF V_RATE_EFFECTIVE_DATE IS NOT NULL AND V_RATE_EFFECTIVE_DATE != '' THEN 
            SELECT IFNULL(str_to_date(V_RATE_EFFECTIVE_DATE, '%m/%d/%Y'),'') INTO V_DATE;
            IF V_DATE IS NULL OR V_DATE = '' THEN 
              INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date','Rate Effective Date format must be "MM/DD/YYYY"');
            -- ELSEIF V_RATE_ID IS NOT NULL AND V_RATE_ID != '' AND V_RATE_ID != 0 AND V_DATE != V_ORIGINAL_EFFECTIVE_DATE THEN
							-- INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date','Cannot change Rate Effective Date, if you want to change, please contact the development team.');
						END IF;
						SELECT FN_VAIDATE_DATE_FIELD(V_RATE_EFFECTIVE_DATE) INTO V_IS_DATE;
						IF V_IS_DATE <= 0 THEN 
              INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date',concat("\"",V_RATE_EFFECTIVE_DATE,"\"",'is an invalid date value.'));
						END IF;
					ELSE
						INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate Effective Date','Rate Effective Date is required');
          END IF;
					
					IF V_CHARGE_TYPE IS NULL OR V_CHARGE_TYPE = '' THEN
						INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Charge Type %Contains%','Charge Type is required');
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

					IF V_VENDOR_NAME IS NULL OR V_VENDOR_NAME = '' THEN
						SET V_KEY_FIELD_IS_VN = (SELECT replace(V_KEY_FIELD,'SVN','') like "%VN%");
						IF V_KEY_FIELD_IS_VN >0 THEN
							INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Vendor Name (VN) %Contains%','Vendor Name is required');
						END IF;
					ELSE
						SELECT count(1) INTO V_COUNT from vendor where replace(vendor_name,' ','') = replace(replace(V_VENDOR_NAME,' ',''),'=','') and vendor_status_id = 1 and rec_active_flag = 'Y';
						IF V_COUNT <= 0 THEN 
							INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Vendor Name (VN) %Contains%',concat(V_VENDOR_NAME,' does not exist in TEMS.'));
						END IF;
						/*OPEN cur_vendor_item;
              read_loop1: LOOP
              FETCH cur_vendor_item INTO
                    V_CHILD_VENDOR_NAME;
              IF V_NOTFOUND THEN
                  LEAVE read_loop1;
              END IF;

							SELECT count(1) INTO V_COUNT from vendor where replace(vendor_name,' ','') = replace(replace(V_CHILD_VENDOR_NAME,' ',''),'=','') and vendor_status_id = 1 and rec_active_flag = 'Y';

              IF V_COUNT <= 0 THEN 
                INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Vendor Name (VN) %Contains%',concat(V_CHILD_VENDOR_NAME,' is not exist.'));
                LEAVE read_loop1;
              END IF;
            END LOOP;
            CLOSE cur_vendor_item;
            SET V_NOTFOUND = FALSE;*/

					END IF;

					IF V_TARIFF_FILE_NAME IS NULL OR V_TARIFF_FILE_NAME = '' THEN
						INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Tariff File Name','Tariff File Name is required');
					END IF;

					IF V_TARIFF_REFERENCE IS NULL OR V_TARIFF_REFERENCE = '' THEN
						INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Tariff Name','Tariff Name is required');
					END IF;

					IF V_RATE IS NULL OR V_RATE = '' THEN
						INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate','Rate is required');
					END IF;

					IF V_EXCLUSION_BAN IS NOT NULL AND V_EXCLUSION_BAN !='' THEN
						select count(1) INTO V_COUNT from ban b where account_number = V_EXCLUSION_BAN and b.ban_status_id = 1 and b.rec_active_flag = 'Y' and b.master_ban_flag = 'Y';
						IF V_COUNT = 0 THEN
							INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Exclusion Ban','"Exclusion BAN" has to be an active BAN in TEMS.');
						END IF;
					END IF;
          
          SELECT (V_RATE REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate','Rate must be a numerical type');
          END IF;
            
          SELECT (V_QUANTITY_BEGIN REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty Begin','Qty Begin must be a numerical type');
          END IF;
          
          SELECT (V_QUANTITY_END REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty End','Qty End must be a numerical type');
          END IF;
					
          SELECT (V_DISCOUNT REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Discount','Discount must be a numerical type');
          END IF;
          
          SELECT (V_BASE_AMOUNT REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Base Amount','Base Amount must be a numerical type');
          END IF;        
                  
          SELECT (V_MULTIPLIER REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL > 0 THEN
            INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Multiplier','Multiplier must be a numerical type');
          END IF;
					SELECT COUNT(1) INTO V_COUNT 
								FROM rate_rule_tariff_original
							 WHERE     rec_active_flag = 'Y'
										 AND id != IF(V_RATE_ID IS NOT NULL AND V_RATE_ID != '',V_RATE_ID,0)
										 AND charge_type = V_CHARGE_TYPE
										 AND key_field = V_KEY_FIELD
										 -- AND rate_effective_date = V_RATE_EFFECTIVE_DATE
										 AND str_to_date(date_format(rate_effective_date, '%m/%d/%Y'), '%m/%d/%Y') = str_to_date(V_RATE_EFFECTIVE_DATE, '%m/%d/%Y')
										 AND IFNULL(summary_vendor_name,'') = V_SUMMARY_VENDOR_NAME
										 AND IFNULL(vendor_name,'') = V_VENDOR_NAME
										 AND IFNULL(usoc,'') = V_USOC
										 AND IFNULL(usoc_description,'') = V_USOC_DESCRIPTION
										 AND IFNULL(sub_product,'') = V_SUB_PRODUCT
										 AND IFNULL(line_item_code_description,'') = V_LINE_ITEM_CODE_DESCRIPTION
										 AND IFNULL(line_item_code,'') = V_LINE_ITEM_CODE
										 AND IFNULL(item_type,'') = V_ITEM_TYPE
										 AND IFNULL(item_description,'') = V_ITEM_DESCRIPTION
										 AND IFNULL(quantity_begin,'') = 0+V_QUANTITY_BEGIN
										 AND IFNULL(quantity_end,'') = 0+V_QUANTITY_END
										 AND IFNULL(tariff_file_name,'') = V_TARIFF_FILE_NAME
										 AND IFNULL(tariff_name,'') = V_TARIFF_REFERENCE
										 AND IFNULL(base_amount,'') = 0+V_BASE_AMOUNT
										 AND IFNULL(multiplier,'') = 0+V_MULTIPLIER
										 AND IFNULL(rate,'') = 0+V_RATE
										 AND IFNULL(discount,'') = 0+V_DISCOUNT
										 AND IFNULL(tariff_page,'') = V_TARIFF_PAGE
										 AND IFNULL(part_section,'') = V_PART_SECTION
										 AND IFNULL(item_number,'') = V_ITEM_NUMBER
										 AND IFNULL(crtc_number,'') = V_CRTC_NUMBER;
					IF V_COUNT > 0 THEN
						INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'ID','This record already exists in TEMS.');
					END IF;

					SELECT COUNT(1) INTO V_COUNT 
								FROM rate_rule_tariff_master_import
							 WHERE     id != V_ID
										 AND batch_no = V_BATCH_NO
										 AND charge_type = V_CHARGE_TYPE
										 AND key_field = V_KEY_FIELD
										 AND str_to_date(date_format(rate_effective_date, '%m/%d/%Y'), '%m/%d/%Y') = str_to_date(V_RATE_EFFECTIVE_DATE, '%m/%d/%Y')
										 AND IFNULL(summary_vendor_name,'') = V_SUMMARY_VENDOR_NAME
										 AND IFNULL(vendor_name,'') = V_VENDOR_NAME
										 AND IFNULL(usoc,'') = V_USOC
										 AND IFNULL(usoc_description,'') = V_USOC_DESCRIPTION
										 AND IFNULL(sub_product,'') = V_SUB_PRODUCT
										 AND IFNULL(line_item_code_description,'') = V_LINE_ITEM_CODE_DESCRIPTION
										 AND IFNULL(line_item_code,'') = V_LINE_ITEM_CODE
										 AND IFNULL(item_type,'') = V_ITEM_TYPE
										 AND IFNULL(item_description,'') = V_ITEM_DESCRIPTION
										 AND IFNULL(quantity_begin,'') = V_QUANTITY_BEGIN
										 AND IFNULL(quantity_end,'') = V_QUANTITY_END
										 AND IFNULL(tariff_file_name,'') = V_TARIFF_FILE_NAME
										 AND IFNULL(tariff_reference,'') = V_TARIFF_REFERENCE
										 AND IFNULL(base_amount,'') = V_BASE_AMOUNT
										 AND IFNULL(multiplier,'') = V_MULTIPLIER
										 AND IFNULL(rate,'') = V_RATE
										 AND IFNULL(discount,'') = V_DISCOUNT
										 AND IFNULL(tariff_page,'') = V_TARIFF_PAGE
										 AND IFNULL(part_section,'') = V_PART_SECTION
										 AND IFNULL(item_number,'') = V_ITEM_NUMBER
										 AND IFNULL(crtc_number,'') = V_CRTC_NUMBER;
					IF V_COUNT > 0 THEN
						INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'ID','This record already exists in TEMS.');
					END IF;

			  ELSE
					SELECT (V_RATE_ID REGEXP '[^0-9.]') INTO V_IS_NUMERICAL;
          IF V_IS_NUMERICAL <= 0 THEN
						INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'ID','This key does not exist in rate.');
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
		INSERT INTO rate_rule_tariff_master_batch(rate_id,
																		 batch_no,
																		 row_no,
																		 user_id,
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
																		 pdf_page,
																		 part_section,
																		 item_number,
																		 crtc_number,
																		 discount,
																		 exclusion_ban,
																		 exclusion_item_description,
																		 notes)
		SELECT IF(rate_id!='',rate_id,NULL),
					 batch_no,
					 row_no,
					 user_id,
					 IF(charge_type!='',charge_type,NULL),
					 IF(key_field!='',key_field,NULL),
					 IF(rate_effective_date!='',str_to_date(rate_effective_date,'%m/%d/%Y'),NULL),
					 IF(summary_vendor_name!='',summary_vendor_name,NULL),
					 IF(vendor_name!='',vendor_name,NULL),
					 IF(usoc!='',usoc,NULL),
					 IF(usoc_description!='',usoc_description,NULL),
					 IF(sub_product!='',sub_product,NULL),
					 IF(line_item_code_description!='',line_item_code_description,NULL),
					 IF(line_item_code!='',line_item_code,NULL),
					 IF(item_type!='',item_type,NULL),
					 IF(item_description!='',item_description,NULL),
					 IF(quantity_begin!='',quantity_begin,NULL),
					 IF(quantity_end!='',quantity_end,NULL),
					 IF(tariff_file_name!='',tariff_file_name,NULL),
					 IF(tariff_reference!='',tariff_reference,NULL),
					 IF(base_amount!='',base_amount,NULL),
					 IF(multiplier!='',multiplier,NULL),
					 IF(rate!='',rate,NULL),
					 IF(rules_details!='',rules_details,NULL),
					 IF(tariff_page!='',tariff_page,NULL),
					 IF(pdf_page!='',pdf_page,NULL),
					 IF(part_section!='',part_section,NULL),
					 IF(item_number!='',item_number,NULL),
					 IF(crtc_number!='',crtc_number,NULL),
					 IF(discount!='',discount,NULL),
					 IF(exclusion_ban!='',exclusion_ban,NULL),
					 IF(exclusion_item_descripton!='',exclusion_item_descripton,NULL),
					 IF(notes!='',notes,NULL)
     FROM rate_rule_tariff_master_import WHERE batch_no = V_BATCH_NO;
		 CALL SP_UPDATE_TARIFF_MASTER_DATA_TO_RATE_MODULE_TABLES(V_BATCH_NO);
  END IF;
  -- DELETE FROM rate_rule_tariff_master_import WHERE batch_no = V_BATCH_NO;
END;
