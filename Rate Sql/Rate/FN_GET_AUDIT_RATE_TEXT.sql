CREATE FUNCTION `FN_GET_AUDIT_RATE_TEXT`(  
    V_REFERENCE_TYPE VARCHAR (64),
    V_REFERENCE_ID INT) 
RETURNS varchar(768) CHARSET utf8 COLLATE utf8_unicode_ci
BEGIN

  /**
   * 显示 rate module rule 描述信息， 格式如下：
   * Rate Mode: ....
   * Active Date: ...
   * Effective Date: ...
   * Inactive Date: ...
   * Effective Date: ...
   * Quantity: ...
   * Multiplier: ...
   * Discount: ...
   */
  
  DECLARE V_RATE_MODE VARCHAR (64);
  DECLARE V_RECORD_AMOUNT INT;
  DECLARE V_RATE varchar(64);
  DECLARE V_EFFECTIVE_DATE VARCHAR (32);
  DECLARE V_INACTIVE_RATE varchar(64) ;

  DECLARE V_INACTIVE_EFFECTIVE_DATE VARCHAR (32);
  DECLARE V_ACTIVE_RATE varchar(64);
  DECLARE V_ACTIVE_EFFECTIVE_DATE VARCHAR (32);

  /**
   * 返回的最终结果
   */
  DECLARE V_RETURNED_RATE_TEXT VARCHAR (768);
  DECLARE V_QUANTITY_TEXT varchar(256);
  DECLARE V_BASE_AMOUNT_TEXT varchar(64);
  DECLARE V_MULTIPLIER varchar(16);
  DECLARE V_DISCOUNT varchar(16);

  DECLARE CONST_TARIFF_REFERENCE_TYPE VARCHAR (16) DEFAULT 'tariff';
  DECLARE CONST_CONTRACT_REFERENCE_TYPE VARCHAR (16) DEFAULT 'contract';
  DECLARE CONST_MTM_REFERENCE_TYPE VARCHAR (16) DEFAULT 'mtm';


  /**
   * 通过 reference_id 查询 rate_mode.
   */
  IF ( V_REFERENCE_TYPE = CONST_TARIFF_REFERENCE_TYPE ) THEN

      SELECT rate_mode INTO V_RATE_MODE FROM tariff
      WHERE id = V_REFERENCE_ID;

  ELSEIF ( V_REFERENCE_TYPE = CONST_CONTRACT_REFERENCE_TYPE ) THEN

      SELECT rate_mode INTO V_RATE_MODE FROM contract
      WHERE id = V_REFERENCE_ID;

  ELSEIF ( V_REFERENCE_TYPE = CONST_MTM_REFERENCE_TYPE ) THEN

      SELECT rate_mode INTO V_RATE_MODE FROM audit_mtm
      WHERE id = V_REFERENCE_ID;

  END IF;
    
  /**
   * 获取 Inactive Rate 和 Effective Date.
   */
  CALL SP_RATE_TEXT_GET_INACTIVE_RATE(
                                        V_REFERENCE_TYPE, 
                                        V_RATE_MODE, 
                                        V_REFERENCE_ID,
                                        V_INACTIVE_EFFECTIVE_DATE, 
                                        V_INACTIVE_RATE
                                      );

  /**
   * 获取 Active Rate 和 Effective Date.
   */
  CALL SP_RATE_TEXT_GET_ACTIVE_RATE( 
                                      V_REFERENCE_TYPE, 
                                      V_RATE_MODE, 
                                      V_REFERENCE_ID,
                                      V_ACTIVE_EFFECTIVE_DATE, 
                                      V_ACTIVE_RATE
                                    );


  /**
   * referenct_type = 'tariff'
   */
  IF (V_REFERENCE_TYPE = CONST_TARIFF_REFERENCE_TYPE) THEN
     

    IF (V_RATE_MODE = 'rate') THEN

      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          'Rate Mode: Rate. <br>',
                                          'Active Rate: ',
                                          V_ACTIVE_RATE,
                                          ', Effective Date: ',
                                          V_ACTIVE_EFFECTIVE_DATE,
                                          '. <br>'
                                        );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT(
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;


    ELSEIF ( V_RATE_MODE = 'tariff_rate_by_quantity' ) THEN

      SELECT 
            GROUP_CONCAT( CAST(trbq.quantity_begin AS CHAR) ,
                          ' ~ ', 
                          IFNULL(CAST(trbq.quantity_end AS CHAR), 'greater' )
                          ORDER BY trbq.quantity_begin
                          SEPARATOR ', ') INTO V_QUANTITY_TEXT
      FROM tariff_rate_by_quantity trbq
      WHERE trbq.tariff_id = V_REFERENCE_ID;

      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          'Rate Mode: Tariff Rate By Quantity. <br>', 
                                          'Quantity & Rate: ', 
                                          '<br>  Quantity: ', 
                                          V_QUANTITY_TEXT,
                                          '. <br>  ', 
                                          'Active Rate: ', 
                                          V_ACTIVE_RATE, 
                                          ', Effective Date: ', 
                                          V_ACTIVE_EFFECTIVE_DATE, 
                                          '. <br>  ' 
                                        );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT( 
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;

    ELSEIF ( V_RATE_MODE = 'tariff_rate_by_quantity_rate_max' ) THEN

      SELECT 
        GROUP_CONCAT( CAST(trbq.quantity_begin AS CHAR) ,
                      ' ~ ', 
                      IFNULL(CAST(trbq.quantity_end AS CHAR), 'greater' )
                      ORDER BY trbq.quantity_begin
                      SEPARATOR ', ') INTO V_QUANTITY_TEXT
      FROM tariff_rate_by_quantity trbq
      WHERE trbq.tariff_id = V_REFERENCE_ID;

      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          'Rate Mode: Tariff Rate By Quantity (Max Rate) <br>', 
                                          'Quantity & Maximum Rate: ', 
                                          '<br>  Quantity: ', 
                                          V_QUANTITY_TEXT,
                                          '. <br>  ', 
                                          'Active Rate: ', 
                                          V_ACTIVE_RATE, 
                                          ', Effective Date: ', 
                                          V_ACTIVE_EFFECTIVE_DATE, 
                                          '. <br>  ' 
                                        );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT( 
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;

    ELSEIF ( V_RATE_MODE = 'tariff_rate_by_quantity_base_amount' ) THEN

      /**
       * Qty text
       */
      SELECT 
            GROUP_CONCAT( CAST(trbq.quantity_begin AS CHAR) ,
                          ' ~ ', 
                          IFNULL(CAST(trbq.quantity_end AS CHAR), 'greater' )
                          ORDER BY trbq.quantity_begin
                          SEPARATOR ', ') into V_QUANTITY_TEXT
      FROM tariff_rate_by_quantity trbq
      WHERE trbq.tariff_id = V_REFERENCE_ID;

      -- base amount.
      SELECT 
        FORMAT(
            GROUP_CONCAT(CAST(trbq.base_amount AS CHAR) ORDER BY trbq.quantity_begin SEPARATOR ', '),
            2
          )
        INTO V_BASE_AMOUNT_TEXT
      FROM tariff_rate_by_quantity trbq
      WHERE trbq.tariff_id = V_REFERENCE_ID;


      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          'Rate Mode: Tariff Rate By Quantity & Base Amount. <br>', 
                                          'Quantity & Rate & Base Amount: ', '<br>  Quantity: ', 
                                          V_QUANTITY_TEXT,
                                          '. <br>  ', 
                                          'Active Rate: ', 
                                          V_ACTIVE_RATE, 
                                          ', Effective Date: ', 
                                          V_ACTIVE_EFFECTIVE_DATE, 
                                          '. <br>  ' 
                                        );

       IF V_INACTIVE_RATE IS NOT NULL THEN

          SET V_RETURNED_RATE_TEXT = CONCAT(
                                              V_RETURNED_RATE_TEXT,
                                              'Inactive Rate: ', 
                                              V_INACTIVE_RATE, 
                                              ', Effective Date: ', 
                                              V_INACTIVE_EFFECTIVE_DATE, 
                                              '. <br>  ' 
                                            );
      END IF;

      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          V_RETURNED_RATE_TEXT, 
                                          'Base Amount: ', 
                                          V_BASE_AMOUNT_TEXT, 
                                          '. <br>' 
                                        );


    ELSEIF ( V_RATE_MODE = 'tariff_rate_multiplier' ) THEN

      -- Multiplier
      SELECT multiplier into V_MULTIPLIER 
      FROM tariff WHERE id = V_REFERENCE_ID;
    
      SET V_RETURNED_RATE_TEXT = CONCAT( 
                                          'Rate Mode: Tariff Rate & Multiplier. <br>',
                                          'Active Rate: ',
                                          V_ACTIVE_RATE,
                                          ', Effective Date: ',
                                          V_ACTIVE_EFFECTIVE_DATE,
                                          '. <br>'
                                        );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT(
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;

      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          V_RETURNED_RATE_TEXT,
                                          'Multiplier: ', 
                                          V_MULTIPLIER, 
                                          '. <br>'
                                        );

    ELSEIF ( V_RATE_MODE = 'tariff_rate_discount' ) THEN

      -- Discount
      SELECT discount INTO V_DISCOUNT 
      FROM tariff WHERE id = V_REFERENCE_ID;
   
      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          'Rate Mode: Tariff Rate & Discount. <br>',
                                          'Active Rate: ',
                                          V_ACTIVE_RATE,
                                          ', Effective Date: ',
                                          V_ACTIVE_EFFECTIVE_DATE,
                                          '. <br>'
                                        );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT(
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;

      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          V_RETURNED_RATE_TEXT,
                                          'Discount: ', 
                                          V_DISCOUNT, 
                                          '. <br>' 
                                        );


    ELSEIF (V_RATE_MODE = 'rate_any') THEN
      
      SET V_RETURNED_RATE_TEXT = CONCAT(
                                        'Rate Mode: Either Rate. <br>',
                                        'Active Rate: ',
                                        V_ACTIVE_RATE,
                                        ', Effective Date: ',
                                        V_ACTIVE_EFFECTIVE_DATE,
                                        '. <br>'
                                      );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT(
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;

    ELSEIF ( V_RATE_MODE = 'rate_max' ) THEN

      SET V_RETURNED_RATE_TEXT = CONCAT(
                                        'Rate Mode: Maximum Rate. <br>',
                                        'Active Maximum Rate: ',
                                        V_ACTIVE_RATE,
                                        ', Effective Date: ',
                                        V_ACTIVE_EFFECTIVE_DATE,
                                        '. <br>'
                                    );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT(
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Maximum Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, '. <br>'
                                          );
      END IF;

    END IF;


  /**
   * referenct_type = 'contract'
   */
  ELSEIF ( V_REFERENCE_TYPE = CONST_CONTRACT_REFERENCE_TYPE ) THEN

    /**
     * Contract rules : 内部条件判断语句块
     */
    IF V_RATE_MODE = 'rate' THEN
     
      SET V_RETURNED_RATE_TEXT = CONCAT(
                                        'Rate Mode: Rate. <br>',
                                        'Active Rate: ',
                                        V_ACTIVE_RATE,
                                        ', Effective Date: ',
                                        V_ACTIVE_EFFECTIVE_DATE,
                                        '. <br>'
                                      );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT(
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;

    ELSEIF V_RATE_MODE = 'rate_any' THEN

      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          'Rate Mode: Either Rate. <br>',
                                          'Active Rate: ',
                                          V_ACTIVE_RATE,
                                          ', Effective Date: ',
                                          V_ACTIVE_EFFECTIVE_DATE,
                                          '. <br>'
                                        );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT(
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;

    ELSEIF V_RATE_MODE = 'contract_rate_by_quantity' THEN

      SELECT 
      GROUP_CONCAT(
                    CAST(crbq.quantity_begin AS CHAR) ,
                    ' ~ ', 
                    IFNULL(CAST(crbq.quantity_end AS CHAR), 'greater' )
                    ORDER BY crbq.quantity_begin
                    SEPARATOR ', ') INTO V_QUANTITY_TEXT
      FROM contract_rate_by_quantity crbq
      WHERE crbq.contract_id = V_REFERENCE_ID;


      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          'Rate Mode: Contract Rate By Volume. <br>', 
                                          'Volume & Rate: ', 
                                          '<br>  Volume: ', 
                                          V_QUANTITY_TEXT,
                                          '. <br>  ', 
                                          'Active Rate: ', 
                                          V_ACTIVE_RATE, 
                                          ', Effective Date: ', 
                                          V_ACTIVE_EFFECTIVE_DATE, 
                                          '. <br>  ' 
                                        );

       IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT(
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;

    END IF;


  /**
   * referenct_type = 'mtm'
   */
  ELSEIF (V_REFERENCE_TYPE = CONST_MTM_REFERENCE_TYPE) THEN

    /**
     * MtM rules : 内部条件判断语句块
     */
    IF V_RATE_MODE = 'rate' THEN

        
      SET V_RETURNED_RATE_TEXT = CONCAT(
                                          'Active Rate: ',
                                          V_ACTIVE_RATE,
                                          ', Effective Date: ',
                                          V_ACTIVE_EFFECTIVE_DATE,
                                          '. <br>'
                                        );

      IF V_INACTIVE_RATE IS NOT NULL THEN

        SET V_RETURNED_RATE_TEXT = CONCAT(
                                            V_RETURNED_RATE_TEXT,
                                            'Inactive Rate: ', 
                                            V_INACTIVE_RATE, 
                                            ', Effective Date: ', 
                                            V_INACTIVE_EFFECTIVE_DATE, 
                                            '. <br>' 
                                          );
      END IF;

    END IF;

  END
  IF;

  RETURN V_RETURNED_RATE_TEXT;


END