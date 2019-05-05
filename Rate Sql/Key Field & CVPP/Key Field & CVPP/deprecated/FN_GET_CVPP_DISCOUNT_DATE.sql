DROP FUNCTION IF EXISTS FN_GET_CVPP_DISCOUNT_DATE;
CREATE FUNCTION `FN_GET_CVPP_DISCOUNT_DATE`( PARAM_INVOICE_ID INT ) RETURNS DATE
BEGIN

  DECLARE V_CVPP_DISCOUNT_DATE  DATE;
  DECLARE V_INVOICE_DATE DATE;
  DECLARE V_INVOICE_START_DATE DATE;
  DECLARE V_MONTHS_INTERVAL INT;

  /**
   * CVPP 数据是基于账单的， 从账单中获取有效的 discount date,
   * 下面是获取 discount date 的优先级
   * 1. invoice.invoice_start_date
   * 2. invoice.invoice_date
   */
  SELECT 
    i.invoice_date, 
    i.invoice_start_date
      INTO 
        V_INVOICE_DATE,  
        V_INVOICE_START_DATE
  FROM invoice i
  WHERE i.id = PARAM_INVOICE_ID;

  SET V_CVPP_DISCOUNT_DATE = NULL;

  /**
   * 1. Base on Invoice Start Date
   */
  IF (V_CVPP_DISCOUNT_DATE IS NULL) THEN

    /**
     * + 1 day 的原因：
     * 例如： ITEM_START_DATE 是 '2017-12-31' 的账单, 使用的是 effective_date 为 '2018-01-01'
     *        的 rate, 这个时候就需要手动加 1 天， 来匹配正确的 rate.
     */
    SET V_CVPP_DISCOUNT_DATE = DATE_ADD( V_INVOICE_START_DATE, INTERVAL 1 DAY);
  END IF;

  /**
   * 2. Base on Inovoice Date
   */
  IF (V_CVPP_DISCOUNT_DATE IS NULL) THEN
    SET V_CVPP_DISCOUNT_DATE = DATE_SUB( V_INVOICE_DATE, INTERVAL 1 MONTH);
  END IF;

  RETURN V_CVPP_DISCOUNT_DATE;
END