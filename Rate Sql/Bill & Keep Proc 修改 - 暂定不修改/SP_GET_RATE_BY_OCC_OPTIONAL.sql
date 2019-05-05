DROP PROCEDURE IF EXISTS SP_GET_RATE_BY_OCC_OPTIONAL;
CREATE PROCEDURE SP_GET_RATE_BY_OCC_OPTIONAL( IN PARAM_REFERENCE_TABLE    VARCHAR(64),
                                              IN PARAM_REFERENCE_ID         INT(11),
                                              IN PARAM_PROPOSAL_ID        INT(11),
                                              IN PARAM_OPTIONAL_TYPE      VARCHAR(16),
                                              OUT PARAM_RATE             DOUBLE (20,5),
                                              OUT PARAM_RATE_EFFECTIVE_DATE DATE)

BEGIN

  DECLARE V_RATE_DATE   DATE;
  DECLARE V_ITEM_START_DATE DATE;
  DECLARE V_INVOICE_DATE DATE;
  DECLARE V_INVOICE_START_DATE DATE;
  DECLARE V_MONTHS_INTERVAL INT;


  /**
     * 获取账单费用产生的实际日期，需要通过三个字段和
     * 相应的逻辑来获取。 优先级 (从高到低)：
     * 1. invoice_item.start_date
     * 2. invoice.invoice_start_date
     * 3. invoice.invoice_date
     */
    SELECT 
      i.invoice_date, 
      ii.start_date, 
      i.invoice_start_date
        INTO 
          V_INVOICE_DATE,  
          V_ITEM_START_DATE,
          V_INVOICE_START_DATE
    FROM proposal p
      LEFT JOIN invoice i ON p.invoice_id = i.id
      LEFT JOIN invoice_item ii ON p.invoice_item_id = ii.id
    WHERE p.id = PARAM_PROPOSAL_ID;
    
    SET V_RATE_DATE = NULL;

    /**
     * 获取 V_ITEM_START_DATE 和 V_INVOICE_DATE 两个日期的差值
     * V_INVOICE_DATE 日期值更大。
     *
     * V_ITEM_START_DATE 可能为 NULL 值。
     */
    SET V_MONTHS_INTERVAL = TIMESTAMPDIFF(MONTH, V_ITEM_START_DATE, V_INVOICE_DATE);

    /**
     * 1. Base on Invoice Item Start Date
     */
    IF (V_ITEM_START_DATE IS NOT NULL AND V_MONTHS_INTERVAL <= 6) THEN

      /**
       * + 1 day 的原因：
       * 例如： ITEM_START_DATE 是 '2017-12-31' 的账单, 使用的是 effective_date 为 '2018-01-01'
       *        的 rate, 这个时候就需要手动加 1 天， 来匹配正确的 rate.
       */
      SET V_RATE_DATE = DATE_ADD( V_ITEM_START_DATE, INTERVAL 1 DAY );  
    END IF;

    /**
     * 2. Base on Invoice Start Date
     */
    IF (V_RATE_DATE IS NULL) THEN

      /**
       * + 1 day 的原因：
       * 例如： ITEM_START_DATE 是 '2017-12-31' 的账单, 使用的是 effective_date 为 '2018-01-01'
       *        的 rate, 这个时候就需要手动加 1 天， 来匹配正确的 rate.
       */
      SET V_RATE_DATE = DATE_ADD( V_INVOICE_START_DATE, INTERVAL 1 DAY);
    END IF;

    /**
     * 3. Base on Inovoice Date
     */
    IF (V_RATE_DATE IS NULL) THEN
      SET V_RATE_DATE = DATE_SUB( V_INVOICE_DATE, INTERVAL 1 MONTH);
    END IF;


  IF ( PARAM_OPTIONAL_TYPE = 'ACTIVE_RATE' ) THEN

    SELECT ROUND(rate, 5), arp.start_date INTO PARAM_RATE, PARAM_RATE_EFFECTIVE_DATE
    FROM audit_rate_period arp
    WHERE arp.reference_table = PARAM_REFERENCE_TABLE
      AND arp.reference_id = PARAM_REFERENCE_ID
      AND V_RATE_DATE >= arp.start_date
      AND (CASE
             WHEN arp.end_date IS NOT NULL
             THEN
                V_RATE_DATE <= arp.end_date
             ELSE
                arp.end_date IS NULL
          END)
    ORDER BY arp.start_date DESC
    LIMIT 1;

  ELSEIF ( PARAM_OPTIONAL_TYPE = 'LAST_ACTIVE_RATE' ) THEN

    SELECT ROUND(rate, 5), arp.start_date INTO PARAM_RATE, PARAM_RATE_EFFECTIVE_DATE
    FROM audit_rate_period arp
    WHERE arp.reference_table = PARAM_REFERENCE_TABLE
      AND arp.reference_id = PARAM_REFERENCE_ID
      AND arp.end_date IS NOT NULL
      AND arp.end_date <= V_RATE_DATE
    ORDER BY arp.end_date DESC
    LIMIT 1;
    
  END IF;



END