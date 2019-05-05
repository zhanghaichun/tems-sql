DROP PROCEDURE IF EXISTS SP_AUDIT_TARIFF_RATE_BY_QUANTITY;
CREATE PROCEDURE `SP_AUDIT_TARIFF_RATE_BY_QUANTITY`(  IN PARAM_TARIFF_ID INT,
                                                    IN PARAM_QUANTITY INT(32),
                                                    IN PARAM_TARIFF_RATE_MODE VARCHAR(128),
                                                    IN PARAM_PROPOSAL_ID INT,
                                                    OUT PARAM_EXPECT_RATE DOUBLE(20, 5),
                                                    OUT PARAM_BASE_AMOUNT DOUBLE(20, 5),
                                                    OUT PARAM_NOTES VARCHAR ( 768 ),
                                                    OUT PARAM_RATE_EFFECTIVE_DATE DATE
                                                  )
BEGIN

  -- 这个存储过程用来获取 rate_mode 为 "tariff_rate_by_quantity"
  -- 的rate， 和 rate_effective_date.
    DECLARE V_TABLE_ID INT;

    SELECT trbq.id ,trbq.base_amount
        INTO V_TABLE_ID, PARAM_BASE_AMOUNT
    FROM
        tariff_rate_by_quantity trbq
    WHERE trbq.tariff_id = PARAM_TARIFF_ID
    -- 根据quantity的范围来选出相应的rate.
    AND trbq.quantity_begin <= PARAM_QUANTITY
    AND (trbq.quantity_end >= PARAM_QUANTITY OR trbq.quantity_end IS NULL);


    CALL SP_GET_RATE_KEY_FIELDS( 'tariff_rate_by_quantity',
                                    V_TABLE_ID,
                                    PARAM_PROPOSAL_ID,
                                    PARAM_EXPECT_RATE,
                                    PARAM_RATE_EFFECTIVE_DATE );


    
    IF (PARAM_EXPECT_RATE IS NOT NULL) THEN

        SET PARAM_NOTES = CONCAT('The rate is $', FN_TRANSFORM_NOTES_RATE(PARAM_EXPECT_RATE) );
        
        IF (PARAM_TARIFF_RATE_MODE = 'tariff_rate_by_quantity_base_amount') THEN

          SET PARAM_NOTES = CONCAT(PARAM_NOTES,
                                    ' , The base amount is $',
                                    FN_TRANSFORM_NOTES_RATE(PARAM_BASE_AMOUNT) );

        ELSEIF (PARAM_TARIFF_RATE_MODE = 'tariff_rate_by_quantity_rate_max') THEN

          SET PARAM_NOTES = CONCAT('The maximum rate is $', FN_TRANSFORM_NOTES_RATE(PARAM_EXPECT_RATE) );

        END IF;

    END IF;

END