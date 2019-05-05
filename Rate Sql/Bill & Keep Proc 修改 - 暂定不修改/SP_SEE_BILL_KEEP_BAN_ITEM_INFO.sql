DROP PROCEDURE IF EXISTS SP_SEE_BILL_KEEP_BAN_ITEM_INFO;
CREATE PROCEDURE SP_SEE_BILL_KEEP_BAN_ITEM_INFO( V_INVOICE_ID INT )

BEGIN
  
/**
 * 这个存储过程主要是用来查询 bill keep ban 中 invoice item
 * 的相关信息， 如：bill keep ban 共有三个参考文件，通过查询可以知晓
 * 当前 rules 出自哪一个参考文件中的规则。
 */

  DECLARE V_LIR_OR_EXCHANGE_NAME VARCHAR(32);
  DECLARE V_ITEM_NAME VARCHAR(64);
  DECLARE V_STRIPPED_ITEM_NAME VARCHAR(64);
  DECLARE V_INVOICE_DATE DATE;

  /**
   * 用来识别当前的 bill_keep_ban item 用于哪个文件中的 rule.
   * value = 1: 【June 2018 Fido - Monthly CLEC Report - Monthly - On Demand - V3.1.xlsx】
   * value = 2: 【Imbalance Report - 5ESS and LCS - On Demand - v 2.0 -  Jun 2018 .xlsx】
   * value = 3: 【June 2018 Digital Home Phone RHPc Bill & Keep Imbalance Report byLIR and Carrier.xlsx】
   */
  DECLARE V_BILL_KEEP_BAN_FILE_TYPE INT; 

  /**
   * 这个字段在 report 中是 Carrier 字段， 但是在系统中是 bill_keep_ban 表中的 report_name 字段。
   */
  DECLARE V_CARRIER VARCHAR(32);

  SELECT
    bk.report_name AS Carrier,
    IFNULL(bkn.bill_keep_name,'') AS 'Lir/Exchange',
    ii.item_name AS ItemName,
    i.invoice_date AS InvoiceDate,
    bl.file_name AS BillKeepBanReferenceFileName

  FROM invoice_item ii
    LEFT JOIN proposal p ON p.invoice_item_id = ii.id
    LEFT JOIN invoice i ON i.id = ii.invoice_id
    LEFT JOIN bill_keep_ban bk ON bk.ban_id = i.ban_id
    LEFT JOIN bill_keep_name_contrast bkn ON REPLACE(ii.item_name,' ','')
      LIKE CONCAT('%',REPLACE(bkn.invoice_item_name,' ',''),'%') AND bk.report_name = bkn.vendor
    LEFT JOIN bill_keep bl ON bl.bill_keep_ban_type = bk.type AND bl.carrier = bk.report_name

  WHERE ii.invoice_id = V_INVOICE_ID
      AND ( bl.lir_exchange = bkn.bill_keep_name OR REPLACE(bl.lir_exchange,' ','') = REPLACE(ii.item_name,' ','') )
      AND (bl.term_switch IS NULL OR bl.term_switch = '')
      AND DATE_FORMAT(bl.invoice_date,'%Y-%m') = DATE_FORMAT(i.invoice_date,'%Y-%m')
      AND (
            ii.item_type_id IN(13,14,15,16,17)
            OR ii.item_type_id LIKE '3%'
            OR ii.item_type_id LIKE '5%'
            OR ii.item_type_id LIKE '6%'
            OR ii.item_type_id LIKE '7%'
      )
      AND ii.proposal_flag = 1
      AND ii.rec_active_flag = 'Y';

END