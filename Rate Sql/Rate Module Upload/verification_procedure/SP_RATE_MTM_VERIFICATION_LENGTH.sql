DROP PROCEDURE IF EXISTS ccm_db.SP_RATE_MTM_VERIFICATION_LENGTH;
CREATE PROCEDURE ccm_db.`SP_RATE_MTM_VERIFICATION_LENGTH`(V_BATCH_NO VARCHAR(64))
BEGIN
	DECLARE V_RATE_ID VARCHAR(32);
	DECLARE V_BAN_ID INT;
	DECLARE V_USER_ID INT;
	DECLARE 	V_CHARGE_TYPE	MEDIUMTEXT;
	DECLARE 	V_KEY_FIELD	MEDIUMTEXT;
	DECLARE 	V_EFFECTIVE_DATE	MEDIUMTEXT;
	DECLARE 	V_SUMMARY_VENDOR_NAME	MEDIUMTEXT;
	DECLARE 	V_STRIPPED_CIRCUIT_NUMBER	MEDIUMTEXT;
	DECLARE 	V_USOC	MEDIUMTEXT;
	DECLARE 	V_USOC_LONG_DESCRIPTION	MEDIUMTEXT;
	DECLARE 	V_SUB_PRODUCT	MEDIUMTEXT;
	DECLARE 	V_TERM	MEDIUMTEXT;
	DECLARE 	V_LINE_ITEM_CODE_DESCRIPTION	MEDIUMTEXT;
	DECLARE 	V_LINE_ITEM_CODE	MEDIUMTEXT;
	DECLARE 	V_ITEM_DESCRIPTION	MEDIUMTEXT;
	DECLARE 	V_RATE	MEDIUMTEXT;

	DECLARE V_ROW_NUMBER INT;
	DECLARE V_NOTFOUND INT DEFAULT FALSE;
	DECLARE v_commit_count INT DEFAULT 0;

	DECLARE cur_rate_length_item CURSOR FOR
			SELECT row_no,
						IFNULL(charge_type,''),
						IFNULL(summary_vendor_name,''),
						IFNULL(key_field,''),
						IFNULL(usoc,''),
						IFNULL(usoc_long_description,''),
						IFNULL(stripped_circuit_number,''),
						IFNULL(sub_product,''),
						IFNULL(rate,''),
						IFNULL(effective_date,''),
						IFNULL(term,''),
						IFNULL(item_description,''),
						IFNULL(line_item_code,''),
						IFNULL(line_item_code_description,'')

				FROM rate_mtm_length_import
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
						V_SUMMARY_VENDOR_NAME,
						V_KEY_FIELD,
						V_USOC,
						V_USOC_LONG_DESCRIPTION,
						V_STRIPPED_CIRCUIT_NUMBER,
						V_SUB_PRODUCT,
						V_RATE,
						V_EFFECTIVE_DATE,
						V_TERM,
						V_ITEM_DESCRIPTION,
						V_LINE_ITEM_CODE,
						V_LINE_ITEM_CODE_DESCRIPTION;
        IF V_NOTFOUND THEN
            LEAVE read_loop;
        END IF;

				IF LENGTH(V_CHARGE_TYPE) > 12 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Charge Type','The maximum characters of Charge Type is 12');
				END IF;

				IF LENGTH(V_KEY_FIELD) > 64 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Key Field*','The maximum characters of Key Field* is 64');
				END IF;

				IF LENGTH(V_SUMMARY_VENDOR_NAME) > 128 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Summary Vendor Name (SVN) %Contains%','The maximum characters of Summary Vendor Name is 128');
				END IF;

				IF LENGTH(V_USOC) > 16 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'USOC','The maximum characters of USOC is 16');
				END IF;

				IF LENGTH(V_USOC_LONG_DESCRIPTION) > 255 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'USOC Long Description','The maximum characters of USOC Long Description is 255');
				END IF;

				IF LENGTH(V_STRIPPED_CIRCUIT_NUMBER) > 128 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Stripped Circuit Number','The maximum characters of Stripped Circuit Number is 128');
				END IF;

				IF LENGTH(V_SUB_PRODUCT) > 128 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Sub Product','The maximum characters of Sub Product is 128');
				END IF;

				IF LENGTH(V_RATE) > 18 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Rate','The maximum length number of Rate is 15');
				END IF;

				IF LENGTH(V_TERM) > 32 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Term','The maximum characters of Term is 32');
				END IF;

				IF LENGTH(V_ITEM_DESCRIPTION) > 128 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Item Description','The maximum characters of Item Description is 128');
				END IF;

				IF LENGTH(V_LINE_ITEM_CODE_DESCRIPTION) > 255 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code Description','The maximum characters of Line Item Code Description is 255');
				END IF;

				IF LENGTH(V_LINE_ITEM_CODE) > 64 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Line Item Code','The maximum characters of Line Item Code is 64');
				END IF;


				SET v_commit_count = v_commit_count + 1;
         IF (v_commit_count % 100 = 0) THEN
            commit;
         END IF;

		END LOOP;
    
	CLOSE cur_rate_length_item;
	commit;
   set autocommit = 1;

	INSERT INTO rate_rule_mtm_master_import(rate_id,
																		 batch_no,
																		 row_no,
																		 user_id,
																		 charge_type,
																		summary_vendor_name,
																		key_field,
																		usoc,
																		usoc_long_description,
																		stripped_circuit_number,
																		sub_product,
																		rate,
																		effective_date,
																		term,
																		item_description,
																		line_item_code,
																		line_item_code_description)
   SELECT  rate_id,
					 batch_no,
					 row_no,
					 user_id,
					 charge_type,
					summary_vendor_name,
					key_field,
					usoc,
					usoc_long_description,
					stripped_circuit_number,
					sub_product,
					rate,
					effective_date,
					term,
					item_description,
					line_item_code,
					line_item_code_description
     FROM rate_mtm_length_import WHERE batch_no = V_BATCH_NO;
     DELETE FROM rate_mtm_length_import WHERE batch_no = V_BATCH_NO;
  
END;
