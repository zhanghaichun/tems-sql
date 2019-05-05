DROP PROCEDURE IF EXISTS SP_AUDIT_REFERENCE_MAPPING;
CREATE  PROCEDURE SP_AUDIT_REFERENCE_MAPPING(IN IN_INVOICE_ID INT(11))

BEGIN

  /**
   * Rate Module 验证匹配程序：
   * 主要的参考表是： audit_reference_mapping
   * 通过规则中的 key_field 来进行匹配，Bill&Keep BAN 通过 ban_id 来匹配。
   *
   * 在给出的 rules report 中，有一些规则是不能够应用于某些特殊的 BAN 的，
   * 具体细节参见 【Tariffs Rate Table File #2 v6.xlsx】
   * 新建一个 audit_reference_mapping_exclusion 表来完成这个任务，将对应
   * 的匹配结果剔除掉。
   */
  
  DECLARE V_BAN_ID                    INT;
  DECLARE V_VENDOR_ID                 INT;
  DECLARE V_KEY_FIELD                 VARCHAR(64);
  DECLARE V_STOP                      BOOLEAN DEFAULT FALSE;
   
  /**
   * 查询出来当前 vendor 的所有 key_field
   */
  DECLARE cur_record CURSOR FOR
    SELECT key_field
    FROM audit_reference_mapping arm
      INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
      INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id
    WHERE vgv.vendor_id = V_VENDOR_ID
      AND arm.rec_active_flag = 'Y'
      AND arm.key_field IS NOT NULL
    GROUP BY key_field
    ORDER BY key_field DESC;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_STOP = TRUE;

  /**
   * 通过 invoice_id 来查询 vendor_id 和 ban_id
   */
  SELECT i.ban_id, b.vendor_id
    INTO V_BAN_ID, V_VENDOR_ID
  FROM invoice i
    INNER JOIN ban b ON b.id = i.ban_id
  WHERE i.id = IN_INVOICE_ID;

  /**
   * 因为需要重新匹配，所以将账单中的匹配信息字段重置
   */
  UPDATE proposal p
  SET p.audit_reference_type_id = NULL,
      p.audit_reference_id = NULL,
      p.product_component_id = NULL,
      p.audit_reference_mapping_id = NULL
  WHERE p.invoice_id = IN_INVOICE_ID;
  
  SET V_STOP = FALSE;

  /**
   * 1. 创建临时表，存储 proposal_id 和 audit_reference_mapping_id 的对应关系。
   */
  DROP TABLE IF EXISTS tmp_proposal_reference_mapping;
  CREATE TEMPORARY TABLE tmp_proposal_reference_mapping(proposal_id INT, audit_reference_mapping_id INT);

  OPEN cur_record;

      

    LAB1:
    WHILE NOT V_STOP
      DO

        FETCH cur_record INTO V_KEY_FIELD;

        IF V_STOP THEN
         LEAVE LAB1;
        END IF;

        /**
         * 以下是多重条件语句块，目的是：向 tmp_proposal_reference_mapping 表中插入数据。
         */

        /**
         * key_field = 'usoc'
         */
        IF (V_KEY_FIELD = 'usoc' ) THEN
            
          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            LEFT JOIN invoice_item ii ON ii.id = p.invoice_item_id
            LEFT JOIN invoice i ON ii.invoice_id = i.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND arm.usoc = p.usoc
            AND (
                  (
                    POSITION('MRC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '13' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '3%'
                        )
                  )
                  OR
                  (
                    POSITION('OCC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '15' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '5%'
                        )
                  )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';
            
        /**
         * key_field = 'line_item_code'
         */
        ELSEIF (V_KEY_FIELD = 'line_item_code' ) THEN -- 2, 

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND REPLACE(ii.line_item_code, '/', '') = arm.line_item_code
            AND (
                  (
                    POSITION('MRC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '13' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '3%'
                        )
                  )
                  OR
                  (
                    POSITION('OCC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '15' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '5%'
                        )
                  )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';

        /**
         * key_field = 'line_item_code_description'
         */
        ELSEIF (V_KEY_FIELD = 'line_item_code_description' ) THEN

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND (
                  ii.line_item_code_description LIKE arm.line_item_code_description
                  OR 
                  ii.description LIKE arm.line_item_code_description
                )
            AND (
                  (
                    POSITION('MRC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '13' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '3%'
                        )
                  )
                  OR
                  (
                    POSITION('OCC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '15' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '5%'
                        )
                  )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';

          /**
           * 处理 charge_type 为 usage 类型的数据。
           */
          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID

            /**
             * 这种查询条件是为了避免 Excel 中提供的字段值和系统中相关字段值有出入的情况。
             */
            AND ( 
                  REPLACE(REPLACE(ii.line_item_code_description,'-',''),' ','') LIKE 
                    REPLACE( REPLACE(arm.line_item_code_description,'-',''),' ','' )
                  OR 
                  REPLACE(REPLACE(ii.description,'-',''),' ','') LIKE 
                    REPLACE( REPLACE(arm.line_item_code_description,'-',''),' ','' )
                )
            AND (
                  arm.charge_type = 'Usage' 
                  AND (
                        CONCAT(p.item_type_id ,'') = '14' 
                        OR 
                        CONCAT(p.item_type_id ,'') LIKE '4%'
                      )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1 
            AND ii.item_amount != 0
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';

        /**
         * key_field = 'item_description'
         */
        ELSEIF (V_KEY_FIELD = 'item_description') THEN

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, MAX(arm.id) FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND (
                  ii.description LIKE CONCAT('%',arm.item_description,'%')
                  OR 
                  ii.item_name LIKE CONCAT('%',arm.item_description,'%') 
                )
            AND (
                  (
                    POSITION('MRC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '13' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '3%'
                        )
                  )
                  OR
                  (
                    POSITION('OCC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '15' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '5%'
                        )
                  )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y'
            GROUP BY p.id
            ORDER BY arm.id DESC;


            /**
             * charge_type = 'Usage' 类型的数据
             */
            INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
            SELECT p.id, arm.id FROM proposal p
              INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
              INNER JOIN audit_reference_mapping arm
              INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
              INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

            WHERE vgv.vendor_id = V_VENDOR_ID
              AND p.invoice_id = IN_INVOICE_ID
              AND (
                    ii.description LIKE CONCAT('%',arm.item_description,'%')
                    OR 
                    ii.item_name LIKE CONCAT('%',arm.item_description,'%') 
                  )
              AND (
                    arm.charge_type = 'Usage' 
                    AND (
                          CONCAT(p.item_type_id ,'') = '14' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '4%'
                        )
                  )
              AND arm.key_field = V_KEY_FIELD
              AND p.proposal_flag = 1
              AND ii.item_amount != 0
              AND p.rec_active_flag = 'Y'
              AND arm.rec_active_flag = 'Y';

        /**
         * key_field = 'stripped_circuit_number'
         */
        ELSEIF (V_KEY_FIELD = 'stripped_circuit_number' ) THEN

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND ii.stripped_circuit_number LIKE arm.circuit_number
            AND (
                  (
                    POSITION('MRC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '13' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '3%'
                        )
                  )
                  OR
                  (
                    POSITION('OCC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '15' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '5%'
                        )
                  )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';

        /**
         * key_field = 'usoc & stripped_circuit_number'
         */
        ELSEIF (V_KEY_FIELD = 'usoc & stripped_circuit_number' ) THEN

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND ii.stripped_circuit_number LIKE arm.circuit_number
            AND ii.usoc = arm.usoc
            AND (
                  (
                    POSITION('MRC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '13' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '3%'
                        )
                  )
                  OR
                  (
                    POSITION('OCC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '15' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '5%'
                        )
                  )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';

        /**
         * key_field = 'stripped_circuit_number & line_item_code'
         */
        ELSEIF (V_KEY_FIELD = 'stripped_circuit_number & line_item_code' ) THEN

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND ii.stripped_circuit_number LIKE arm.circuit_number
            AND REPLACE(ii.line_item_code, '/', '') = arm.line_item_code
            AND (
                  (
                    POSITION('MRC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '13' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '3%'
                        )
                  )
                  OR
                  (
                    POSITION('OCC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '15' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '5%'
                        )
                  )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';

        /**
         * key_field = ''stripped_circuit_number & line_item_code_description'
         */
        ELSEIF (V_KEY_FIELD = 'stripped_circuit_number & line_item_code_description' ) THEN

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND ii.stripped_circuit_number LIKE arm.circuit_number
            AND ( 
                  (ii.line_item_code_description LIKE arm.line_item_code_description) 
                  OR 
                  (ii.description LIKE arm.line_item_code_description) 
                )
            AND (
                  (
                    POSITION('MRC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '13' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '3%'
                        )
                  )
                  OR
                  (
                    POSITION('OCC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '15' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '5%'
                        )
                  )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';


        /**
         * key_field = 'stripped_circuit_number & item_description'
         */
        ELSEIF (V_KEY_FIELD = 'stripped_circuit_number & item_description' ) THEN

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND ii.stripped_circuit_number LIKE arm.circuit_number
            AND ( 
                  (ii.description LIKE arm.item_description) 
                  OR 
                  (ii.item_name LIKE arm.item_description) 
                )
            AND (
                  (
                    POSITION('MRC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '13' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '3%'
                        )
                  )
                  OR
                  (
                    POSITION('OCC' IN arm.charge_type) > 0 
                    AND (
                          CONCAT(p.item_type_id ,'') = '15' 
                          OR 
                          CONCAT(p.item_type_id ,'') LIKE '5%'
                        )
                  )
                )
            AND arm.key_field = V_KEY_FIELD
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';

        /**
         * key_field = 'usage_item_type'
         */
        ELSEIF (V_KEY_FIELD = 'usage_item_type' ) THEN

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
            INNER JOIN vendor_group vg ON vg.id = arm.vendor_group_id
            INNER JOIN vendor_group_vendor vgv ON vgv.vendor_group_id = vg.id

          WHERE vgv.vendor_id = V_VENDOR_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND ii.charge_type = arm.usage_item_type
            AND (
                  arm.charge_type = 'Usage' 
                  AND (
                        CONCAT(p.item_type_id ,'') = '14' 
                        OR 
                        CONCAT(p.item_type_id ,'') LIKE '4%'
                      )
                )
            AND arm.key_field = V_KEY_FIELD
            AND ii.item_amount != 0
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';

        /**
         * key_field = 'bill_keep_ban'
         */
        ELSEIF (V_KEY_FIELD = 'bill_keep_ban' ) THEN 

          INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
          SELECT p.id, arm.id FROM proposal p
            INNER JOIN invoice_item ii ON p.invoice_item_id = ii.id
            INNER JOIN audit_reference_mapping arm
          WHERE arm.ban_id = V_BAN_ID
            AND p.invoice_id = IN_INVOICE_ID
            AND arm.key_field = V_KEY_FIELD
            AND ii.item_amount != 0
            AND p.proposal_flag = 1
            AND p.rec_active_flag = 'Y'
            AND arm.rec_active_flag = 'Y';

        END IF;

  
    END WHILE LAB1;

  CLOSE cur_record;

  /**
   * 下面的临时表转换，目的在于取 tmp_proposal_reference_mapping 表中重复数据的第一条。
   * 中间转换表是 tmp_proposal_reference_mapping_swap_table。
   */
  DROP TABLE IF EXISTS tmp_proposal_reference_mapping_swap_table;

  /**
   * 将数据复制到转换表中。
   */
  CREATE TEMPORARY TABLE tmp_proposal_reference_mapping_swap_table AS
  SELECT proposal_id, audit_reference_mapping_id FROM tmp_proposal_reference_mapping
  GROUP BY proposal_id;

  /**
   * 删除原表中的数据
   */
  DELETE FROM tmp_proposal_reference_mapping;

  /**
   * 将转换表中的数据重新插入到原表中。
   */
  INSERT INTO tmp_proposal_reference_mapping(proposal_id, audit_reference_mapping_id)
  SELECT proposal_id, audit_reference_mapping_id FROM tmp_proposal_reference_mapping_swap_table;

  /**
   * 禁止某个 BAN 应用某条验证规则。
   * 排除表： audit_reference_mapping_exclusion
   */
  DELETE tprm FROM tmp_proposal_reference_mapping tprm
    LEFT JOIN audit_reference_mapping_exclusion arme 
      ON tprm.audit_reference_mapping_id = arme.audit_reference_mapping_id
  WHERE 1 = 1
    AND arme.exclude_key_field = 'ban' 
    AND arme.ban_id = V_BAN_ID;

  /**
   * 禁止某些含有特定 item_description 的明细应用某条规则。
   * 排除表： audit_reference_mapping_exclusion
   */
  DELETE tprm FROM tmp_proposal_reference_mapping tprm
    LEFT JOIN audit_reference_mapping_exclusion arme 
      ON tprm.audit_reference_mapping_id = arme.audit_reference_mapping_id
    LEFT JOIN proposal p ON p.id = tprm.proposal_id
    LEFT JOIN invoice_item ii ON ii.id = p.invoice_item_id
  WHERE 1 = 1
    AND arme.exclude_key_field = 'item_description' 
    AND (
          ii.description LIKE CONCAT('%', arme.item_description ,'%')
          OR
          ii.item_name LIKE CONCAT('%', arme.item_description ,'%')
        );

  /**
   * 这个是整个 SQL 程序中最重要的一步，[更新]
   * 更新账单验证时需要的字段信息。
   */
  UPDATE proposal p,
         tmp_proposal_reference_mapping tprm,
         audit_reference_mapping arm

  SET p.audit_reference_type_id =
        IFNULL(arm.audit_reference_type_id, p.audit_reference_type_id),
      p.audit_reference_id =
        IFNULL(arm.audit_reference_id, p.audit_reference_id),
      p.audit_reference_mapping_id = tprm.audit_reference_mapping_id  

  WHERE p.id = tprm.proposal_id 
    AND tprm.audit_reference_mapping_id = arm.id;

  /**
   * 下面的程序用来更新 proposal 上的 product_component_id.
   * product 表中存储 product -> product_component 的对应关系，而且这种
   * 对应关系是唯一的。
   * proposal 明细中有 product_id 的数据才会更新 product_component_id.
   * audit_reference_mapping 表中 sub_product 就是 product_component.
   *
   * 除了更新 proposal 明细上的 product_component_id， 还有一种操作：
   * 就是当某个 product 与 product_component 的对应关系在 product_component
   * 表中不存在， 那么就将这条对应关系插入到 product_component 表中。
   */

  /**
   * 创建 product 与 product_component 的对应关系表，能插入到这个表中的数据
   * 代表 product 与 product_component 的对应关系在 product_component
   * 表中不存在。通过 left join 操作来实现的。
   */
  DROP TABLE IF EXISTS tmp_product_component;

  CREATE TEMPORARY table tmp_product_component AS
  SELECT p.product_id, arm.sub_product AS component_name
  FROM proposal p
    INNER JOIN tmp_proposal_reference_mapping tprm ON p.id = tprm.proposal_id
    INNER JOIN audit_reference_mapping arm ON tprm.audit_reference_mapping_id = arm.id
    LEFT JOIN product_component pc ON pc.component_name = arm.sub_product AND pc.product_id = p.product_id
  WHERE 1 = 1
    /**
     * 通过左连接再加上这个条件就能查询出 product_component 表中不存在的对应关系。
     */
    AND pc.id IS NULL
    /**
     * 必须首先确保明细中有 product, 才能添加 product_component.
     */
    AND p.product_id IS NOT NULL
  GROUP BY p.product_id;
    
  /**
   * 将 product_component 表中不存在的对应关系插入到该表中
   */
  INSERT INTO product_component (product_id , component_name, created_timestamp)
  SELECT product_id,component_name, current_timestamp
  FROM tmp_product_component;

  /**
   * 更新 proposal 明细的 product_conponent_id。
   */
  UPDATE proposal p, 
      tmp_proposal_reference_mapping tprm, 
      audit_reference_mapping arm, 
      product_component pc
  SET p.product_component_id = pc.id
  WHERE p.id = tprm.proposal_id -- proposal
      AND tprm.audit_reference_mapping_id = arm.id -- mapping record
      AND p.product_id = pc.product_id -- product id
      AND arm.sub_product = pc.component_name; -- product component id.
   
END