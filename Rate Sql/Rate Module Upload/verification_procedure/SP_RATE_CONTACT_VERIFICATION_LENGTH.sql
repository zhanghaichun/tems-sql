DROP PROCEDURE IF EXISTS ccm_db.SP_RATE_CONTACT_VERIFICATION_LENGTH;
CREATE PROCEDURE ccm_db.`SP_RATE_CONTACT_VERIFICATION_LENGTH`(V_BATCH_NO VARCHAR(64))
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
	DECLARE 	V_RENEWAL_TERM_AFTER_TERM_EXPIRATION	MEDIUMTEXT;
	DECLARE 	V_EARLY_TERMINATION_FEE	MEDIUMTEXT;
	DECLARE 	V_CONTRACT_NAME	MEDIUMTEXT;
	DECLARE 	V_CONTRACT_SERVICE_SCHEDULE_NAME	MEDIUMTEXT;
	DECLARE 	V_TOTAL_VOLUME_BEGIN	MEDIUMTEXT;
	DECLARE 	V_TOTAL_VOLUME_END	MEDIUMTEXT;
	DECLARE 	V_MMBC	MEDIUMTEXT;
	DECLARE 	V_DISCOUNT	MEDIUMTEXT;
	DECLARE 	V_NOTES	MEDIUMTEXT;


	DECLARE V_ROW_NUMBER INT;
	DECLARE V_NOTFOUND INT DEFAULT FALSE;
	DECLARE v_commit_count INT DEFAULT 0;

	DECLARE cur_rate_length_item CURSOR FOR
			SELECT row_no,
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
				FROM rate_contact_length_import
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
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'USOC Description','The maximum characters of USOC Description is 255');
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
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Term (Months)','The maximum characters of Term (Months) is 15');
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

				IF LENGTH(V_RENEWAL_TERM_AFTER_TERM_EXPIRATION) > 16 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Renewal Term after Term Expiration','The maximum characters of Renewal Term after Term Expiration is 16');
				END IF;

				IF LENGTH(V_EARLY_TERMINATION_FEE) > 255 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Early Termination Fee','The maximum characters of Early Termination Fee is 255');
				END IF;

				IF LENGTH(V_CONTRACT_NAME) > 500 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Contract Name','The maximum characters of Contract Name is 500');
				END IF;

				IF LENGTH(V_CONTRACT_SERVICE_SCHEDULE_NAME) > 128 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Contract Service Schedule Name','The maximum characters of Contract Service Schedule Name is 128');
				END IF;

				IF LENGTH(V_TOTAL_VOLUME_BEGIN) > 11 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty Begin','The maximum length number of Qty Begin is 11');
				END IF;

				IF LENGTH(V_TOTAL_VOLUME_END) > 11 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Qty End','The maximum length number of Qty End is 11');
				END IF;

				IF LENGTH(V_MMBC) > 32 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'MMBC','The maximum characters of MMBC is 32');
				END IF;

				IF LENGTH(V_DISCOUNT) > 18 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Discount %','The maximum length number of Discount % is 15');
				END IF;

				IF LENGTH(V_NOTES) > 500 THEN
					INSERT INTO tmp_rate_error (row_number,field,note) VALUES (V_ROW_NUMBER,'Notes','The maximum characters of Notes is 500');
				END IF;

				SET v_commit_count = v_commit_count + 1;
         IF (v_commit_count % 100 = 0) THEN
            commit;
         END IF;

		END LOOP;
    
	CLOSE cur_rate_length_item;
	commit;
   set autocommit = 1;

	INSERT INTO rate_rule_contact_master_import(rate_id,
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
   SELECT  rate_id,
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
       			notes
     FROM rate_contact_length_import WHERE batch_no = V_BATCH_NO;
     -- DELETE FROM rate_contact_length_import WHERE batch_no = V_BATCH_NO;
  
END;
