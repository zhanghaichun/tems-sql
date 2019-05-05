SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `rate_rule_tariff_original`
-- ----------------------------
DROP TABLE IF EXISTS `rate_rule_mtm_original`;
CREATE TABLE `rate_rule_mtm_original` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rec_active_flag` char(1) COLLATE utf8_unicode_ci DEFAULT 'Y',
  `sync_flag` char(1) COLLATE utf8_unicode_ci DEFAULT 'Y',
  `audit_reference_mapping_id` int(11) DEFAULT NULL,
  `audit_rate_period_id` int(11) DEFAULT NULL,
  `rate_status` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary_vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_field` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `stripped_circuit_number` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sub_product` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate` double(20,6) DEFAULT NULL,
  `rate_effective_date` date DEFAULT NULL,
  `term` varchar(16) DEFAULT NULL,
  `item_description` varchar(128) DEFAULT NULL,
  `line_item_code` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_timestamp` datetime DEFAULT NULL,
  `modified_timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
);


insert into rate_rule_mtm_original(
  `audit_reference_mapping_id`,
  `audit_rate_period_id`,
  `charge_type`,
  `key_field`,
  `rate_effective_date`,
  `summary_vendor_name`,
  `stripped_circuit_number`,
  `usoc`,
  `usoc_description`,
  `sub_product`,
  `line_item_code_description`,
  `line_item_code`,
  `item_description`,
  `rate`,
  `term`
)

SELECT
  arm.id as auditReferenceMappingId,
  arp.id as auditRatePeriodId,
  arm.charge_type AS chargeType,
  arm.key_field_original AS keyField,
  arp.start_date AS rateEffectiveDate,
  arm.summary_vendor_name AS summaryVendorName,
  arm.circuit_number,
  arm.usoc AS usoc,
  arm.usoc_description AS usocLongDescription,
  arm.sub_product AS subProduct,
  arm.line_item_code_description AS lineItemCodeDescription,
  arm.line_item_code AS lineItemCode,
  arm.item_description AS itemDescription,
  arp.rate AS rate,
  am.term

FROM
  audit_mtm am
LEFT JOIN audit_reference_mapping arm ON (
  arm.audit_reference_id = am.id
  AND arm.audit_reference_type_id = 18
)
LEFT JOIN audit_rate_period arp ON (
  arp.reference_table = 'audit_mtm'
  AND arp.reference_id = am.id
)
WHERE
  1 = 1
AND am.source = 'Rogers'
AND arm.rec_active_flag = 'Y'
AND arp.rec_active_flag = 'Y'
order by arp.id;