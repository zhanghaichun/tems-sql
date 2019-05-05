DROP PROCEDURE IF EXISTS SP_AUDIT_RULE_RATE_BY_ANY;
CREATE PROCEDURE SP_AUDIT_RULE_RATE_BY_ANY( IN PARAM_REFERENCE_ID INT,
                                            IN PARAM_PROPOSAL_ID INT,
                                            IN PARAM_PROPOSAL_RATE DOUBLE (20, 5),
                                            IN PARAM_REFERENCE_TABLE VARCHAR (64),
                                            OUT PARAM_EXPECT_RATE DOUBLE (20, 5),
                                            OUT PARAM_NOTES VARCHAR ( 768 ),
                                            OUT PARAM_RATE_EFFECTIVE_DATE DATE )

BEGIN

  /**
   * Either rate. "Tariffs Rate Table File C v1.xlsx"
   */
  DECLARE V_RATE_DATE  DATE;
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




  /**
   * 查询 rate 和 effective date
   */
  SELECT arp.rate, arp.start_date INTO PARAM_EXPECT_RATE, PARAM_RATE_EFFECTIVE_DATE
  FROM audit_rate_period arp
  WHERE arp.reference_table = PARAM_REFERENCE_TABLE
    AND arp.reference_id = PARAM_REFERENCE_ID

    /**
     * 当出现 either rate 的数据， 应该使用 actual rate 和系统中的 rate 做对比。
     */
    AND arp.rate = PARAM_PROPOSAL_RATE
    AND V_RATE_DATE >= arp.start_date
    AND (CASE
         WHEN arp.end_date IS NOT NULL
         THEN
            V_RATE_DATE < arp.end_date
         ELSE
            arp.end_date IS NULL
      END)
    ORDER BY arp.start_date DESC
    LIMIT 1;


  /**
   * Notes
   */
  SET PARAM_NOTES =  (
                        SELECT
                          CONCAT(
                                  'The rate is $' ,
                                  GROUP_CONCAT(
                                      CAST((0 + CAST(arp.rate AS char)) AS CHAR)
                                      ORDER BY rate DESC SEPARATOR ' or $'
                                  )
                          )
                        FROM
                            audit_rate_period arp
                        WHERE
                          arp.reference_table = PARAM_REFERENCE_TABLE
                          and arp.reference_id = PARAM_REFERENCE_ID
                          AND V_RATE_DATE >= arp.start_date
                          AND (CASE
                                   WHEN arp.end_date IS NOT NULL
                                   THEN
                                      V_RATE_DATE < arp.end_date
                                   ELSE
                                      arp.end_date IS NULL
                              END)
                        LIMIT 1

                      );

  IF ( PARAM_EXPECT_RATE IS NULL ) THEN

    SET PARAM_NOTES = CONCAT(PARAM_NOTES, ', but cannot find the relevant rate in proposal.');

  END IF;

END