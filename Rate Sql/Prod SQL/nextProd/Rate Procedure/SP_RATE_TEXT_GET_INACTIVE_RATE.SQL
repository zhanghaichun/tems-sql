DROP PROCEDURE IF EXISTS SP_RATE_TEXT_GET_INACTIVE_RATE;
CREATE PROCEDURE `SP_RATE_TEXT_GET_INACTIVE_RATE`(  IN I_REFERENCE_TYPE VARCHAR (16),
                                                  IN I_RATE_MODE VARCHAR (64),
                                                  IN I_REFERENCE_ID INT,
                                                  OUT O_INACTIVE_EFFECTIVE_DATE VARCHAR (12),
                                                  OUT O_INACTIVE_RATE VARCHAR (256)
                                                )
BEGIN
    
  /**
   * @{link SQLFunciton} FN_GET_AUDIT_RATE_TEXT
   * @return {String} [O_INACTIVE_RATE] 字符串格式的 rate, 因为当 key_field 有 quantity 的时候， 
   *                                    多个 rate 会通过逗号拼接成一个字符串。
   * @return {String} [O_INACTIVE_EFFECTIVE_DATE]
   * 
   * 这个 SQL 程序针对 rate module , 返回 inactive 状态下的 rate 和 effective date.
   * 针对不同的 reference_type 做分类型处理。同时内部也会根据不同的 rate mode 做处理。
   */
  DECLARE CONST_TARIFF_REFERENCE_TYPE VARCHAR (16) DEFAULT 'tariff';
  DECLARE CONST_CONTRACT_REFERENCE_TYPE VARCHAR (16) DEFAULT 'contract';
  DECLARE CONST_MTM_REFERENCE_TYPE VARCHAR (16) DEFAULT 'mtm';

  /**
   * referenct_type = 'tariff'
   */
  IF ( I_REFERENCE_TYPE = CONST_TARIFF_REFERENCE_TYPE ) THEN
  
    IF ( I_RATE_MODE IN ('rate', 'tariff_rate_multiplier', 'tariff_rate_discount', 'rate_max') ) THEN

      /**
       * 返回单一的 rate 值。
       */
      SELECT
        CONCAT( '',  FN_TRANSFORM_NOTES_RATE(rate) ) ,
        DATE_FORMAT(start_date, '%Y-%m-%d')
        INTO 
          O_INACTIVE_RATE, 
          O_INACTIVE_EFFECTIVE_DATE 
      FROM audit_rate_period 
      WHERE reference_table = I_REFERENCE_TYPE
        AND reference_id = I_REFERENCE_ID
        AND rec_active_flag = 'Y'
        AND end_date IS NOT NULL
      GROUP BY start_date
      ORDER BY start_date DESC
      LIMIT 1;

    ELSEIF ( I_RATE_MODE IN ('tariff_rate_by_quantity','tariff_rate_by_quantity_base_amount', 
                              'tariff_rate_by_quantity_rate_max') ) THEN

      /**
       * 返回用逗号组合的 rate 值。不同的 quantity 有不同 rate 值。
       */
      SELECT 
        GROUP_CONCAT( FN_TRANSFORM_NOTES_RATE(arp.rate) ORDER BY trbq.quantity_begin separator ', '), 
        DATE_FORMAT(arp.start_date, '%Y-%m-%d') 
        INTO 
          O_INACTIVE_RATE, 
          O_INACTIVE_EFFECTIVE_DATE
      FROM audit_rate_period arp
        LEFT JOIN tariff_rate_by_quantity trbq ON trbq.id = arp.reference_id
      WHERE arp.reference_table = 'tariff_rate_by_quantity'
        AND arp.end_date IS NOT NULL
        AND arp.rec_active_flag = 'Y'
        AND arp.reference_id IN (
                                  SELECT id
                                  FROM tariff_rate_by_quantity
                                  WHERE tariff_id = I_REFERENCE_ID
                                )
      GROUP BY start_date
      ORDER BY arp.start_date DESC
      LIMIT 1;

    ELSEIF ( I_RATE_MODE = 'rate_any' ) THEN 

      /**
       * 返回使用 'or' 连接的 rate， 因为可能相同的规则可以有两个或多个 rate 值。
       */
      SELECT
        GROUP_CONCAT(  FN_TRANSFORM_NOTES_RATE(rate) ORDER BY id separator ' or ' ),
        DATE_FORMAT(start_date, '%Y-%m-%d') 
        INTO 
          O_INACTIVE_RATE,
          O_INACTIVE_EFFECTIVE_DATE
      FROM audit_rate_period
      WHERE reference_table = I_REFERENCE_TYPE
        AND reference_id = I_REFERENCE_ID
        AND end_date IS NOT NULL
        AND rec_active_flag = 'Y'
      GROUP BY start_date
      ORDER BY start_date DESC
      LIMIT 1;


    END IF;

  /**
   * referenct_type = 'contract'
   */
  ELSEIF ( I_REFERENCE_TYPE = CONST_CONTRACT_REFERENCE_TYPE ) THEN

    IF ( I_RATE_MODE = 'rate' ) THEN

      /**
       * 返回单一的 rate 值。
       */
      SELECT
        CONCAT( '', FN_TRANSFORM_NOTES_RATE(rate) ),
        DATE_FORMAT(start_date, '%Y-%m-%d')  
        INTO 
          O_INACTIVE_RATE, 
          O_INACTIVE_EFFECTIVE_DATE
      FROM audit_rate_period
      WHERE reference_table = I_REFERENCE_TYPE
        AND reference_id = I_REFERENCE_ID
        AND end_date IS NOT NULL
        AND rec_active_flag = 'Y'
      GROUP BY start_date
      ORDER BY start_date DESC
      LIMIT 1;

    ELSEIF ( I_RATE_MODE = 'rate_any' ) THEN

      /**
       * 返回使用 'or' 连接的 rate， 因为可能相同的规则可以有两个或多个 rate 值。
       */
      SELECT
        GROUP_CONCAT( FN_TRANSFORM_NOTES_RATE(rate) ORDER BY id SEPARATOR ' or ' ),
        DATE_FORMAT(start_date, '%Y-%m-%d')
        INTO 
          O_INACTIVE_RATE, 
          O_INACTIVE_EFFECTIVE_DATE
      FROM audit_rate_period
      WHERE reference_table = I_REFERENCE_TYPE
        AND reference_id = I_REFERENCE_ID
        AND end_date IS NOT NULL
        AND rec_active_flag = 'Y'
      GROUP BY start_date
      ORDER BY start_date DESC
      LIMIT 1;

    ELSEIF ( I_RATE_MODE = 'contract_rate_by_quantity' ) THEN

      /**
       * 返回用逗号组合的 rate 值。不同的 quantity 有不同 rate 值。
       */
      SELECT 
        GROUP_CONCAT( FN_TRANSFORM_NOTES_RATE(arp.rate) ORDER BY crbq.quantity_begin separator ', '), 
        DATE_FORMAT(arp.start_date, '%Y-%m-%d') 
        INTO 
          O_INACTIVE_RATE, 
          O_INACTIVE_EFFECTIVE_DATE
      FROM audit_rate_period arp
        LEFT JOIN contract_rate_by_quantity crbq ON crbq.id = arp.reference_id
      WHERE arp.reference_table = 'contract_rate_by_quantity'
        AND arp.end_date IS NOT NULL
        AND arp.rec_active_flag = 'Y'
        AND arp.reference_id IN (
                                  SELECT id
                                  FROM contract_rate_by_quantity
                                  WHERE contract_id = I_REFERENCE_ID
                                )
      GROUP BY start_date
      ORDER BY arp.start_date DESC
      LIMIT 1; 

    END IF;

  /**
   * referenct_type = 'mtm'
   */
  ELSEIF ( I_REFERENCE_TYPE = CONST_MTM_REFERENCE_TYPE ) THEN -- MtM
      
    IF ( I_RATE_MODE = 'rate' ) THEN

      /**
       * 返回单一的 rate 值。
       */
      SELECT
        CONCAT( '', FN_TRANSFORM_NOTES_RATE(rate) ),
        DATE_FORMAT(start_date, '%Y-%m-%d')
        INTO 
          O_INACTIVE_RATE,
          O_INACTIVE_EFFECTIVE_DATE
      FROM audit_rate_period
      WHERE reference_table = 'audit_mtm'
        AND reference_id = I_REFERENCE_ID
        AND end_date IS NOT NULL
        AND rec_active_flag = 'Y'
      GROUP BY start_date
      ORDER BY start_date DESC
      LIMIT 1;
        
    END IF;

  END IF;


END