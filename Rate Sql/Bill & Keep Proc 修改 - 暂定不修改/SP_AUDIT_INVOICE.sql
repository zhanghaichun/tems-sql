DROP PROCEDURE IF EXISTS SP_AUDIT_INVOICE;
CREATE PROCEDURE SP_AUDIT_INVOICE(V_INVOICE_ID INT)

BEGIN
  
  DECLARE V_PROVINCE_COUNTRY VARCHAR(128);
  DECLARE V_PROVINCE_ID INT(11);
  DECLARE V_BAN_ID INT(11);
  DECLARE V_LINE_OF_BUSINESS VARCHAR(128);
  DECLARE V_COUNT INT(11);

  INSERT INTO event_journal (event_type, ip_address, message_type, 
            event_message, event_data, created_timestamp, created_by)
            VALUES ('SP_AUDIT_INVOICE','',
            'INFO','Entering Processing BEGIN: ',NULL,current_timestamp,0);
    
    
    CALL SP_AUDIT_PRODUCT_MAPPING_CIRCUIT(V_INVOICE_ID);
    CALL SP_AUDIT_REFERENCE_MAPPING(V_INVOICE_ID);
    -- CALL SP_AUDIT_REFERENCE_MAPPING_SEARCH(V_INVOICE_ID);
    
    SELECT
      b.province_id, line_of_business,b.id
    INTO 
      V_PROVINCE_ID, V_LINE_OF_BUSINESS,V_BAN_ID
    FROM
      invoice i,
      ban b 
    WHERE
      i.ban_id = b.id 
      AND i.id = V_INVOICE_ID;
      
    SELECT country INTO V_PROVINCE_COUNTRY FROM province WHERE id = V_PROVINCE_ID;
    
    IF V_PROVINCE_ID IS NULL or V_PROVINCE_COUNTRY = 'Canada' THEN
      CALL SP_AUDIT_PROVINCE(V_INVOICE_ID);
    END IF;
    
    
    DELETE FROM audit_result WHERE invoice_id = V_INVOICE_ID;
    DELETE FROM invoice_audit_status WHERE invoice_id = V_INVOICE_ID;
    UPDATE proposal p
    SET p.audit_status_id = null
    WHERE invoice_id = V_INVOICE_ID;
    
    
    IF V_LINE_OF_BUSINESS LIKE 'Power Supply%' THEN
      CALL SP_AUDIT_EXISTS_PS(V_INVOICE_ID);
      CALL SP_AUDIT_TAX(V_INVOICE_ID);
      CALL SP_AUDIT_PAYMENT(V_INVOICE_ID);
    ELSE   
      CALL SP_AUDIT_EXISTS(V_INVOICE_ID);
      
      CALL SP_AUDIT_TAX(V_INVOICE_ID);
      CALL SP_AUDIT_PAYMENT(V_INVOICE_ID);
      CALL SP_AUDIT_MASTER_INVENTORY_RATE(V_INVOICE_ID);
      CALL SP_AUDIT_MASTER_INVENTORY_CIRCUIT_STATUS(V_INVOICE_ID);
      
      CALL SP_AUDIT_MRC_OCC(V_INVOICE_ID);
      CALL SP_AUDIT_USAGE(V_INVOICE_ID);
      CALL SP_AUDIT_OCC_DISCONNECTION(V_INVOICE_ID);
      CALL SP_AUDIT_OCC_RATE_CHANGE(V_INVOICE_ID);
      
      SELECT COUNT(1) INTO V_COUNT 
        FROM audit_reference_mapping 
        WHERE ban_id = V_BAN_ID
          and rec_active_flag = 'Y';
      IF V_COUNT > 0 THEN
        CALL SP_AUDIT_INVOICE_BILL_KEEP_FOR_TARIFF(V_INVOICE_ID);
      ELSE
        CALL SP_AUDIT_INVOICE_BILL_KEEP(V_INVOICE_ID);
      END IF;
      
      CALL SP_AUDIT_INVOICE_CVPP(V_INVOICE_ID);
      CALL SP_AUDIT_NAS(V_INVOICE_ID);
      CALL SP_AUDIT_BNS(V_INVOICE_ID);
      CALL SP_AUDIT_LPC(V_INVOICE_ID);
    END IF;

    CALL SP_AUDIT_SET_AUDIT_STATUS(V_INVOICE_ID);
  
  INSERT INTO event_journal (event_type, ip_address, message_type, 
            event_message, event_data, created_timestamp, created_by)
            VALUES ('SP_AUDIT_INVOICE','',
            'INFO','Entering Processing END: ',NULL,current_timestamp,0);
END