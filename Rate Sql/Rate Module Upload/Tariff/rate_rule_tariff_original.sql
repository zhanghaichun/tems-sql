
SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `rate_rule_tariff_original`
-- ----------------------------
DROP TABLE IF EXISTS `rate_rule_tariff_original`;
CREATE TABLE `rate_rule_tariff_original` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rec_active_flag` char(1) COLLATE utf8_unicode_ci DEFAULT 'Y',
  `sync_flag` char(1) COLLATE utf8_unicode_ci DEFAULT 'Y',
  `audit_reference_mapping_id` int(11) DEFAULT NULL,
  `audit_rate_period_id` int(11) DEFAULT NULL,
  `rate_status` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_field` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate_effective_date` date DEFAULT NULL,
  `summary_vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sub_product` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_description` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `quantity_begin` int(11) DEFAULT NULL,
  `quantity_end` int(11) DEFAULT NULL,
  `tariff_file_name` varchar(42) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tariff_name` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `base_amount` double(20,5) DEFAULT NULL,
  `multiplier` double(20,5) DEFAULT NULL,
  `rate` double(20,6) DEFAULT NULL,
  `rules_details` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tariff_page` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `part_section` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_number` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `crtc_number` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `discount` double(20,5) DEFAULT NULL,
  `exclusion_ban` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `exclusion_item_description` varchar(256) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_timestamp` datetime DEFAULT NULL,
  `modified_timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
);


/**
 * 向数据表中插入数据
 */
insert into rate_rule_tariff_original(
  `audit_reference_mapping_id`,
  `audit_rate_period_id`,
  `charge_type`,
  `key_field`,
  `rate_effective_date`,
  `summary_vendor_name`,
  `vendor_name`,
  `usoc`,
  `usoc_description`,
  `sub_product`,
  `line_item_code_description`,
  `line_item_code`,
  `item_type`,
  `item_description`,
  `quantity_begin`,
  `quantity_end`,
  `tariff_file_name`,
  `tariff_name`,
  `base_amount`,
  `multiplier`,
  `rate`,
  `rules_details`,
  `tariff_page`,
  `part_section`,
  `item_number`,
  `crtc_number`,
  `discount` 
)

SELECT
  arm.id as auditReferenceMappingId,
  arp.id as auditRatePeriodId,
  arm.charge_type AS chargeType,
  arm.key_field_original AS keyField,
  arp.start_date AS rateEffectiveDate,
  arm.summary_vendor_name AS summaryVendorName,
  arm.vendor_name AS vendorName,
  arm.usoc AS usoc,
  arm.usoc_description AS usocLongDescription,
  arm.sub_product AS subProduct,
  arm.line_item_code_description AS lineItemCodeDescription,
  arm.line_item_code AS lineItemCode,
  arm.usage_item_type AS itemType,
  arm.item_description AS itemDescription,
  trbq.quantity_begin AS quantityBegin,
  trbq.quantity_end AS quantityEnd,
  tf.tariff_name,
  t.name AS contractNumberOrTariffReference,
  trbq.base_amount AS baseAmount,
  t.multiplier AS multiplier,
  arp.rate AS rate,
  arp.rules_details AS rulesDetails,
  t.page AS tariffPage,
  t.part_section AS partOrSection,
  t.item_number AS itemNumber,
  SUBSTRING(
    tf.tariff_name,
    INSTR(
      tf.tariff_name,
      TRIM(
        REVERSE(
          - (- REVERSE(tf.tariff_name))
        )
      )
    )
  ) AS crtcNumber,
  t.discount AS discount

FROM
  tariff t
LEFT JOIN (
  SELECT
    t.id AS tariff_id,
    'tariff' AS reference_table,
    t.id AS reference_id
  FROM
    tariff t
  WHERE
    t.rate_mode NOT IN (
      'tariff_rate_by_quantity',
      'tariff_rate_by_quantity_base_amount',
      'tariff_rate_by_quantity_rate_max'
    )
  UNION
    SELECT
      t.id AS tariff_id,
      'tariff_rate_by_quantity' AS reference_table,
      trbq.id AS reference_id
    FROM
      tariff t
    LEFT JOIN tariff_rate_by_quantity trbq ON trbq.tariff_id = t.id
    WHERE
      t.rate_mode IN (
        'tariff_rate_by_quantity',
        'tariff_rate_by_quantity_base_amount',
        'tariff_rate_by_quantity_rate_max'
      )
) refer ON t.id = tariff_id
LEFT JOIN tariff_file tf ON t.tariff_file_id = tf.id
LEFT JOIN tariff_rate_by_quantity trbq ON (
  refer.reference_id = trbq.id
  AND refer.reference_table = 'tariff_rate_by_quantity'
)
LEFT JOIN audit_reference_mapping arm ON (
  arm.audit_reference_id = t.id
  AND arm.audit_reference_type_id = 2
)
LEFT JOIN audit_rate_period arp ON (
  arp.reference_table = refer.reference_table
  AND arp.reference_id = refer.reference_id
)
WHERE
  1 = 1
AND t.source = 'Rogers'
and arm.key_field <> 'bill_keep_ban'
and arp.reference_table <> 'tariff_rate_by_bill_keep'
and t.rate_mode <> 'tariff_rate_by_bill_keep'
AND t.rec_active_flag = 'Y'
AND arm.rec_active_flag = 'Y'
AND arp.rec_active_flag = 'Y'
order by arp.id;

/**
 * 更新 exclusion
 */
update rate_rule_tariff_original
set exclusion_item_description = 'CREDIT FOR ACCESS SERVICE REMOVED'
where summary_vendor_name = 'bell canada'
and usoc = 'U91PN';

update rate_rule_tariff_original
set exclusion_ban = '505038603'
where line_item_code in ('NBISGAS00009', 'NBISGAS00002', 'NBISGAS00005');



