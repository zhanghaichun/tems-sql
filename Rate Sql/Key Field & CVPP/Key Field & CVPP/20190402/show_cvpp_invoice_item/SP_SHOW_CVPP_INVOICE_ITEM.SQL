DROP PROCEDURE IF EXISTS SP_SHOW_CVPP_INVOICE_ITEM;
CREATE PROCEDURE `SP_SHOW_CVPP_INVOICE_ITEM`(V_INVOICE_ID INT(11))
BEGIN

  DECLARE V_IS_BELL    INT(11) DEFAULT 0;
  DECLARE V_IS_TELUS   INT(11) DEFAULT 0;

  /**
   * Query invoice item info about CVPP, including BELL CANADA & ALIANT & TELUS.
   */
  
  SET V_IS_BELL = (
      SELECT count(1)
      FROM invoice i, vendor v, ban b
      WHERE i.vendor_id = v.id
        AND i.ban_id = b.id
        AND i.id = V_INVOICE_ID
        AND (
              (v.summary_vendor_name = 'ALIANT' AND b.account_number = '87004913')
              OR 
              (
                v.summary_vendor_name = 'BELL CANADA'
                AND 
                b.account_number IN ('T6011329', 'B1ES2A5201102', 'B1ES2A5201102', 'B1ES4A0318555',
                            'B1ES9A8501304', 'B1ES9B1616135', 'B1FS1Q0911102', 'B1FS1Q0911102', 'B1FS4O1823165',
                            'B1FS7A0031555', 'N9550000')
              )
          )
        AND i.rec_active_flag = 'Y'
    );
      -- 测试ID 515864
  SET V_IS_TELUS = (
      SELECT count(1)
      FROM proposal p, invoice_item ii, invoice i, vendor v, ban b
      WHERE p.invoice_item_id = ii.id
        AND b.vendor_id = v.id
        AND i.ban_id = b.id
        AND i.id = p.invoice_id
        AND i.id = V_INVOICE_ID
        AND v.summary_vendor_name = 'TELUS'
        AND (   
              p.item_type_id IN (13, 15)
              OR 
              p.item_type_id LIKE '3%'
              OR 
              p.item_type_id LIKE '5%'
          )
        AND (
              ii.line_item_code IN ('2296M', '232M0', '243M4', '80427', '80428', '80433',
                                    '80434', '80435', '84495', '89389', '89574')
              OR 
              ii.usoc = '1HWNS'
          )
        AND p.proposal_flag = 1
        AND p.rec_active_flag = 'Y'
    );

    IF V_IS_BELL > 0 THEN

       CALL SP_SHOW_CVPP_BELL_AND_ALIANT_INVOICE_ITEM(V_INVOICE_ID);

    ELSEIF V_IS_TELUS > 0 THEN

       CALL SP_SHOW_CVPP_TELUS_INVOICE_ITEM(V_INVOICE_ID);
    END IF;
END;