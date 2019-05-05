DROP PROCEDURE IF EXISTS SP_SHOW_CVPP_TELUS_INVOICE_ITEM;
CREATE PROCEDURE `SP_SHOW_CVPP_TELUS_INVOICE_ITEM`(V_INVOICE_ID INT(11))
BEGIN
  
  /**
   * Query CVPP invoice item info.
   * SUMMARY_VENDOR_NAME: TELUS
   */
  
  SELECT 
    v.summary_vendor_name,
    b.account_number AS BAN,
    i.id AS invoice_id, 
    p.id AS proposal_id, 
    (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0)) AS payment_amount,
    ii.line_item_code AS line_item_code,
    ii.line_item_code_description AS line_item_code_description,
    ii.usoc AS usoc,
    ii.usoc_description AS usoc_description
  FROM proposal p, invoice_item ii, vendor v, invoice i, ban b
  WHERE p.invoice_item_id = ii.id
    AND p.invoice_id = i.id
    AND v.id = i.vendor_id
    AND b.id = i.ban_id
    AND p.invoice_id = V_INVOICE_ID
    AND (
          ii.line_item_code IN ('2296M', '232M0', '243M4', '80427', '80428',
                                '80433', '80434', '80435', '84495', '89389', '89574')
          OR 
          ii.usoc = '1HWNS'
        )
    AND p.proposal_flag = 1
    AND p.rec_active_flag = 'Y';

END;