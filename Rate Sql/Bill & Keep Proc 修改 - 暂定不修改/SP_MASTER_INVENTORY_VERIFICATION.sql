DROP PROCEDURE IF EXISTS SP_MASTER_INVENTORY_VERIFICATION;
CREATE PROCEDURE SP_MASTER_INVENTORY_VERIFICATION(V_BATCH_NO VARCHAR(64))
BEGIN

  /**
   * 此程序是用来验证上传的 master_inventory 数据的有效性，其中包含对多个字段的输入约束。
   * 1. 如果向 master_inventory 表中插入数据， 那么 key 的值必须为 NULL
   */
  
  DECLARE V_COUNT INT;
  DECLARE V_USER_ID INT;
  DECLARE V_VENDOR_ID INT;
  DECLARE V_BAN_ID INT;
  DECLARE V_ROW_NUMBER INT;
  DECLARE V_MAX_LENGTH INT DEFAULT 10000;
  DECLARE V_VENDOR_NAME VARCHAR(128);
  DECLARE V_ACCOUNT_NUMBER VARCHAR(128);
  DECLARE V_MASTER_INVENTORY_ID VARCHAR(64);
  DECLARE V_TMP_MASTER_INVENTORY_ID INT;

  DECLARE V_SUMMARY_VENDOR_NAME VARCHAR(128);
  DECLARE V_INSTALLATION_DATE VARCHAR(64);
  DECLARE V_DISCONNECTION_DATE VARCHAR(64);
  DECLARE V_RATE_EFFECTIVE_DATE VARCHAR(64);
  DECLARE V_COST_TYPE VARCHAR(64);
  DECLARE V_CIRCUIT_STATUS VARCHAR(64);
  DECLARE V_COMPLETE_FLAG VARCHAR(1);


  DECLARE V_STRIPPED_CIRCUIT_NUMBER VARCHAR(128);
  DECLARE V_TYPE VARCHAR(64);
  DECLARE V_DATE VARCHAR(64);
  DECLARE V_ADDRESS VARCHAR(255);
  DECLARE V_A_STREET_NAME VARCHAR(128);
  DECLARE V_A_CITY VARCHAR(128);
  DECLARE V_A_POSTAL_CODE VARCHAR(128);
  DECLARE V_A_PROVINCE VARCHAR(128);
  DECLARE V_A_COUNTRY VARCHAR(128);

  DECLARE V_RATE VARCHAR(255);
  DECLARE V_END_USER VARCHAR(255);
  DECLARE V_SERVICE_ID VARCHAR(255);

  DECLARE V_IS_NUM INT DEFAULT 0;
  DECLARE V_NOTFOUND INT DEFAULT FALSE;

  DECLARE V_EMAIL_NOTFOUND INT DEFAULT FALSE;
  DECLARE v_commit_count INT DEFAULT 0;
  DECLARE V_BAN_SUMMARY_VENDOR_NAME VARCHAR(128);

  DECLARE V_OLD_VENDOR_NAME VARCHAR(255);
  DECLARE V_OLD_BAN VARCHAR(255);
  DECLARE V_OLD_LATEST_INVOICE_NUMBER VARCHAR(255);
  DECLARE V_OLD_LINE_OF_BUSINESS VARCHAR(255);
  DECLARE V_OLD_REVENUE_MATCH_DATE VARCHAR(255);
  DECLARE V_OLD_SERVICE_ID_MATCH_STATUS VARCHAR(255);
  DECLARE V_OLD_ACCESS_TYPE VARCHAR(255);
  DECLARE V_OLD_LAST_SIGNOFF_DATE VARCHAR(255);
  DECLARE V_OLD_USOC VARCHAR(255);
  DECLARE V_OLD_TARIFF VARCHAR(255);
  DECLARE V_OLD_AGREEMENT_TYPE VARCHAR(255);
  DECLARE V_OLD_RATE_DISCREPANCY VARCHAR(255);
  DECLARE V_OLD_TERMINATION_PENALTY_AMOUNT VARCHAR(255);

  DECLARE V_NEW_VENDOR_NAME VARCHAR(256);
  DECLARE V_NEW_BAN VARCHAR(256);
  DECLARE V_NEW_LATEST_INVOICE_NUMBER VARCHAR(256);
  DECLARE V_NEW_LINE_OF_BUSINESS VARCHAR(256);
  DECLARE V_NEW_REVENUE_MATCH_DATE VARCHAR(256);
  DECLARE V_NEW_SERVICE_ID_MATCH_STATUS VARCHAR(256);
  DECLARE V_NEW_ACCESS_TYPE VARCHAR(256);
  DECLARE V_NEW_LAST_SIGNOFF_DATE VARCHAR(256);
  DECLARE V_NEW_USOC VARCHAR(256);
  DECLARE V_NEW_TARIFF VARCHAR(256);
  DECLARE V_NEW_AGREEMENT_TYPE VARCHAR(256);
  DECLARE V_NEW_RATE_DISCREPANCY VARCHAR(256);
  DECLARE V_NEW_TERMINATION_PENALTY_AMOUNT VARCHAR(256);


  DECLARE V_LATEST_INVOICE_NUMBER VARCHAR(255);
  DECLARE V_LINE_OF_BUSINESS VARCHAR(255);
  DECLARE V_LASTEST_INVOICE_DATE VARCHAR(255);
  DECLARE V_REVENUE_MATCH_DATE VARCHAR(255);
  DECLARE V_SERVICE_ID_MATCH_STATUS VARCHAR(255);
  DECLARE V_ACCESS_TYPE VARCHAR(255);
  DECLARE V_FIRST_INVOICE_DATE VARCHAR(255);
  DECLARE V_FIRST_INVOICE_NUMBER VARCHAR(255);
  DECLARE V_LAST_SIGNOFF_DATE VARCHAR(255);
  DECLARE V_USOC VARCHAR(255);
  DECLARE V_TARIFF VARCHAR(255);
  DECLARE V_AGREEMENT_TYPE VARCHAR(255);
  DECLARE V_RATE_DISCREPANCY VARCHAR(255);
  DECLARE V_TERMINATION_PENALTY_AMOUNT VARCHAR(255);

  DECLARE V_MI_SUMMARY_VENDOR_NAME VARCHAR(128);
  DECLARE V_MI_BAN VARCHAR(128);
  DECLARE V_ORDER_NUMBER VARCHAR(128);

  DECLARE V_OWNER_EMAIL VARCHAR(128);
  DECLARE V_IS_EMAIL INT DEFAULT 0;
  DECLARE V_EMAIL VARCHAR(255);

  DECLARE V_SPECIAL_DIFFERENCE VARCHAR(768);
  
  DECLARE cur_email_item CURSOR FOR
      SELECT substring_index(
          substring_index(V_OWNER_EMAIL, ',', b.help_topic_id + 1),
                        ',',
                        -1)
                FROM mysql.help_topic b
               WHERE b.help_topic_id <
                        (  length(V_OWNER_EMAIL)
                         - length(replace(V_OWNER_EMAIL, ',', ''))
                         + 1);

  DECLARE cur_master_item CURSOR FOR
      SELECT t.row_no,
             t.id,
             IFNULL(t.vendor_name, ''),
             IFNULL(t.ban, ''),
             IFNULL(t.master_inventory_id, ''),
             IFNULL(t.summary_vendor_name, ''),
             IFNULL(t.stripped_circuit_number, ''),
             IFNULL(t.cost_type, ''),
             IFNULL(t.status, ''),
             IFNULL(t.a_street_number, ''),
             IFNULL(t.a_street_name, ''),
             IFNULL(t.a_city, ''),
             IFNULL(t.a_postal_code, ''),
             IFNULL(t.a_province, ''),
             IFNULL(t.a_country, ''),
             IFNULL(t.rate, ''),
             IFNULL(t.end_user, ''),
             IFNULL(t.rate_effective_date, ''),
             IFNULL(t.installation_date, ''),
             IFNULL(t.disconnection_date, ''),
             IFNULL(t.service_id, ''),
             IFNULL(t.summary_vendor_name, ''),
             (SELECT IFNULL(v.summary_vendor_name, '')
                FROM vendor v
               WHERE v.id = m.vendor_id),
             IFNULL(t.ban, ''),
             (SELECT IFNULL(b.account_number, '')
                FROM ban b
               WHERE b.id = m.ban_id),
             IFNULL(t.line_of_business, ''),
             (SELECT IFNULL(b.line_of_business, '')
                FROM ban b
               WHERE b.id = m.ban_id),
             IFNULL(t.revenue_match_date, ''),
             IFNULL(m.revenue_match_date, ''),
             IFNULL(t.service_id_match_status, ''),
             IFNULL(m.service_id_match_status, ''),
             IFNULL(t.type, ''),
             IFNULL(m.access_type, ''),
             IFNULL(t.last_signoff_date, ''),
             IFNULL(m.last_signoff_date, ''),
             IFNULL(t.usoc, ''),
             IFNULL(m.usoc, ''),
             IFNULL(t.tariff, ''),
             IFNULL(tariff_name, ''),
             IFNULL(t.agreement_type, ''),
             IFNULL(m.agreement_type, ''),
             IFNULL(t.rate_discrepancy_flag, ''),
             IFNULL(m.rate_discrepancy_flag, ''),
             IFNULL(t.termination_penalty_amount, ''),
             IFNULL(m.termination_penalty_percentage, ''),
             IFNULL((SELECT IFNULL(i.invoice_number, '')
                       FROM invoice i
                      WHERE i.id = m.latest_invoice_id),
                    'blank'),
             IFNULL((SELECT IFNULL(b.line_of_business, '')
                       FROM ban b
                      WHERE b.id = m.ban_id),
                    'blank'),
             IFNULL((SELECT IFNULL(i.invoice_date, '')
                       FROM invoice i
                      WHERE i.id = m.latest_invoice_id),
                    'blank'),
             IFNULL(m.revenue_match_date, 'blank'),
             IFNULL(m.service_id_match_status, 'blank'),
             IFNULL(m.access_type, 'blank'),
             IFNULL((SELECT IFNULL(i.invoice_date, '')
                       FROM invoice i
                      WHERE i.id = m.first_invoice_id),
                    'blank'),
             IFNULL((SELECT IFNULL(i.invoice_number, '')
                       FROM invoice i
                      WHERE i.id = m.first_invoice_id),
                    'blank'),
             IFNULL(m.last_signoff_date, 'blank'),
             IFNULL(m.usoc, 'blank'),
             IFNULL(m.tariff_name, 'blank'),
             IFNULL(m.agreement_type, 'blank'),
             IFNULL(m.rate_discrepancy_flag, 'blank'),
             IFNULL(m.termination_penalty_percentage, 'blank'),
             IFNULL((SELECT IFNULL(v.summary_vendor_name, '')
                       FROM vendor v
                      WHERE v.id = m.vendor_id),
                    ''),
             IFNULL((SELECT IFNULL(b.account_number, '')
                       FROM ban b
                      WHERE b.id = m.ban_id),
                    ''),
             IFNULL(replace(t.owner_email, ';', ','), ''),
             IFNULL(t.order_number, '')
        FROM master_inventory_import t
             LEFT JOIN master_inventory m ON t.master_inventory_id = m.id
        where t.batch_no = V_BATCH_NO;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_NOTFOUND = TRUE;

  CALL SP_MASTER_INVENTORY_VERIFICATION_LENGTH(V_BATCH_NO);

  set autocommit = 0; 
  OPEN cur_master_item;
    read_loop: LOOP
        FETCH cur_master_item INTO
            V_ROW_NUMBER,
            V_TMP_MASTER_INVENTORY_ID,
            V_VENDOR_NAME,
            V_ACCOUNT_NUMBER,
            V_MASTER_INVENTORY_ID,
            V_SUMMARY_VENDOR_NAME,
            V_STRIPPED_CIRCUIT_NUMBER,
            V_COST_TYPE,
            V_CIRCUIT_STATUS,
            V_ADDRESS,
            V_A_STREET_NAME,
            V_A_CITY,
            V_A_POSTAL_CODE,
            V_A_PROVINCE,
            V_A_COUNTRY,
            V_RATE,
            V_END_USER,
            V_RATE_EFFECTIVE_DATE,
            V_INSTALLATION_DATE,
            V_DISCONNECTION_DATE,
            V_SERVICE_ID,
            V_NEW_VENDOR_NAME,
            V_OLD_VENDOR_NAME,
            V_NEW_BAN,
            V_OLD_BAN,
            V_NEW_LINE_OF_BUSINESS,
            V_OLD_LINE_OF_BUSINESS,
            V_NEW_REVENUE_MATCH_DATE,
            V_OLD_REVENUE_MATCH_DATE,
            V_NEW_SERVICE_ID_MATCH_STATUS,
            V_OLD_SERVICE_ID_MATCH_STATUS,
            V_NEW_ACCESS_TYPE,
            V_OLD_ACCESS_TYPE,
            V_NEW_LAST_SIGNOFF_DATE,
            V_OLD_LAST_SIGNOFF_DATE,
            V_NEW_USOC,
            V_OLD_USOC,
            V_NEW_TARIFF,
            V_OLD_TARIFF,
            V_NEW_AGREEMENT_TYPE,
            V_OLD_AGREEMENT_TYPE,
            V_NEW_RATE_DISCREPANCY,
            V_OLD_RATE_DISCREPANCY,
            V_NEW_TERMINATION_PENALTY_AMOUNT,
            V_OLD_TERMINATION_PENALTY_AMOUNT,
            V_LATEST_INVOICE_NUMBER,
            V_LINE_OF_BUSINESS,
            V_LASTEST_INVOICE_DATE,
            V_REVENUE_MATCH_DATE,
            V_SERVICE_ID_MATCH_STATUS,
            V_ACCESS_TYPE,
            V_FIRST_INVOICE_DATE,
            V_FIRST_INVOICE_NUMBER,
            V_LAST_SIGNOFF_DATE,
            V_USOC,
            V_TARIFF,
            V_AGREEMENT_TYPE,
            V_RATE_DISCREPANCY,
            V_TERMINATION_PENALTY_AMOUNT,
            V_MI_SUMMARY_VENDOR_NAME,
            V_MI_BAN,
            V_OWNER_EMAIL,
            V_ORDER_NUMBER;
        IF V_NOTFOUND THEN
            LEAVE read_loop;
        END IF;

        IF V_MASTER_INVENTORY_ID IS NOT NULL AND V_MASTER_INVENTORY_ID != '' THEN
          SELECT COUNT(1) INTO V_COUNT FROM master_inventory where id = V_MASTER_INVENTORY_ID;
        ELSE
          SET V_COUNT = 1;
        END IF;
        
        IF V_COUNT > 0 THEN
        
          SET V_BAN_ID = 0;
          SET V_VENDOR_ID = 0;
          SET V_BAN_SUMMARY_VENDOR_NAME = '';
          
          IF V_ACCOUNT_NUMBER IS NULL OR V_ACCOUNT_NUMBER = '' THEN
            INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'BAN','BAN is required');
          ELSE
            
            SET V_BAN_ID = (
              SELECT id
               FROM ban
              WHERE account_number = V_ACCOUNT_NUMBER
              AND rec_active_flag = 'Y'
              AND master_ban_flag = 'Y'
              AND ban_status_id = 1
              LIMIT 1
            );
            
            IF (V_BAN_ID IS NULL) THEN
              SET V_BAN_ID = (
                SELECT id
                FROM ban
                WHERE account_number = V_ACCOUNT_NUMBER
                AND rec_active_flag = 'Y'
                AND master_ban_flag = 'Y'
                LIMIT 1
              );
            END IF;
            
            IF V_BAN_ID IS NULL THEN
              INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'BAN','BAN is incorrect');
            
            ELSE
              SELECT ifnull(b.id, 0),IFNULL(b.vendor_id,0), v.summary_vendor_name INTO V_BAN_ID,V_VENDOR_ID, V_BAN_SUMMARY_VENDOR_NAME
                FROM ban b, vendor v
                WHERE b.vendor_id = v.id
                AND b.id = V_BAN_ID;
              
              UPDATE master_inventory_import SET ban_id = V_BAN_ID where id = V_TMP_MASTER_INVENTORY_ID;
            END IF;
            
          END IF;
              
          
          IF V_SUMMARY_VENDOR_NAME IS NULL OR V_SUMMARY_VENDOR_NAME = '' THEN
            INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'SUMMARY VENDOR NAME','Summary Vendor Name is required');
          ELSE
            SELECT COUNT(1) INTO V_COUNT
               FROM vendor
              WHERE summary_vendor_name = V_SUMMARY_VENDOR_NAME
                    AND id = V_VENDOR_ID
                    AND rec_active_flag = 'Y'
                    AND vendor_status_id = 1
                    LIMIT 1;
                    
            IF V_COUNT > 0 THEN
              UPDATE master_inventory_import SET vendor_id = V_VENDOR_ID where id = V_TMP_MASTER_INVENTORY_ID;
            ELSE
              
                IF (V_BAN_SUMMARY_VENDOR_NAME <> '') THEN
                INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'SUMMARY VENDOR NAME'
                      ,concat('Summary Vendor Name is incorrect', '. The Summary Vendor Name of BAN is ',V_BAN_SUMMARY_VENDOR_NAME));
                ELSE
                  INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'VENDOR NAME','Vendor is incorrect');
                END IF;
                
            END IF;
          END IF;
          
          
          
          IF V_COST_TYPE IN ('CUSTOMER - DIRECT','CUSTOMER - INDIRECT') THEN
            
            -- IF V_A_COUNTRY != '' AND V_ADDRESS != '' AND V_A_STREET_NAME != '' AND V_A_CITY != '' AND V_A_POSTAL_CODE != '' AND V_A_PROVINCE != '' AND V_RATE != '' AND V_END_USER != '' AND V_SERVICE_ID != '' THEN
            IF V_A_COUNTRY != '' AND V_ADDRESS != '' AND V_A_STREET_NAME != '' AND V_A_CITY != '' AND V_A_POSTAL_CODE != '' AND V_A_PROVINCE != '' AND V_END_USER != '' AND V_SERVICE_ID != '' THEN
              SET V_COMPLETE_FLAG = 'Y';
            ELSE
              SET V_COMPLETE_FLAG = 'N';
            END IF;
          ELSEIF V_COST_TYPE IN ('INTERNAL - COMMUNICATIONS','INTERNAL - NETWORK') THEN
            -- IF V_A_COUNTRY != '' AND V_ADDRESS != '' AND V_A_STREET_NAME != '' AND V_A_CITY != '' AND V_A_POSTAL_CODE != '' AND V_A_PROVINCE != '' AND V_RATE != '' AND V_END_USER != '' AND V_ORDER_NUMBER != '' THEN
            IF V_A_COUNTRY != '' AND V_ADDRESS != '' AND V_A_STREET_NAME != '' AND V_A_CITY != '' AND V_A_POSTAL_CODE != '' AND V_A_PROVINCE != '' AND V_END_USER != '' AND V_ORDER_NUMBER != '' THEN

              SET V_COMPLETE_FLAG = 'Y';
            ELSE
              SET V_COMPLETE_FLAG = 'N';
            END IF;
          ELSE
            SET V_COMPLETE_FLAG = 'N';
          END IF;

          UPDATE master_inventory_import SET complete_flag = V_COMPLETE_FLAG where id = V_TMP_MASTER_INVENTORY_ID;
          
          IF V_STRIPPED_CIRCUIT_NUMBER IS NULL OR V_STRIPPED_CIRCUIT_NUMBER = '' THEN
            INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'STRIPPED CIRCUIT NUMBER','Stripped Circuit Number is required');
          END IF;

          
          IF V_INSTALLATION_DATE IS NOT NULL AND V_INSTALLATION_DATE != '' THEN 
            SELECT IFNULL(str_to_date(V_INSTALLATION_DATE, '%m/%d/%Y'),'') INTO V_DATE;
            IF V_DATE IS NULL OR V_DATE = '' THEN 
              INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'INSTALL DATE','Install Date format must be "MM/DD/YYYY"');
            END IF;
          END IF;
          
          IF V_DISCONNECTION_DATE IS NOT NULL AND V_DISCONNECTION_DATE != '' THEN
            SELECT IFNULL(str_to_date(V_DISCONNECTION_DATE, '%m/%d/%Y'),'') INTO V_DATE;
            IF V_DATE IS NULL OR V_DATE = '' THEN 
              INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'DISCONNECTION DATE','Disconnection Date format must be "MM/DD/YYYY"');
            END IF;
          END IF;

          IF V_SERVICE_ID = '' OR V_SERVICE_ID IS NULL OR V_SERVICE_ID = 'UNKNOWN' THEN

            IF V_COST_TYPE != '' AND V_COST_TYPE NOT IN ('CUSTOMER - DIRECT','CUSTOMER - INDIRECT','Network','INTERNAL - NETWORK','INTERNAL - COMMUNICATIONS') THEN 
              INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'COST TYPE','Cost Type must be CUSTOMER - DIRECT , CUSTOMER - INDIRECT , INTERNAL - NETWORK or INTERNAL - COMMUNICATIONS');
            END IF;
          ELSE
            IF V_COST_TYPE NOT IN ('CUSTOMER - DIRECT','CUSTOMER - INDIRECT','Network','INTERNAL - NETWORK','INTERNAL - COMMUNICATIONS') THEN 
              INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'COST TYPE','Cost Type must be CUSTOMER - DIRECT , CUSTOMER - INDIRECT , INTERNAL - NETWORK or INTERNAL - COMMUNICATIONS');
            END IF;
          END IF;
          
          IF V_RATE_EFFECTIVE_DATE IS NOT NULL AND V_RATE_EFFECTIVE_DATE != '' THEN
            SELECT IFNULL(str_to_date(V_RATE_EFFECTIVE_DATE, '%m/%d/%Y'),'') INTO V_DATE;
            IF V_DATE IS NULL OR V_DATE = '' THEN 
              INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'RATE EFFECTIVE DATE','Rate Effective Date format must be "MM/DD/YYYY"');
            END IF;
          END IF;

          IF V_OWNER_EMAIL IS NOT NULL AND V_OWNER_EMAIL != '' THEN
            OPEN cur_email_item;
              read_loop1: LOOP
              FETCH cur_email_item INTO
                    V_EMAIL;
              IF V_NOTFOUND THEN
                  LEAVE read_loop1;
              END IF;
              SELECT V_EMAIL REGEXP '^[A-Z0-9._%-]+@[A-Z0-9.-]+.[A-Z]{2,4}$' INTO V_IS_EMAIL;
              IF V_IS_EMAIL <= 0 THEN 
                INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'OWNER E-MAIL','Owner E-mail is not a mailbox format');
                LEAVE read_loop1;
              END IF;
            END LOOP;
            CLOSE cur_email_item;
            SET V_NOTFOUND = FALSE;
          END IF;

        ELSE
          INSERT INTO tmp_master_inventory_error (row_number,field,note) VALUES (V_ROW_NUMBER,'KEY','This key does not exist in master inventory.');
        END IF;
        
        IF (IFNULL(V_SERVICE_ID,'') = '') THEN
            SET V_NEW_SERVICE_ID_MATCH_STATUS = 'TBD';
            
        ELSEIF(V_SERVICE_ID = 'UNKNOWN') THEN
            SET V_NEW_SERVICE_ID_MATCH_STATUS = 'UNKNOWN';
        ELSE
            SET V_NEW_SERVICE_ID_MATCH_STATUS = 'Complete';
        END IF;
      
        UPDATE master_inventory_import SET service_id_match_status = V_NEW_SERVICE_ID_MATCH_STATUS where id = V_TMP_MASTER_INVENTORY_ID;

        IF V_ACCOUNT_NUMBER = 'PRIMUSBI' THEN
          SET V_SPECIAL_DIFFERENCE = '';
          IF V_COST_TYPE = 'CUSTOMER - DIRECT' THEN
            SET V_SPECIAL_DIFFERENCE = 'CUST';
          ELSEIF V_COST_TYPE = 'CUSTOMER - INDIRECT' THEN
            SET V_SPECIAL_DIFFERENCE = 'NTWK';
          END IF;
          UPDATE master_inventory_import SET special_difference = V_SPECIAL_DIFFERENCE where id = V_TMP_MASTER_INVENTORY_ID;
        END IF;
        
       SET v_commit_count = v_commit_count + 1;
       IF (v_commit_count % 100 = 0) THEN
          commit;
       END IF;

      IF V_ROW_NUMBER % 1000 = 0 THEN
        SELECT COUNT(1) INTO V_COUNT FROM tmp_master_inventory_error;
        IF V_COUNT >= V_MAX_LENGTH THEN
          SET V_NOTFOUND = TRUE;
        END IF;
      END IF;

    END LOOP;
    
  CLOSE cur_master_item;

   commit;
   set autocommit = 1;
   
  SELECT COUNT(1) INTO V_COUNT
    FROM tmp_master_inventory_error;
  IF V_COUNT = 0 THEN
    SELECT user_id INTO V_USER_ID FROM master_inventory_import WHERE batch_no = V_BATCH_NO LIMIT 1;
    
    INSERT INTO master_inventory(
                      stripped_circuit_number,
                      unique_circuit_id,
                      service_id,
                      service_id_mrr,
                      service_id_mrr_province,
                      circuit_status,
                      installation_date,
                      disconnection_date,
                      order_number,
                      order_type,
                      quote_number,
                      validation_source_system,
                      cost_type,
                      service_description,
                      product_category,
                      sub_product_category,
                      project,
                      project_category_status,
                      a_street_number,
                      a_street_name,
                      a_unit,
                      a_city,
                      a_postal_code,
                      a_province,
                      a_country,
                      z_street_number,
                      z_street_name,
                      z_unit,
                      z_city,
                      z_postal_code,
                      z_province,
                      z_country,
                      region,
                      serving_wire_centre,
                      aggregator_cid,
                      time_slot_vlan_assignment,
                      comments,
                      trunk_group_clli,
                      customer_billing_account,
                      business_segment,
                      end_user,
                      scoa,
                      owner,
                      owner_email,
                      multiplier,
                      usoc,
                      rate,
                      rate_effective_date,
                      contract_name,
                      circuit_term,
                      tariff_name,
                      tariff_page,
                      expiry_date,
                      rate_status,
                      intercompany_business_unit,
                      intercompany_channel,
                      fsa_code,
                      serviceability_fibre,
                      serviceability_cable,
                      created_timestamp,
                      created_by,
                      modified_by,
                      modified_timestamp,
                      vendor_id,
                      import_summary_vendor_name,
                      ban_id,
                      service_id_match_status,
                      complete_flag,
                      special_difference)
       SELECT 
              f_translate(t.stripped_circuit_number, '(.\_/-:) ',''),
              IF(t.unique_circuit_id!='',t.unique_circuit_id,NULL),
              IF(t.service_id!='',t.service_id,NULL),
              IF(t.service_id_mrr!='',t.service_id_mrr,NULL),
              IF(t.service_id_mrr_province!='',t.service_id_mrr_province,NULL),
              IF(t.status!='',t.status,NULL),
              IF(t.installation_date!='',str_to_date(t.installation_date,'%m/%d/%Y'),NULL),
              IF(t.disconnection_date!='',str_to_date(t.disconnection_date,'%m/%d/%Y'),NULL),
              IF(t.order_number!='',t.order_number,NULL),
              IF(t.order_type!='',t.order_type,NULL),
              IF(t.quote_number!='',t.quote_number,NULL),
              IF(t.validation_source_system!='',t.validation_source_system,NULL),
              IF(t.cost_type!='',t.cost_type,NULL),
              IF(t.service_description!='',t.service_description,NULL),
              IF(t.product_category!='',t.product_category,NULL),
              IF(t.sub_product_category!='',t.sub_product_category,NULL),
              IF(t.project!='',t.project,NULL),
              IF(t.project_category_status!='',t.project_category_status,NULL),
              IF(t.a_street_number!='',t.a_street_number,NULL),
              IF(t.a_street_name!='',t.a_street_name,NULL),
              IF(t.a_unit!='',t.a_unit,NULL),
              IF(t.a_city!='',t.a_city,NULL),
              IF(t.a_postal_code!='',t.a_postal_code,NULL),
              IF(t.a_province!='',t.a_province,NULL),
              IF(t.a_country!='',t.a_country,NULL),
              IF(t.z_street_number!='',t.z_street_number,NULL),
              IF(t.z_street_name!='',t.z_street_name,NULL),
              IF(t.z_unit!='',t.z_unit,NULL),
              IF(t.z_city!='',t.z_city,NULL),
              IF(t.z_postal_code!='',t.z_postal_code,NULL),
              IF(t.z_province!='',t.z_province,NULL),
              IF(t.z_country!='',t.z_country,NULL),
              IF(t.region!='',t.region,NULL),
              IF(t.serving_wire_centre!='',t.serving_wire_centre,NULL),
              IF(t.aggregator_cid!='',t.aggregator_cid,NULL),
              IF(t.time_slot_vlan_assignment!='',t.time_slot_vlan_assignment,NULL),
              IF(t.comments!='',t.comments,NULL),
              IF(t.trunk_group_clli!='',t.trunk_group_clli,NULL),
              IF(t.customer_billing_account!='',t.customer_billing_account,NULL),
              IF(t.business_segment!='',t.business_segment,NULL),
              IF(t.end_user!='',t.end_user,NULL),
              IF(t.scoa!='',t.scoa,NULL),
              IF(t.owner!='',t.owner,NULL),
              IF(t.owner_email!='',t.owner_email,NULL),
              IF(t.mileage!='',t.mileage,NULL),
              IF(t.usoc!='',t.usoc,NULL),
              IF(t.rate!='',t.rate,NULL),
              IF(t.rate_effective_date!='',str_to_date(t.rate_effective_date,'%m/%d/%Y'),NULL),
              IF(t.contract!='',t.contract,NULL),
              IF(t.circuit_term!='',t.circuit_term,NULL),
              IF(t.tariff!='',t.tariff,NULL),
              IF(t.tariff_page!='',t.tariff_page,NULL),
              IF(t.expiry_date!='',str_to_date(t.expiry_date,'%m/%d/%Y'),NULL),
              IF(t.rate_status!='',t.rate_status,NULL),
              IF(t.intercompany_business_unit!='',t.intercompany_business_unit,NULL),
              IF(t.intercompany_channel!='',t.intercompany_channel,NULL),
              IF(t.fsa_code!='',t.fsa_code,NULL),
              IF(t.serviceability_fibre!='',t.serviceability_fibre,NULL),
              IF(t.serviceability_cable!='',t.serviceability_cable,NULL),
              now(),
              t.user_id,
              t.user_id,
              now(),
              IF(t.vendor_id!='',t.vendor_id,NULL),
              IF(t.summary_vendor_name!='',t.summary_vendor_name,NULL),
              IF(t.ban_id!='',t.ban_id,NULL),
              t.service_id_match_status,
              t.complete_flag,
              IF(t.special_difference!='',t.special_difference,NULL)
         FROM master_inventory_import t
        WHERE t.batch_no = V_BATCH_NO AND t.master_inventory_id NOT IN (SELECT id FROM master_inventory);

    UPDATE master_inventory m INNER JOIN master_inventory_import t ON t.master_inventory_id = m.id
       SET m.stripped_circuit_number = f_translate(t.stripped_circuit_number, '(.\_/-:) ',''),
          m.unique_circuit_id = IF(t.unique_circuit_id!='',t.unique_circuit_id,NULL),
          m.service_id = IF(t.service_id!='',t.service_id,NULL),
          m.service_id_mrr = IF(t.service_id_mrr!='',t.service_id_mrr,NULL),
          m.service_id_mrr_province = IF(t.service_id_mrr_province!='',t.service_id_mrr_province,NULL),
          m.circuit_status = IF(t.status!='',t.status,NULL),
          m.installation_date = IF(t.installation_date!='',str_to_date(t.installation_date,'%m/%d/%Y'),NULL),
          m.disconnection_date = IF(t.disconnection_date!='',str_to_date(t.disconnection_date,'%m/%d/%Y'),NULL),
          m.order_number = IF(t.order_number!='',t.order_number,NULL),
          m.order_type = IF(t.order_type!='',t.order_type,NULL),
          m.quote_number = IF(t.quote_number!='',t.quote_number,NULL),
          m.validation_source_system = IF(t.validation_source_system!='',t.validation_source_system,NULL),
          m.cost_type = IF(t.cost_type!='',t.cost_type,NULL),
          m.service_description = IF(t.service_description!='',t.service_description,NULL),
          m.product_category = IF(t.product_category!='',t.product_category,NULL),
          m.sub_product_category = IF(t.sub_product_category!='',t.sub_product_category,NULL),
          m.project = IF(t.project!='',t.project,NULL),
          m.project_category_status = IF(t.project_category_status!='',t.project_category_status,NULL),
          m.a_street_number = IF(t.a_street_number!='',t.a_street_number,NULL),
          m.a_street_name = IF(t.a_street_name!='',t.a_street_name,NULL),
          m.a_unit = IF(t.a_unit!='',t.a_unit,NULL),
          m.a_city = IF(t.a_city!='',t.a_city,NULL),
          m.a_postal_code = IF(t.a_postal_code!='',t.a_postal_code,NULL),
          m.a_province = IF(t.a_province!='',t.a_province,NULL),
          m.a_country = IF(t.a_country!='',t.a_country,NULL),
          m.z_street_number = IF(t.z_street_number!='',t.z_street_number,NULL),
          m.z_street_name = IF(t.z_street_name!='',t.z_street_name,NULL),
          m.z_unit = IF(t.z_unit!='',t.z_unit,NULL),
          m.z_city = IF(t.z_city!='',t.z_city,NULL),
          m.z_postal_code = IF(t.z_postal_code!='',t.z_postal_code,NULL),
          m.z_province = IF(t.z_province!='',t.z_province,NULL),
          m.z_country = IF(t.z_country!='',t.z_country,NULL),
          m.region = IF(t.region!='',t.region,NULL),
          m.serving_wire_centre = IF(t.serving_wire_centre!='',t.serving_wire_centre,NULL),
          m.aggregator_cid = IF(t.aggregator_cid!='',t.aggregator_cid,NULL),
          m.time_slot_vlan_assignment = IF(t.time_slot_vlan_assignment!='',t.time_slot_vlan_assignment,NULL),
          
          m.comments = IF(t.comments!='',t.comments,NULL),
          m.trunk_group_clli = IF(t.trunk_group_clli!='',t.trunk_group_clli,NULL),
          m.customer_billing_account = IF(t.customer_billing_account!='',t.customer_billing_account,NULL),
          m.business_segment = IF(t.business_segment!='',t.business_segment,NULL),
          m.end_user = t.end_user,
          m.scoa = IF(t.scoa!='',t.scoa,NULL),
          m.owner = IF(t.owner!='',t.owner,NULL),
          m.owner_email = IF(t.owner_email!='',t.owner_email,NULL),
          
          m.multiplier = IF(t.mileage!='',t.mileage,NULL),
          m.usoc = IF(t.usoc!='',t.usoc,NULL),
          m.rate = IF(t.rate>0,t.rate,NULL),
          m.rate_effective_date = IF(t.rate_effective_date!='',str_to_date(t.rate_effective_date,'%m/%d/%Y'),NULL),
          m.contract_name = IF(t.contract!='',t.contract,NULL),
          m.circuit_term = IF(t.circuit_term!='',t.circuit_term,NULL),
          m.tariff_name = IF(t.tariff!='',t.tariff,NULL),
          m.tariff_page = IF(t.tariff_page!='',t.tariff_page,NULL),
          m.expiry_date = IF(t.expiry_date!='',str_to_date(t.expiry_date,'%m/%d/%Y'),NULL),
          m.rate_status = IF(t.rate_status!='',t.rate_status,NULL),
          m.intercompany_business_unit = IF(t.intercompany_business_unit!='',t.intercompany_business_unit,NULL),
          m.intercompany_channel = IF(t.intercompany_channel!='',t.intercompany_channel,NULL),
          m.fsa_code = IF(t.fsa_code!='',t.fsa_code,NULL),
          m.serviceability_fibre = IF(t.serviceability_fibre!='',t.serviceability_fibre,NULL),
          m.serviceability_cable = IF(t.serviceability_cable!='',t.serviceability_cable,NULL),
          m.complete_flag = t.complete_flag,
          m.import_summary_vendor_name = IF(t.summary_vendor_name!='',t.summary_vendor_name,NULL),
          m.service_id_match_status = t.service_id_match_status ,
          m.modified_timestamp = now(),
          m.modified_by = t.user_id,
          m.special_difference = IF(t.special_difference!='',t.special_difference,NULL)
        where t.batch_no = V_BATCH_NO;
    
      UPDATE master_inventory m
      SET m.product_category = '10 GIGE'
      WHERE m.product_category = '10GIGE';
      
      DROP TABLE IF EXISTS tmp_master_product_mapping;
       CREATE TABLE tmp_master_product_mapping
      AS
        SELECT m.import_account_number AS ban
              ,m.stripped_circuit_number
              ,m.import_account_number AS usoc
              ,m.product_category
              ,m.sub_product_category
        FROM master_inventory m;
      
      DROP TABLE IF EXISTS tmp_new_prod;
      CREATE TEMPORARY TABLE tmp_new_prod AS
      SELECT product_category
      FROM
      (SELECT product_category
      FROM tmp_master_product_mapping
      WHERE ifnull(product_category,'')<>''
      GROUP BY product_category) t
      LEFT JOIN product p ON p.product_name = t.product_category
      WHERE p.id IS NULL;
      
      INSERT INTO product(
                    product_name
                  ,created_timestamp)
        SELECT product_category
              ,now()
        FROM tmp_new_prod;
      
      INSERT INTO product_component(
                    product_id
                  ,component_name
                  ,created_timestamp)
        SELECT p.id
              ,t.sub_product_category
              ,now()
        FROM (SELECT product_category
                    ,sub_product_category
              FROM tmp_master_product_mapping
              WHERE ifnull(
                      product_category
                    ,'') <> ''
              AND   IFNULL(
                      sub_product_category
                    ,'') <> ''
              GROUP BY product_category
                      ,sub_product_category) t
            LEFT JOIN product p
              ON p.product_name = t.product_category
            LEFT JOIN product_component pc
              ON pc.product_id = p.id
        AND       pc.component_name = t.sub_product_category
        WHERE pc.id IS NULL;
        
      DROP TABLE IF EXISTS tmp_mi_product;
      CREATE TEMPORARY TABLE tmp_mi_product AS  
      SELECT m.id as master_inventory_id ,p.id as product_id
      FROM master_inventory m
      INNER JOIN product p ON m.product_category = p.product_name 
      WHERE m.product_category IS NOT NULL
      AND (m.product_id IS NULL OR m.product_id <> p.id);
      
      ALTER TABLE tmp_mi_product ADD KEY master_inventory_id(master_inventory_id);
      
      UPDATE master_inventory m
            ,tmp_mi_product p
      SET m.product_id = p.product_id
      WHERE m.id = p.master_inventory_id;
      
      UPDATE master_inventory m
      SET m.product_id = null
      WHERE m.product_id is not null
      AND ( m.product_category is null or  m.product_category = '');
      
      DROP TABLE IF EXISTS tmp_mi_product_component;
      CREATE TEMPORARY TABLE tmp_mi_product_component AS  
      SELECT m.id as master_inventory_id ,pc.id as product_component_id
      FROM master_inventory m
      INNER JOIN product_component pc ON m.product_id = pc.product_id AND m.sub_product_category = pc.component_name
      WHERE m.sub_product_category is not null
      AND (m.product_component_id IS NULL OR m.product_component_id <> pc.id);
          
      ALTER TABLE tmp_mi_product_component ADD KEY master_inventory_id(master_inventory_id);
      
      UPDATE master_inventory m
            ,tmp_mi_product_component p
      SET m.product_component_id = p.product_component_id
      WHERE m.id = p.master_inventory_id;
      
      UPDATE master_inventory m
      SET m.product_component_id = null
      WHERE m.product_component_id is not null
      AND ( m.sub_product_category is null or  m.sub_product_category = '');
      
  END IF;

  DELETE FROM master_inventory_import WHERE batch_no = V_BATCH_NO;
  
END