DROP PROCEDURE IF EXISTS ccm_db.SP_RATE_VERIFICATION_LENGTH;
CREATE PROCEDURE ccm_db.`SP_RATE_VERIFICATION_LENGTH`(V_BATCH_NO VARCHAR(64))

BEGIN
	DECLARE V_RATE_ID VARCHAR(32);
	DECLARE V_BAN_ID INT;
	DECLARE V_USER_ID INT;
	DECLARE 	V_CHARGE_TYPE	MEDIUMTEXT;
	DECLARE 	V_KEY_FIELD	MEDIUMTEXT;
	DECLARE 	V_RATE_EFFECTIVE_DATE	MEDIUMTEXT;
	DECLARE 	V_SUMMARY_VENDOR_NAME	MEDIUMTEXT;
	DECLARE 	V_VENDOR_NAME	MEDIUMTEXT;
	DECLARE 	V_USOC	MEDIUMTEXT;
	DECLARE 	V_USOC_DESCRIPTION	MEDIUMTEXT;
	DECLARE 	V_SUB_PRODUCT	MEDIUMTEXT;
	DECLARE 	V_LINE_ITEM_CODE_DESCRIPTION	MEDIUMTEXT;
	DECLARE 	V_LINE_ITEM_CODE	MEDIUMTEXT;
	DECLARE 	V_ITEM_TYPE	MEDIUMTEXT;
	DECLARE 	V_ITEM_DESCRIPTION	MEDIUMTEXT;
	DECLARE 	V_QUANTITY_BEGIN	MEDIUMTEXT;
	DECLARE 	V_QUANTITY_END	MEDIUMTEXT;
	DECLARE 	V_TARIFF_FILE_NAME	MEDIUMTEXT;
	DECLARE 	V_TARIFF_REFERENCE	MEDIUMTEXT;
	DECLARE 	V_BASE_AMOUNT	MEDIUMTEXT;
	DECLARE 	V_MULTIPLIER	MEDIUMTEXT;
	DECLARE 	V_RATE	MEDIUMTEXT;
	DECLARE 	V_RULES_DETAILS	MEDIUMTEXT;
	DECLARE 	V_TARIFF_PAGE	MEDIUMTEXT;
	DECLARE 	V_PDF_PAGE	MEDIUMTEXT;
	DECLARE 	V_PART_SECTION	MEDIUMTEXT;
	DECLARE 	V_ITEM_NUMBER	MEDIUMTEXT;
	DECLARE 	V_CRTC_NUMBER	MEDIUMTEXT;
	DECLARE 	V_DISCOUNT	MEDIUMTEXT;
	DECLARE 	V_EXCLUSION_BAN	MEDIUMTEXT;
	DECLARE 	V_EXCLUSION_ITEM_DESCRIPTON	MEDIUMTEXT;
	DECLARE 	V_NOTES	MEDIUMTEXT;
	DECLARE 	V_BILL_KEEP_BAN MEDIUMTEXT;
	DECLARE 	V_IMBALANCE_START	MEDIUMTEXT;
	DECLARE 	V_IMBALANCE_END MEDIUMTEXT;
	DECLARE 	V_PROVINCE MEDIUMTEXT;
	DECLARE 	V_PROVIDER MEDIUMTEXT;

	DECLARE V_ROW_NUMBER INT;
	DECLARE V_NOTFOUND INT DEFAULT FALSE;
	DECLARE v_commit_count INT DEFAULT 0;

	DECLARE cur_rate_length_item CURSOR FOR
			SELECT row_no,
						IFNULL(charge_type,''),
						IFNULL(key_field,''),
						IFNULL(rate_effective_date,''),
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
						IFNULL(notes,''),
						IFNULL(bill_keep_ban,''),
						IFNULL(province,''),
						IFNULL(provider,''),
						IFNULL(imbalance_start,''),
						IFNULL(imbalance_end,'')

				FROM rate_length_import
				WHERE batch_no = V_BATCH_NO;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_NOTFOUND = TRUE;

	DROP TABLE IF EXISTS tmp_rate_error;
	CREATE TEMPORARY TABLE tmp_rate_error (
		row_number int(11),
		field VARCHAR(64),
		note VARCHAR(768)
	);

	set autocommit = 0; 
	OPEN cur_rate_length_item;
		read_loop: LOOP
        FETCH cur_rate_length_item INTO
						V_ROW_NUMBER,
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
						V_NOTES,
						V_BILL_KEEP_BAN,
						V_PROVINCE,
						V_PROVIDER,
						V_IMBALANCE_START,
						V_IMBALANCE_END;
        IF V_NOTFOUND THEN
            LEAVE read_loop;
        END IF;

				IF LENGTH(V_CHARGE_TYPE) > 12 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Charge Type %Contains%','The maximum characters of Charge Type %Contains% is 12');
				END IF;

				IF LENGTH(V_KEY_FIELD) > 64 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Key Field*','The maximum characters of Key Field* is 64');
				END IF;

				IF LENGTH(V_SUMMARY_VENDOR_NAME) > 128 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Summary Vendor Name (SVN) %Contains%','The maximum characters of Summary Vendor Name is 128');
				END IF;

				IF LENGTH(V_VENDOR_NAME) > 128 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Vendor Name (VN) %Contains%','The maximum characters of Vendor Name is 128');
				END IF;

				IF LENGTH(V_USOC) > 16 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'USOC','The maximum characters of USOC is 16');
				END IF;

				IF LENGTH(V_USOC_DESCRIPTION) > 255 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'USOC Description','The maximum characters of USOC Description is 255');
				END IF;

				IF LENGTH(V_SUB_PRODUCT) > 128 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Sub Product','The maximum characters of Sub Product is 128');
				END IF;

				IF LENGTH(V_LINE_ITEM_CODE_DESCRIPTION) > 255 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code Description','The maximum characters of Line Item Code Description is 255');
				END IF;

				IF LENGTH(V_LINE_ITEM_CODE) > 64 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code','The maximum characters of Line Item Code is 64');
				END IF;

				IF LENGTH(V_ITEM_TYPE) > 64 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Item Type','The maximum characters of Item Type is 64');
				END IF;

				IF LENGTH(V_ITEM_DESCRIPTION) > 128 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Item Description','The maximum characters of Item Description is 128');
				END IF;

				IF LENGTH(V_QUANTITY_BEGIN) > 11 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty Begin','The maximum length number of Qty Begin is 11');
				END IF;

				IF LENGTH(V_QUANTITY_END) > 11 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty End','The maximum length number of Qty End is 11');
				END IF;

				IF LENGTH(V_TARIFF_FILE_NAME) > 42 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Tariff File Name','The maximum characters of Tariff File Name is 42');
				END IF;

				IF LENGTH(V_TARIFF_REFERENCE) > 500 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Tariff Name','The maximum characters of Tariff Name is 500');
				END IF;

				IF LENGTH(V_BASE_AMOUNT) > 11 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Base Amount','The maximum length number of Base Amount is 11');
				END IF;

				IF LENGTH(V_MULTIPLIER) > 18 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Multiplier','The maximum length number of Multiplier is 15');
				END IF;

				IF LENGTH(V_RATE) > 18 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate','The maximum length number of Rate is 15');
				END IF;

				IF LENGTH(V_RULES_DETAILS) > 500 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Details from Tariff','The maximum characters of Details from Tariff is 500');
				END IF;

				IF LENGTH(V_TARIFF_PAGE) > 32 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Tariff Page','The maximum characters of Tariff Page is 32');
				END IF;

				IF LENGTH(V_PDF_PAGE) > 16 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'PDF Page','The maximum characters of PDF Page is 16');
				END IF;

				IF LENGTH(V_PART_SECTION) > 32 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Part Section','The maximum characters of Part Section is 32');
				END IF;

				IF LENGTH(V_ITEM_NUMBER) > 32 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Item #','The maximum characters of Item # is 32');
				END IF;

				IF LENGTH(V_CRTC_NUMBER) > 12 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'CRTC #','The maximum characters of CRTC # is 12');
				END IF;

				IF LENGTH(V_DISCOUNT) > 18 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Discount','The maximum length number of Discount is 15');
				END IF;

				IF LENGTH(V_EXCLUSION_BAN) > 32 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Exclusion Ban','The maximum characters of Exclusion Ban is 32');
				END IF;

				IF LENGTH(V_EXCLUSION_ITEM_DESCRIPTON) > 256 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Exclusion Item Description','The maximum characters of Exclusion Item Description is 256');
				END IF;

				IF LENGTH(V_NOTES) > 500 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Notes','The maximum characters of Notes is 500');
				END IF;

				IF LENGTH(V_BILL_KEEP_BAN) > 64 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Bill Keep Ban','The maximum characters of Bill Keep Ban is 64');
				END IF;

				IF LENGTH(V_PROVINCE) > 16 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Province','The maximum characters of Province is 16');
				END IF;

				IF LENGTH(V_PROVIDER) > 16 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Provider','The maximum characters of Provider is 64');
				END IF;

				IF LENGTH(V_IMBALANCE_START) > 20 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Imbalance Start (%)','The maximum characters of Provider is 64');
				END IF;

				IF LENGTH(V_IMBALANCE_END) > 20 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Imbalance End (%)','The maximum characters of Provider is 64');
				END IF;



				SET v_commit_count = v_commit_count + 1;
         IF (v_commit_count % 100 = 0) THEN
            commit;
         END IF;

		END LOOP;
    
	CLOSE cur_rate_length_item;
	commit;
   set autocommit = 1;

	INSERT INTO rate_rule_tariff_master_import(rate_id,
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
																		 tariff_reference,
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
																		 exclusion_item_descripton,
																		 notes,
																		bill_keep_ban,
																		province,
																		provider,
																		imbalance_start,
																		imbalance_end)
   SELECT  rate_id,
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
					 tariff_reference,
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
					 exclusion_item_descripton,
					 notes,
					bill_keep_ban,
					province,
					provider,
					imbalance_start,
					imbalance_end
     FROM rate_length_import WHERE batch_no = V_BATCH_NO;
     DELETE FROM rate_length_import WHERE batch_no = V_BATCH_NO;
  
END