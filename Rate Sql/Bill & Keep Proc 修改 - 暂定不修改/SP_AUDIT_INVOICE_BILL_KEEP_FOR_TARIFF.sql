DROP PROCEDURE IF EXISTS SP_AUDIT_INVOICE_BILL_KEEP_FOR_TARIFF;
CREATE PROCEDURE SP_AUDIT_INVOICE_BILL_KEEP_FOR_TARIFF(V_INVOICE_ID INT)

BEGIN
  
  /**
   * BILL&KEEP 验证程序，规则存储在 rate module 中，核心对照表是 tariff_rate_by_bill_keep表. 
   *
   * bill_keep_ban 分为两种状态: Active & Inactive，它们都属于 bill_keep_ban, 验证类型都是 bill keep validation
   * 但是状态为 Inactive 的 ban, 相当于 no report, 验证结果应该是 Cannot validate.
   * 
   */
  DECLARE V_COUNT INT;
  DECLARE V_BAN_ID INT;
  DECLARE V_PROPOSAL_ID INT;
  DECLARE V_TARIFF_MAPPING_ID INT;
  DECLARE V_AUDIT_TARIFF_MAPPING_ID INT;
  DECLARE V_VENDOR_ID INT;
  DECLARE V_BILL_KEEP_BAN_TYPE INT;
  DECLARE V_REPORT_NAME VARCHAR(64);
  DECLARE V_PROVINCE_ACRONYM VARCHAR(64);
  DECLARE V_EXCHANGE VARCHAR(64);
  DECLARE V_ITEM_EXCHANGE VARCHAR(64);
  DECLARE V_ITEM_NAME VARCHAR(64);
  DECLARE V_TRIM_ITEM_NAME VARCHAR(64);
  DECLARE V_BILL_PROV VARCHAR(64);

  DECLARE V_BILL_IMBALANCE VARCHAR(64); -- 期望 imbalance: bill_keep 表中的 imbalance 字段.
  DECLARE V_IMBALANCE VARCHAR(64); -- 实际 imbalance： invoice_item 表中的 text01 字段.

  DECLARE V_BILL_EXCHANGE VARCHAR(64); -- 期望 trunk: bill_keep 表中的 dso_billable 字段.
  DECLARE V_TRUNKS VARCHAR(64); -- 实际 trunk: invoice_item 表中的 quantity 字段.
  
  DECLARE V_AUDIT_BILL_RATE DOUBLE(20,5) DEFAULT 0; -- 期望 rate： audit_rate_period 表中的 rate.
  DECLARE V_RATE DOUBLE(20,5) DEFAULT 0; -- 实际 rate: invoice_item 表中的 rate.

  DECLARE V_BILL_AMOUNT DOUBLE(20,5) DEFAULT 0; -- 期望 amount: 期望 trunk * 期望 rate.
  DECLARE V_ITEM_AMOUNT DOUBLE(20,5) DEFAULT 0; -- 实际 amount: invoice_item 表中的 item_amount.

  DECLARE V_BAN_STATUS VARCHAR(1); -- 当前 ban 的状态。'Y' | 'N'

  DECLARE V_VENDOR_ACRONYM VARCHAR(64);
  DECLARE V_AUDIT_STATUS_ID INT;
  DECLARE V_AUDIT_TRUNKS_STATUS_ID INT;
  DECLARE V_AUDIT_IMBALANCE_STATUS_ID INT;
  DECLARE V_AUDIT_RATE_STATUS_ID INT;
  DECLARE V_AUDIT_AMOUNT_STATUS_ID INT;
  DECLARE V_INVOICE_DATE VARCHAR(64);
  DECLARE V_AMOUNT_DIFFERENCE DOUBLE(20,5);
  DECLARE V_TRUNKS_DIFFERENCE DOUBLE(20,5);
  DECLARE V_DIFFERENCE_RATE DOUBLE(20,5);
  DECLARE V_NOTES VARCHAR(768);
  DECLARE V_FILE_NAME VARCHAR(512);
  DECLARE V_EFFECTIVE_DATE DATE; -- audit_rate_period 表中 start_date 字段， 有效期。
  DECLARE V_IMPORT_DATE DATE;
  DECLARE V_ATTACHMENT_POINT_ID INT;
  DECLARE V_NOTFOUND INT DEFAULT FALSE;

  DECLARE V_AUDIT_REFERENCE_MAPPING_ID INT; -- audit_reference_mapping 表中的 id 字段
  DECLARE V_TARIFF_ID INT; -- tariff_rate_by_bill_keep 表中的 tariff_id 字段。

	DECLARE V_PASS_COUNT INT;
	DECLARE V_FAIL_COUNT INT;
	DECLARE V_NO_REPORT_COUNT INT;
	DECLARE V_INVOICE_SUM_AMOUNT DOUBLE(20,5) DEFAULT 0;
	DECLARE V_BILL_SUM_AMOUNT DOUBLE(20,5) DEFAULT 0;
	DECLARE V_SUM_AMOUNT_DIFFERENCE DOUBLE(20,5);
	DECLARE IS_BILL_KEEP_BAN INT;

  DECLARE cur_invoice_item CURSOR FOR
    SELECT
            IFNULL(bkn.bill_keep_name,''),
            ABS(SUBSTRING_INDEX(ii.text01, '>', -1)),
            p.id,
            p.audit_reference_mapping_id,
            ii.item_name,
            REPLACE(ii.item_name,' ',''),
            ii.rate,
            ii.item_amount,
            ii.quantity,
            v.vendor_acronym,
            i.invoice_date,
            pr.province_acronym,
            bk.type

    FROM invoice_item ii
        LEFT JOIN proposal p ON p.invoice_item_id = ii.id
        LEFT JOIN province pr ON p.province_id = pr.id
        LEFT JOIN invoice i ON i.id = ii.invoice_id
        LEFT JOIN vendor v ON v.id = i.vendor_id
        LEFT JOIN bill_keep_ban bk ON bk.ban_id = i.ban_id
        LEFT JOIN bill_keep_name_contrast bkn ON REPLACE(ii.item_name,' ','')
            LIKE CONCAT('%',REPLACE(bkn.invoice_item_name,' ',''),'%') and bk.report_name = bkn.vendor

    WHERE ii.invoice_id = V_INVOICE_ID
        AND (
              ii.item_type_id IN(13,14,15,16,17)
              OR ii.item_type_id LIKE '3%'
              OR ii.item_type_id LIKE '5%'
              OR ii.item_type_id LIKE '6%'
              OR ii.item_type_id LIKE '7%'
        )
        AND ii.proposal_flag = 1
        AND ii.rec_active_flag = 'Y';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_NOTFOUND = TRUE;

  -- SQL 程序日志输出
  INSERT INTO event_journal (
                              event_type,
                              ip_address,
                              message_type,
                              event_message,
                              event_data,
                              created_timestamp,
                              created_by
                          )
    VALUES (
            'SP_AUDIT_INIVOICE_BILL_KEEP'
            ,V_INVOICE_ID
            ,'INFO'
            ,'Entering Processing Begin: '
            ,NULL
            ,current_timestamp
            ,0
        );

    -- 检索当前账单是否属于 bill keep ban 下的账单。
  SELECT COUNT(1), bk.rec_active_flag INTO V_COUNT, V_BAN_STATUS
  FROM invoice i INNER JOIN bill_keep_ban bk ON bk.ban_id = i.ban_id
  WHERE i.id = V_INVOICE_ID;

  IF V_COUNT > 0 THEN -- 如果当前账单属于 bill keep ban.

    /**
     * 用 invoice_id 检索账单 ban_id, vendor_id, bill_keep_ban 的 report name.
     * 这个 report name 其实就是 vendor name.
     */
    SELECT i.ban_id, i.vendor_id, bk.report_name INTO V_BAN_ID,V_VENDOR_ID,V_REPORT_NAME
    FROM invoice i INNER JOIN bill_keep_ban bk ON bk.ban_id = i.ban_id
    WHERE i.id = V_INVOICE_ID;

    -- 系统 sys_config 表中的 Trunks 差值
    SELECT value INTO V_TRUNKS_DIFFERENCE FROM sys_config WHERE parameter = 'audit_bill_keep_trunks';

    -- 系统 sys_config 表中的 Amount 差值
    SELECT value INTO V_AMOUNT_DIFFERENCE FROM sys_config WHERE parameter = 'audit_bill_keep_amount';

    OPEN cur_invoice_item; -- 开启游标

      read_loop: LOOP

        -- 游标赋值
        FETCH cur_invoice_item INTO
                              V_EXCHANGE,
                              V_IMBALANCE,
                              V_PROPOSAL_ID,
                              V_AUDIT_REFERENCE_MAPPING_ID,
                              V_ITEM_NAME,
                              V_TRIM_ITEM_NAME,
                              V_RATE,
                              V_ITEM_AMOUNT,
                              V_TRUNKS,
                              V_VENDOR_ACRONYM,
                              V_INVOICE_DATE,
                              V_PROVINCE_ACRONYM,
                              V_BILL_KEEP_BAN_TYPE;

        IF V_NOTFOUND THEN
            LEAVE read_loop;
        END IF;

        -- 重置 V_COUNT 变量， 因为每次循环都会使用这个变量。
        SET V_COUNT = 0;

        -- 到 bill_keep 表中检索符合条件的记录数。
        SELECT COUNT(1) INTO V_COUNT FROM bill_keep
        WHERE carrier = V_REPORT_NAME
            AND (lir_exchange = V_EXCHANGE OR REPLACE(lir_exchange,' ','') = V_TRIM_ITEM_NAME)
            AND bill_keep_ban_type = V_BILL_KEEP_BAN_TYPE
            AND (term_switch IS NULL OR term_switch = '')
            AND DATE_FORMAT(invoice_date,'%Y-%m') = DATE_FORMAT(V_INVOICE_DATE,'%Y-%m');

        /**
         * V_COUNT > 0: 代表系统中有对应 bill_keep_ban 的 report， 可以用来获取相应的期望值。
         * V_BAN_STATUS = 'Y': 代表当前 bill_keep_ban 的状态是 Active 的。
         */
        IF (V_COUNT > 0 && V_BAN_STATUS = 'Y') THEN 

          -- 到 bill_keep 表中检索所需信息。
          SELECT
            ROUND(dso_billable,0),
            ABS(imbalance),
            IFNULL(file_name,''),
            IFNULL(attachment_point_id,0)

            INTO
                V_BILL_EXCHANGE, -- 期望的 Trunk
                V_BILL_IMBALANCE, -- 期望的 Imbalance
                V_FILE_NAME,
                V_ATTACHMENT_POINT_ID

          FROM bill_keep
          WHERE carrier = V_REPORT_NAME
              AND (lir_exchange = V_EXCHANGE OR REPLACE(lir_exchange,' ','') = V_TRIM_ITEM_NAME)
              AND bill_keep_ban_type = V_BILL_KEEP_BAN_TYPE
              AND (term_switch IS NULL OR term_switch = '')
              AND DATE_FORMAT(invoice_date,'%Y-%m') = DATE_FORMAT(V_INVOICE_DATE,'%Y-%m');

          /**
           * 去 audit_reference_mapping 表中查询 audit_reference_id, 通过这个 audit_reference_id
           * 可以到 tariff_rate_ban_bill_keep 表中查询 bill keep ban tariff mapping 信息。
           */
          SELECT audit_reference_id INTO V_TARIFF_ID FROM audit_reference_mapping
          WHERE id = V_AUDIT_REFERENCE_MAPPING_ID;

          IF V_ATTACHMENT_POINT_ID != '' AND V_ATTACHMENT_POINT_ID != 0 THEN -- 如果存在 attachment_point_id
            
            /**
             * 当前判断语句的逻辑是在 invoice_notes 表中， 是否有当前账单对应的附件信息，
             * 如果有则什么都不做， 如果没有，则将 invoice_id 和 attachment_point_id 插入到该表中。
             */

            -- 同样是是否存在记录的查询
            SELECT COUNT(1) INTO V_COUNT
            FROM invoice_notes
            WHERE invoice_id = V_INVOICE_ID AND attachment_point_id = V_ATTACHMENT_POINT_ID;

            -- 如果相应记录不存在
            IF V_COUNT <= 0 THEN

              INSERT INTO invoice_notes (
                                          invoice_id,
                                          ban_id,
                                          notes,
                                          modified_timestamp,
                                          created_by,
                                          created_timestamp,
                                          attachment_point_id
                                        )
                VALUES (
                        V_INVOICE_ID,
                        V_BAN_ID,
                        V_FILE_NAME,
                        now(),
                        0,
                        now(),
                        V_ATTACHMENT_POINT_ID
                    );

            END IF;

          END IF;
          
          /**
           * ~~~ BILL KEEP Trunk validation.
           */
          IF V_TRUNKS <= V_BILL_EXCHANGE * (1 + V_TRUNKS_DIFFERENCE) AND V_TRUNKS >= 
              V_BILL_EXCHANGE * (1 - V_TRUNKS_DIFFERENCE) THEN

            SET V_AUDIT_TRUNKS_STATUS_ID = 1;
          ELSE
            SET V_AUDIT_TRUNKS_STATUS_ID = 2;
          END IF;

          -- 计算 Trunk 差异率
          SET V_DIFFERENCE_RATE = (V_TRUNKS - V_BILL_EXCHANGE) / V_BILL_EXCHANGE;

          IF V_BILL_EXCHANGE = 0 AND V_TRUNKS != 0 THEN
            SET V_DIFFERENCE_RATE = 1;
          END IF;

          -- bill_keep trunk validation 描述信息。
          SET V_NOTES = CONCAT(
                                'Bill Keep - Validation: Trunk. </br>The tolerance rate is ',
                                CONCAT( ROUND(V_TRUNKS_DIFFERENCE*100),
                                '% </br>Difference rate is ',
                                FORMAT(V_DIFFERENCE_RATE*100,2),'%')
                              );

          -- 插入验证结果
          INSERT INTO audit_result (
                                      invoice_id,
                                      proposal_id,
                                      audit_status_id,
                                      audit_source_id,
                                      actual_amount,
                                      expect_amount,
                                      audit_reference_type_id,
                                      notes,
                                      created_timestamp,
                                      created_by
                                    )

          VALUES (
                    V_INVOICE_ID,
                    V_PROPOSAL_ID,
                    V_AUDIT_TRUNKS_STATUS_ID,
                    '10001',
                    V_TRUNKS,
                    V_BILL_EXCHANGE,
                    11,
                    V_NOTES ,
                    now(),
                    0
                  );

          /**
           * ~~~ BILL KEEP Imbalance validation
           * 在做 imbalance validation 的时候分为两种情况，一种是期望 imbalance > 10, 另一种是期望 imbalance <= 10.
           * 而且查询期望 rate 和 effective date 的时候也是在这一步。
           */

          -- 重置期望 rate。
          SET V_AUDIT_BILL_RATE = 0;

          IF V_BILL_IMBALANCE > 10 THEN -- 期望 imbalance > 10

            /**
             * 1. 根据期望 imbalance 去 tariff_rate_by_bill_keep 表中查找对应的 imbalance 范围记录 id.
             * 2. 同时也关联了 audit_rate_period 表， 查找对应的期望 rate 和 effective date, 后面的 rate validation,
             *    和 amount validation 会用到。
             */
            SELECT trbk.id, IFNULL(arp.rate, 0), arp.start_date
              INTO V_AUDIT_TARIFF_MAPPING_ID, V_AUDIT_BILL_RATE, V_EFFECTIVE_DATE
            FROM tariff_rate_by_bill_keep trbk 
              LEFT JOIN audit_rate_period arp ON trbk.id = arp.reference_id 
                AND arp.reference_table = 'tariff_rate_by_bill_keep'
            WHERE trbk.tariff_id = V_TARIFF_ID
              AND IF (V_BILL_IMBALANCE < 10, 10, V_BILL_IMBALANCE) >= trbk.imbalance_start
              AND IF (V_BILL_IMBALANCE >= 100, 99, V_BILL_IMBALANCE) < trbk.imbalance_end
              AND V_BILL_EXCHANGE >= trbk.trunk_start
              AND ( V_BILL_EXCHANGE <= trbk.trunk_end OR trbk.trunk_start = trbk.trunk_end)
              AND (trbk.province = V_PROVINCE_ACRONYM OR trbk.province = '' OR trbk.province IS NULL)
              AND arp.start_date <= V_INVOICE_DATE
            ORDER BY arp.start_date DESC LIMIT 1;
 
            -- 根据实际 imbalance 去 tariff_rate_by_bill_keep 表中查找对应的 imbalance 范围记录 id
            SELECT id INTO V_TARIFF_MAPPING_ID
            FROM tariff_rate_by_bill_keep
            WHERE tariff_id = V_TARIFF_ID
                AND IF (V_IMBALANCE < 10, 10, V_IMBALANCE) >= imbalance_start
                AND IF (V_IMBALANCE >= 100, 99, V_IMBALANCE) < imbalance_end
                AND V_TRUNKS >= trunk_start
                AND ( V_TRUNKS <= trunk_end OR trunk_start = trunk_end)
                AND (province = V_PROVINCE_ACRONYM OR province = '' OR province IS NULL)
                LIMIT 1;

            /**
             * 如果期望 imbalance 和 实际 imbalance 都落在同一个范围内， 则验证成功。
             * 通过对比实际 imbalance 和 期望 imbalance 求出的记录 id 是否相同即可得出验证结果。
             */
            IF V_TARIFF_MAPPING_ID = V_AUDIT_TARIFF_MAPPING_ID THEN
              SET V_AUDIT_IMBALANCE_STATUS_ID = 1;
            ELSE
              SET V_AUDIT_IMBALANCE_STATUS_ID = 2;
            END IF;

          ELSE -- 期望 imbalance <= 10

            -- 将期望 imbalance 值重置为 0
            SET V_BILL_IMBALANCE = 0;

            -- 根据实际 Imbalance 值来判断验证结果。
            IF V_IMBALANCE <= 10 THEN
              SET V_AUDIT_IMBALANCE_STATUS_ID = 1;
            ELSE
              SET V_AUDIT_IMBALANCE_STATUS_ID = 2;
            END IF;

          END IF;

          -- 插入 bill keep imbalance validation 结果。
          INSERT INTO audit_result (
                                      invoice_id,
                                      proposal_id,
                                      audit_status_id,
                                      audit_source_id,
                                      actual_amount,
                                      expect_amount,
                                      audit_reference_type_id,
                                      notes,
                                      created_timestamp,
                                      created_by
                                    )

          VALUES (
                  V_INVOICE_ID,
                  V_PROPOSAL_ID,
                  V_AUDIT_IMBALANCE_STATUS_ID,
                  '10002',
                  V_IMBALANCE,
                  V_BILL_IMBALANCE,
                  11,
                  'Bill Keep - Validation: Imbalance' ,
                  now(),
                  0
                );

          /**
           * ~~~ BILL KEEP Rate Validation
           */
          
          IF V_AUDIT_BILL_RATE = V_RATE THEN
              SET V_AUDIT_RATE_STATUS_ID = 1;
          ELSE
              SET V_AUDIT_RATE_STATUS_ID = 2;
          END IF;

          -- 向 audit_result 表中插入审计结果。
          INSERT INTO audit_result (
                                      invoice_id,
                                      proposal_id,
                                      audit_status_id,
                                      audit_source_id,
                                      actual_amount,
                                      expect_amount,
                                      rate,
                                      rate_effective_date,
                                      audit_reference_type_id,
                                      notes,
                                      created_timestamp,
                                      created_by
                                    )
          VALUES (
                  V_INVOICE_ID,
                  V_PROPOSAL_ID,
                  V_AUDIT_RATE_STATUS_ID,
                  '10003',
                  V_RATE,
                  V_AUDIT_BILL_RATE,
                  V_AUDIT_BILL_RATE,
                  V_EFFECTIVE_DATE,
                  11,
                  'Bill Keep - Validation: Rate' ,
                  now(),
                  0
                );

          /**
           * ~~~ BILL KEEP Amount Validation.
           */
          IF V_AUDIT_BILL_RATE > 0 THEN
            SET V_BILL_AMOUNT = V_BILL_EXCHANGE * V_AUDIT_BILL_RATE;
          ELSE
            SET V_BILL_AMOUNT = 0;
          END IF;

          -- 在误差允许的范围内比较实际 amount 和 期望 amount.
          IF V_ITEM_AMOUNT <= V_BILL_AMOUNT * (1 + V_AMOUNT_DIFFERENCE)
              AND V_ITEM_AMOUNT >= V_BILL_AMOUNT * (1 - V_AMOUNT_DIFFERENCE) THEN

              SET V_AUDIT_AMOUNT_STATUS_ID = 1;
          ELSE
              SET V_AUDIT_AMOUNT_STATUS_ID = 2;
          END IF;

          -- 计算 amount 差异率。
          SET V_DIFFERENCE_RATE = (V_ITEM_AMOUNT - V_BILL_AMOUNT) / V_BILL_AMOUNT;

          IF V_BILL_AMOUNT = 0 AND V_ITEM_AMOUNT != 0 THEN
            SET V_DIFFERENCE_RATE = 1;
          END IF;

          -- BILL KEEP Amount Validation 描述信息
          SET V_NOTES = CONCAT(
                                'Bill Keep - Validation: Amount. </br>The tolerance rate is ',
                                concat(round(V_AMOUNT_DIFFERENCE*100),
                                '% </br>Difference rate is ',
                                FORMAT(V_DIFFERENCE_RATE*100,2),'%')
                              );

          -- 插入验证结果
          INSERT INTO audit_result (
                                      invoice_id,
                                      proposal_id,
                                      audit_status_id,
                                      audit_source_id,
                                      actual_amount,
                                      expect_amount,
                                      rate,
                                      rate_effective_date,
                                      audit_reference_type_id,
                                      notes,
                                      created_timestamp,
                                      created_by
                                  )
          VALUES (
                    V_INVOICE_ID,
                    V_PROPOSAL_ID,
                    V_AUDIT_AMOUNT_STATUS_ID,
                    '10004',
                    V_ITEM_AMOUNT,
                    V_BILL_AMOUNT,
                    V_AUDIT_BILL_RATE,
                    V_EFFECTIVE_DATE,
                    11,
                    V_NOTES ,
                    now(),
                    0
                );

        ELSE 

          /**
           * ELSE 情况分为两种情况：
           * 1，对于这个账单 不存在 bill keep reference report.
           * 2，可能在系统中对于这个 bill_keep_ban 是有 report 的，但是这个 ban 的状态是 Inactive.
           */

          SET V_AUDIT_STATUS_ID = 3;
          SET V_NOTES = 'There is no report.';

          -- BILL KEEP Trunk no report 审计结果。
          INSERT INTO audit_result (
                                      invoice_id,
                                      proposal_id,
                                      audit_status_id,
                                      audit_source_id,
                                      actual_amount,
                                      expect_amount,
                                      audit_reference_type_id,
                                      notes,
                                      created_timestamp,
                                      created_by
                                    )
          VALUES (
                    V_INVOICE_ID,
                    V_PROPOSAL_ID,
                    V_AUDIT_STATUS_ID,
                    '10001',
                    V_TRUNKS,
                    null,
                    11,
                    V_NOTES ,
                    now(),
                    0
                  );


          -- BILL KEEP Imbalance no report 审计结果。
          INSERT INTO audit_result (
                                      invoice_id,
                                      proposal_id,
                                      audit_status_id,
                                      audit_source_id,
                                      actual_amount,
                                      expect_amount,
                                      audit_reference_type_id,
                                      notes,
                                      created_timestamp,
                                      created_by
                                  )
          VALUES (
                    V_INVOICE_ID,
                    V_PROPOSAL_ID,
                    V_AUDIT_STATUS_ID,
                    '10002',
                    NULL,
                    null,
                    11,
                    V_NOTES ,
                    now(),
                    0
              );

          -- BILL KEEP Rate no report 审计结果。
          INSERT INTO audit_result (
                                      invoice_id,
                                      proposal_id,
                                      audit_status_id,
                                      audit_source_id,
                                      actual_amount,
                                      expect_amount,
                                      rate,
                                      rate_effective_date,
                                      audit_reference_type_id,
                                      notes,
                                      created_timestamp,
                                      created_by
                                    )
          VALUES (
                    V_INVOICE_ID,
                    V_PROPOSAL_ID,
                    V_AUDIT_STATUS_ID,
                    '10003',
                    V_RATE,
                    NULL,
                    NULL,
                    NULL,
                    11,
                    V_NOTES ,
                    now(),
                    0
                  );

          -- BILL KEEP Amount no report 审计结果。
          INSERT INTO audit_result (
                                      invoice_id,
                                      proposal_id,
                                      audit_status_id,
                                      audit_source_id,
                                      actual_amount,
                                      expect_amount,
                                      rate,
                                      rate_effective_date,
                                      audit_reference_type_id,
                                      notes,
                                      created_timestamp,
                                      created_by
                                    )
          VALUES (
                    V_INVOICE_ID,
                    V_PROPOSAL_ID,
                    V_AUDIT_STATUS_ID,
                    '10004',
                    V_ITEM_AMOUNT,
                    NULL,
                    NULL,
                    NULL,
                    11,
                    V_NOTES ,
                    now(),
                    0
                  );
        END IF;

        END LOOP;
        CLOSE cur_invoice_item;

  END IF;


	SELECT
				SUM(ii.item_amount) INTO V_INVOICE_SUM_AMOUNT
		FROM invoice_item ii
		WHERE ii.invoice_id = V_INVOICE_ID
				AND (
							ii.item_type_id IN(13,14,15,16,17)
							OR ii.item_type_id LIKE '3%'
							OR ii.item_type_id LIKE '5%'
							OR ii.item_type_id LIKE '6%'
							OR ii.item_type_id LIKE '7%'
				)
				AND ii.proposal_flag = 1
				AND ii.rec_active_flag = 'Y';

	SELECT
				COUNT(1) INTO V_PASS_COUNT
		FROM audit_result
		WHERE invoice_id = V_INVOICE_ID
				AND audit_source_id = 10004
				AND audit_status_id = 1;

	SELECT
				COUNT(1) INTO V_FAIL_COUNT
		FROM audit_result
		WHERE invoice_id = V_INVOICE_ID
				AND audit_source_id = 10004
				AND audit_status_id = 2;

	SELECT
				COUNT(1) INTO V_NO_REPORT_COUNT
		FROM audit_result
		WHERE invoice_id = V_INVOICE_ID
				AND audit_source_id = 10004
				AND audit_status_id = 3;

	
	SELECT
				SUM(expect_amount) INTO V_BILL_SUM_AMOUNT
		FROM audit_result
		WHERE invoice_id = V_INVOICE_ID
				AND audit_source_id = 10004;

	SET V_DIFFERENCE_RATE = (V_INVOICE_SUM_AMOUNT - V_BILL_SUM_AMOUNT) / V_BILL_SUM_AMOUNT;
	IF V_BILL_SUM_AMOUNT = 0 AND V_INVOICE_SUM_AMOUNT != 0 THEN
		SET V_DIFFERENCE_RATE = 1;
	END IF;


	SET V_NOTES = CONCAT('</br>Bill Keep Item Passed: ',V_PASS_COUNT,' record(s)',
																		'</br>Bill Keep Item Failed: ',V_FAIL_COUNT,' record(s)',
																		'</br>Bill Keep Cannot Validate: ',V_NO_REPORT_COUNT,' record(s)',
																		'</br>The tolerance rate is ', ROUND(V_SUM_AMOUNT_DIFFERENCE*100),'%',
																		'</br>Difference rate is ', FORMAT(V_DIFFERENCE_RATE*100,2),'%');

	IF V_INVOICE_SUM_AMOUNT <= V_BILL_SUM_AMOUNT * (1 + V_SUM_AMOUNT_DIFFERENCE)
			AND V_INVOICE_SUM_AMOUNT >= V_BILL_SUM_AMOUNT * (1 - V_SUM_AMOUNT_DIFFERENCE) THEN

			SET V_AUDIT_AMOUNT_STATUS_ID = 1;
	ELSE
			SET V_AUDIT_AMOUNT_STATUS_ID = 2;
	END IF;


	INSERT INTO audit_result (
															invoice_id,
															audit_status_id,
															audit_source_id,
															actual_amount,
															expect_amount,
															rate,
															rate_effective_date,
															audit_reference_type_id,
															notes,
															created_timestamp,
															created_by
													)
	VALUES (
							V_INVOICE_ID,
							V_AUDIT_AMOUNT_STATUS_ID,
							'10009',
							V_INVOICE_SUM_AMOUNT,
							V_BILL_SUM_AMOUNT,
							NULL,
							NULL,
							11,
							V_NOTES ,
							now(),
							0
			);
  -- 事件跟踪。
  INSERT INTO event_journal (
                              event_type,
                              ip_address,
                              message_type,
                              event_message,
                              event_data,
                              created_timestamp,
                              created_by
                          )
    VALUES (
            'SP_AUDIT_INIVOICE_BILL_KEEP'
            ,V_INVOICE_ID
            ,'INFO'
            ,'Exiting Processing End'
            ,NULL
            ,current_timestamp
            ,0
        );

  COMMIT;
END

