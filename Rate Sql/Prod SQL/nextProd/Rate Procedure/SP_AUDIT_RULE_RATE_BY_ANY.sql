DROP PROCEDURE IF EXISTS SP_AUDIT_RULE_RATE_BY_ANY;
CREATE PROCEDURE `SP_AUDIT_RULE_RATE_BY_ANY`( IN PARAM_REFERENCE_ID INT,
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

  DECLARE V_EXPECT_RATE DOUBLE (20, 5);
  DECLARE V_EXPECT_AMOUNT DOUBLE (20, 5);

  DECLARE V_EXPECT_AMOUNT_NOTES VARCHAR(256);
  DECLARE V_COUNT INT DEFAULT 0;
  DECLARE V_QUANTITY INT(32) DEFAULT 1;

  DECLARE V_DONE BOOLEAN DEFAULT FALSE;


  DECLARE V_EITHER_RATE_CURSOR CURSOR FOR 
      SELECT arp.rate
      FROM audit_rate_period arp
      WHERE arp.reference_table = PARAM_REFERENCE_TABLE
        AND arp.reference_id = PARAM_REFERENCE_ID
        AND V_RATE_DATE >= arp.start_date
        AND (CASE
             WHEN arp.end_date IS NOT NULL
             THEN
                V_RATE_DATE < arp.end_date
             ELSE
                arp.end_date IS NULL
          END)
        ORDER BY arp.rate DESC;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_DONE = TRUE; 


  SET V_RATE_DATE = ( SELECT FN_GET_RATE_DATE(PARAM_PROPOSAL_ID) );
  

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
                                FN_TRANSFORM_NOTES_RATE(arp.rate)
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

    SET V_EXPECT_AMOUNT_NOTES = 'and expect amount is ';
    SET V_COUNT = 0;

    SELECT IFNULL(quantity,1) INTO V_QUANTITY
    FROM proposal WHERE id = PARAM_PROPOSAL_ID;

    SET V_DONE = FALSE; 

    OPEN V_EITHER_RATE_CURSOR;
      
      LABEL1: 
      WHILE NOT V_DONE
      DO 
        FETCH V_EITHER_RATE_CURSOR INTO V_EXPECT_RATE;


        IF (V_DONE) THEN
          LEAVE LABEL1;
        END IF;

        SET V_EXPECT_AMOUNT = V_EXPECT_RATE * V_QUANTITY;

        IF (V_COUNT > 0) THEN

          SET V_EXPECT_AMOUNT_NOTES = CONCAT(
            V_EXPECT_AMOUNT_NOTES, 
            ' or $',  
            FN_TRANSFORM_NOTES_RATE(V_EXPECT_AMOUNT) 
          );
          
        ELSE

          SET V_EXPECT_AMOUNT_NOTES = CONCAT(
            V_EXPECT_AMOUNT_NOTES, 
            '$',  
            FN_TRANSFORM_NOTES_RATE(V_EXPECT_AMOUNT) 
          );

        END IF;

        SET V_COUNT = V_COUNT + 1;

      END WHILE LABEL1;
    CLOSE V_EITHER_RATE_CURSOR;

    SET PARAM_NOTES = CONCAT(PARAM_NOTES, ', ', V_EXPECT_AMOUNT_NOTES, '.');

  ELSE 

    SET PARAM_NOTES = CONCAT(PARAM_NOTES, '.');

  END IF;

END