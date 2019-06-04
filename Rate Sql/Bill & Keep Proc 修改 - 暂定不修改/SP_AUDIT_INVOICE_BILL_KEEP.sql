DROP PROCEDURE IF EXISTS SP_AUDIT_INVOICE_BILL_KEEP;
CREATE PROCEDURE SP_AUDIT_INVOICE_BILL_KEEP(V_INVOICE_ID INT)

BEGIN
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
  DECLARE V_IMBALANCE VARCHAR(64);
  DECLARE V_ITEM_EXCHANGE VARCHAR(64);
  DECLARE V_ITEM_NAME VARCHAR(64);
  DECLARE V_TRIM_ITEM_NAME VARCHAR(64);
  DECLARE V_BILL_EXCHANGE VARCHAR(64);
  DECLARE V_BILL_PROV VARCHAR(64);
  DECLARE V_BILL_IMBALANCE VARCHAR(64);
  DECLARE V_AUDIT_BILL_RATE DOUBLE(20,5) DEFAULT 0;
  DECLARE V_BILL_AMOUNT DOUBLE(20,5) DEFAULT 0;
  DECLARE V_RATE DOUBLE(20,5) DEFAULT 0;
  DECLARE V_ITEM_AMOUNT DOUBLE(20,5) DEFAULT 0;
  DECLARE V_TRUNKS VARCHAR(64);
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
  DECLARE V_EFFECTIVE_DATE DATE;
  DECLARE V_IMPORT_DATE DATE;
  DECLARE V_ATTACHMENT_POINT_ID INT;
  DECLARE V_NOTFOUND INT DEFAULT FALSE;
  DECLARE V_START_IMBALANCE INT DEFAULT 10;

  DECLARE V_PASS_COUNT INT;
  DECLARE V_FAIL_COUNT INT;
  DECLARE V_NO_REPORT_COUNT INT;
  DECLARE V_INVOICE_SUM_AMOUNT DOUBLE(20,5) DEFAULT 0;
  DECLARE V_BILL_SUM_AMOUNT DOUBLE(20,5) DEFAULT 0;
  DECLARE V_SUM_AMOUNT_DIFFERENCE DOUBLE(20,5);
  DECLARE IS_BILL_KEEP_BAN INT;
  

    -- 查询游标数据集
    DECLARE cur_invoice_item CURSOR FOR
        SELECT
                IFNULL(bkn.bill_keep_name,''),
                ABS(SUBSTRING_INDEX(ii.text01, '>', -1)),
                p.id,
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

  
  SELECT COUNT(1) INTO IS_BILL_KEEP_BAN  FROM bill_keep_ban bk LEFT JOIN invoice i ON bk.ban_id = i.ban_id WHERE i.id = V_INVOICE_ID;

  IF IS_BILL_KEEP_BAN > 0 THEN
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

    -- 查询属于 bill keep ban 下的账单数量
    SELECT COUNT(1) INTO V_COUNT
    FROM invoice i
       INNER JOIN bill_keep_ban bk ON bk.ban_id = i.ban_id
    WHERE i.id = V_INVOICE_ID
        AND bk.rec_active_flag = 'Y';

    -- 根据账单数量，采用不用的逻辑处理

  IF V_COUNT > 0 THEN -- 如果账单数量大于 0

        -- 根据账单 ID 查询 ban 相关信息。
    SELECT i.ban_id, i.vendor_id, bk.report_name
            INTO V_BAN_ID,V_VENDOR_ID,V_REPORT_NAME
        FROM invoice i
            INNER JOIN bill_keep_ban bk ON bk.ban_id = i.ban_id
        WHERE i.id = V_INVOICE_ID;

        -- 系统 sys_config 表中的 Trunks 差值
    SELECT value INTO V_TRUNKS_DIFFERENCE
        FROM sys_config WHERE parameter = 'audit_bill_keep_trunks';

        -- 系统 sys_config 表中的 Amount 差值
    SELECT value INTO V_AMOUNT_DIFFERENCE
        FROM sys_config WHERE parameter = 'audit_bill_keep_amount';

        -- 合计金额误差率
    SELECT value INTO V_SUM_AMOUNT_DIFFERENCE
        FROM sys_config WHERE parameter = 'audit_tolerance_rate_bill_keep';

    IF V_BAN_ID = 9194 THEN
      SET V_START_IMBALANCE = 20;
    END IF;
    
    OPEN cur_invoice_item; -- 开启游标

            read_loop: LOOP

                -- 游标赋值
                FETCH cur_invoice_item INTO
                                            V_EXCHANGE,
                                            V_IMBALANCE, -- 实际 Imbalance.
                                            V_PROPOSAL_ID,
                                            V_ITEM_NAME,
                                            V_TRIM_ITEM_NAME,
                                            V_RATE,
                                            V_ITEM_AMOUNT,
                                            V_TRUNKS, -- 实际 Trunk.
                                            V_VENDOR_ACRONYM,
                                            V_INVOICE_DATE,
                                            V_PROVINCE_ACRONYM,
                                            V_BILL_KEEP_BAN_TYPE;

                IF V_NOTFOUND THEN
                    LEAVE read_loop;
                END IF;

                -- 重置 V_COUNT 变量， 因为每次循环
                -- 都会使用这个变量。
                SET V_COUNT = 0;

                -- 根据条件去 bill_keep 表中检索记录数
                -- 需要判断当前账单是否是 Bill Keep ban 的。
        SELECT COUNT(1) INTO V_COUNT
                FROM bill_keep
                WHERE carrier = V_REPORT_NAME
                    AND (lir_exchange = V_EXCHANGE OR REPLACE(lir_exchange,' ','') = V_TRIM_ITEM_NAME)
                    AND bill_keep_ban_type = V_BILL_KEEP_BAN_TYPE
                    AND (term_switch IS NULL OR term_switch = '')
                    AND DATE_FORMAT(invoice_date,'%Y-%m') = DATE_FORMAT(V_INVOICE_DATE,'%Y-%m');

                -- 根据条数来采用不同的处理逻辑

        IF V_COUNT > 0 THEN -- 如果条数大于 0 时, 存在 bill keep report.

                    -- 使用和以上查询条数相同的 where 条件
                    -- 来查询相关信息
                    -- 保证了只有在有记录的情况下才会进一步去查询结果集。
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

                    -- 如果 V_ATTACHMENT_POINT_ID 有值而且值不为 0， 则采用
                    -- 下面的逻辑
          IF V_ATTACHMENT_POINT_ID != '' AND V_ATTACHMENT_POINT_ID != 0 THEN
              -- 这个 IF 语句块中的逻辑是：
              -- 对应 invoice id 和 attachment point id
              -- 在 invoice_notes 表中是否存在，
              -- 如果不存在就插入。

              -- 同样是是否存在记录的查询
            SELECT COUNT(1) INTO V_COUNT
            FROM invoice_notes
            WHERE invoice_id = V_INVOICE_ID
                AND attachment_point_id = V_ATTACHMENT_POINT_ID;

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

                    -- *** BILL KEEP Trunk validation.

                    -- 实际的 Trunk 为账单明细的 quantity,
                    -- V_BILL_EXCHANGE即为 "DSO billable" 列的值，
                    -- 为期望的 Trunk.
                    -- 将这一列的值作为 Trunk, 来进行对比
                    -- 对比的时候，只要差值在系统误差允许的范围内，
                    -- 那么结果都算 Passed. 否则结果就为 Failed.
                    -- 系统误差为 5%.
          IF V_TRUNKS <= V_BILL_EXCHANGE * (1 + V_TRUNKS_DIFFERENCE)
              AND V_TRUNKS >= V_BILL_EXCHANGE * (1 - V_TRUNKS_DIFFERENCE) THEN

                        SET V_AUDIT_TRUNKS_STATUS_ID = 1;
                    ELSE
            SET V_AUDIT_TRUNKS_STATUS_ID = 2;
          END IF;

                    -- 计算 Trunk 差异率
          SET V_DIFFERENCE_RATE = (V_TRUNKS - V_BILL_EXCHANGE) / V_BILL_EXCHANGE;

                    -- 如果期望 Trunk = 0 且 实际 Trunk ！= 0
                    -- 那么将差异率设置为 100%。
          IF V_BILL_EXCHANGE = 0 AND V_TRUNKS != 0 THEN
            SET V_DIFFERENCE_RATE = 1;
          END IF;

                    -- 变量赋值
          -- 描述 Trunk 相关信息
          SET V_NOTES = CONCAT(
                                            'Bill Keep - Validation: Trunk. </br>The tolerance rate is ',
                                            CONCAT( ROUND(V_TRUNKS_DIFFERENCE*100),
                                            '% </br>Difference rate is ',
                                            FORMAT(V_DIFFERENCE_RATE*100,2),'%')
                              );

                    -- 向 audit_result 表中插入验证结果，
                    -- Bill Keep Trunk validation: audit_source_id => 10001
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

                    --  *** BILL KEEP Imbalance validation
                    -- 重置期望金额, 接下来的 Rate 验证会用到。
          SET V_AUDIT_BILL_RATE = 0;

          -- V_BILL_IMBALANCE 为 Bill Keep report中的
          -- imbalance

          IF V_BILL_IMBALANCE > V_START_IMBALANCE THEN -- 当 imbalance 数 大于 10

                        -- 通过条件检索记录，
                        -- 返回查询记录的条数， 如果有相应记录的话
                        -- 按照 effective_date 返回最新的一条记录。
                        SELECT COUNT(1)
                            INTO V_COUNT
                        FROM bill_keep_ban_tariff_mapping
                        WHERE ban_id = V_BAN_ID
                            AND IF (V_BILL_IMBALANCE<V_START_IMBALANCE,V_START_IMBALANCE,V_BILL_IMBALANCE) >= imbalance_start
                            AND IF (V_BILL_IMBALANCE>=100,99,V_BILL_IMBALANCE) < imbalance_end
                            -- imbalance 和 trunk 进行比较
                            AND V_BILL_EXCHANGE >= trunk_start
                            AND ( V_BILL_EXCHANGE <= trunk_end or trunk_start = trunk_end)
                            AND (territory = V_PROVINCE_ACRONYM or territory = '' or territory is NULL)
                            AND STR_TO_DATE(effective_date,"%Y/%m/%d") <= DATE_FORMAT(V_INVOICE_DATE,"%Y/%m/%d")
                            ORDER BY effective_date DESC
                            LIMIT 1;

                        -- 如果检索到了记录
                        -- 事实上就是证明存在相应的记录
                        -- 这里是通过系统中原有的 imbalance
                        -- 来查询 tariff mapping id的。
            IF V_COUNT > 0 THEN

                            -- 以相同的检索条件，检索
                            -- 出相关信息。

                            -- V_AUDIT_BILL_RATE 是期望 rate,
                            -- 根据期望 Trunk 和 期望 Imbalance 来作为检索条件。
                            -- V_AUDIT_BILL_RATE， V_EFFECTIVE_DATE 是用于 Rate
                            -- 验证结果的输出。
                            SELECT id,IFNULL(rate,0), effective_date
                            INTO V_AUDIT_TARIFF_MAPPING_ID,V_AUDIT_BILL_RATE,V_EFFECTIVE_DATE
                            FROM bill_keep_ban_tariff_mapping
                            WHERE ban_id = V_BAN_ID
                                AND IF (V_BILL_IMBALANCE<V_START_IMBALANCE,V_START_IMBALANCE,V_BILL_IMBALANCE) >= imbalance_start
                                AND IF (V_BILL_IMBALANCE>=100,99,V_BILL_IMBALANCE) < imbalance_end
                                AND V_BILL_EXCHANGE >= trunk_start
                                AND ( V_BILL_EXCHANGE <= trunk_end or trunk_start = trunk_end)
                                AND (territory = V_PROVINCE_ACRONYM or territory = '' or territory is NULL)
                                AND STR_TO_DATE(effective_date,"%Y/%m/%d") <= DATE_FORMAT(V_INVOICE_DATE,"%Y/%m/%d")
                                ORDER BY effective_date DESC
                                LIMIT 1;

            END IF;

                        -- 以多个检索条件判断记录是否存在
                        -- 用到了 明细中的 quantity.
                        SELECT COUNT(1)
                            INTO V_COUNT
                        FROM bill_keep_ban_tariff_mapping
                        WHERE ban_id = V_BAN_ID
                            AND IF (V_IMBALANCE<V_START_IMBALANCE,V_START_IMBALANCE,V_IMBALANCE) >= imbalance_start
                            AND IF (V_IMBALANCE>=100,99,V_IMBALANCE) < imbalance_end
                            AND V_TRUNKS >= trunk_start
                            AND ( V_TRUNKS <= trunk_end or trunk_start = trunk_end)
                            AND (territory = V_PROVINCE_ACRONYM or territory = '' or territory is NULL)
                            AND STR_TO_DATE(effective_date,"%Y/%m/%d") <= DATE_FORMAT(V_INVOICE_DATE,"%Y/%m/%d")
                            ORDER BY effective_date DESC
                            LIMIT 1;

                        -- 如果上面检索到了记录
                        -- 这里通过明细中给出的 quantity
                        -- 来检索 tariff mapping id
            IF V_COUNT > 0 THEN

                            -- 同样是根据上面的检索条件检索相关
                            -- 信息。
                            SELECT id
                                INTO V_TARIFF_MAPPING_ID
                            FROM bill_keep_ban_tariff_mapping
                            WHERE ban_id = V_BAN_ID
                                AND IF (V_IMBALANCE<V_START_IMBALANCE,V_START_IMBALANCE,V_IMBALANCE) >= imbalance_start
                                AND IF (V_IMBALANCE>=100,99,V_IMBALANCE) < imbalance_end
                                AND V_TRUNKS >= trunk_start
                                AND ( V_TRUNKS <= trunk_end or trunk_start = trunk_end)
                                AND (territory = V_PROVINCE_ACRONYM or territory = '' or territory is NULL)
                                AND STR_TO_DATE(effective_date,"%Y/%m/%d") <= DATE_FORMAT(V_INVOICE_DATE,"%Y/%m/%d")
                                ORDER BY effective_date DESC
                                LIMIT 1;

            END IF;


            -- 判断两个 tariff mapping id 是否能够对应得上
            -- 一个是账单明细中给出的，通过 quantity 来检索到的。
            -- 一个是系统中存在的， 用到了 invoice date。
            IF V_TARIFF_MAPPING_ID = V_AUDIT_TARIFF_MAPPING_ID THEN
              SET V_AUDIT_IMBALANCE_STATUS_ID = 1;
            ELSE
              SET V_AUDIT_IMBALANCE_STATUS_ID = 2;
            END IF;

          ELSE -- 当 imbalance 数 小于等于 10

                        -- 将期望 imbalance 值重置为 0
            SET V_BILL_IMBALANCE = 0;

                        -- 根据实际 Imbalance 来输出
                        -- Imbalance 验证审计结果。
            IF V_IMBALANCE <= V_START_IMBALANCE THEN
              SET V_AUDIT_IMBALANCE_STATUS_ID = 1;
            ELSE
              SET V_AUDIT_IMBALANCE_STATUS_ID = 2;
            END IF;

          END IF;

                    -- 向 audit_result 表中插入审计
                    -- 结果
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

                    -- *** BILL KEEP Rate Validation
                    -- 实际 rate 与 期望 rate 做对比
                    -- V_AUDIT_BILL_RATE: 期望 rate
                    -- V_RATE: 实际 rate。
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

                    -- *** BILL KEEP Amount Validation.
          IF V_AUDIT_BILL_RATE > 0 THEN
              -- 期望 amount = 期望 Trunk * 期望 Rate.
            SET V_BILL_AMOUNT = V_BILL_EXCHANGE * V_AUDIT_BILL_RATE;
          ELSE
            SET V_BILL_AMOUNT = 0;
          END IF;

                    -- 在误差范围内比较 实际 amount 值和
                    -- 期望 amount 值。
                    -- V_ITEM_AMOUNT： 实际 amount.
                    -- V_BILL_AMOUNT: 期望 amount.
                    -- V_AMOUNT_DIFFERENCE: 误差范围 5%
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

                    -- BILL KEEP Amount Validation 说明信息
          SET V_NOTES = CONCAT(
                                  'Bill Keep - Validation: Amount. </br>The tolerance rate is ',
                                  concat(round(V_AMOUNT_DIFFERENCE*100),
                                  '% </br>Difference rate is ',
                                  FORMAT(V_DIFFERENCE_RATE*100,2),'%')
                              );

                    -- 向 audit_result 表中插入审计结果
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

        ELSE -- 对于这个账单 不存在 bill keep report.

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
                            V_IMBALANCE,
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
  END IF;
END