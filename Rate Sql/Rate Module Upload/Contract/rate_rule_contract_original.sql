SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `rate_rule_tariff_original`
-- ----------------------------
DROP TABLE IF EXISTS `rate_rule_contract_original`;
CREATE TABLE `rate_rule_contract_original` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rec_active_flag` char(1) COLLATE utf8_unicode_ci DEFAULT 'Y',
  `sync_flag` char(1) COLLATE utf8_unicode_ci DEFAULT 'Y',
  `audit_reference_mapping_id` int(11) DEFAULT NULL,
  `audit_rate_period_id` int(11) DEFAULT NULL,
  `rate_status` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary_vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_field` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `stripped_circuit_number` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sub_product` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate` double(20,6) DEFAULT NULL,
  `rate_effective_date` date DEFAULT NULL,
  `term_months` varchar(16) DEFAULT NULL,
  `renewal_term_after_term_expiration` varchar(16) DEFAULT NULL,
  `early_termination_fee` varchar(255) DEFAULT NULL,
  `item_description` varchar(128) DEFAULT NULL,
  `contract_name` varchar(500) DEFAULT NULL,
  `contract_service_schedule_name` varchar(128) DEFAULT NULL,
  `line_item_code` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `total_volume_begin` int DEFAULT NULL,
  `total_volume_end` int DEFAULT NULL,
  `mmbc` varchar(32) DEFAULT NULL,
  `discount` double(20, 5) DEFAULT NULL, 
  `notes` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_timestamp` datetime DEFAULT NULL,
  `modified_timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
);

update audit_rate_period
set end_date = '2018-07-16'
where reference_table = 'contract'
and reference_id = 5170;

insert into audit_rate_period(reference_table, reference_id, start_date)
values('contract', 5170, '2018-07-17');

insert into rate_rule_contract_original(
  audit_reference_mapping_id,
  audit_rate_period_id,
  summary_vendor_name,
  charge_type,
  key_field,
  usoc,
  usoc_description,
  stripped_circuit_number,
  sub_product,
  rate,
  rate_effective_date,
  term_months,
  renewal_term_after_term_expiration,
  early_termination_fee,
  item_description,
  contract_name,
  contract_service_schedule_name,
  line_item_code,
  line_item_code_description,
  total_volume_begin,
  total_volume_end,
  mmbc,
  discount
)

SELECT
    arm.id,
    arp.id,
    arm.summary_vendor_name AS summaryVendorName,
    arm.charge_type AS chargeType,
    arm.key_field_original AS keyField,
    arm.usoc AS usoc,
    arm.usoc_description AS usocLongDescription,
    arm.circuit_number AS strippedCircuitNumber,
    arm.sub_product AS subProduct,
    arp.rate AS rate,
    arp.start_date AS effectiveDate,
    cf.term_quantity AS term,
    cf.renewal_term_after_term_expiration,
    cf.penalty_initial_percent,
    arm.item_description AS itemDescription,
    cf.contract_number AS contractNumberOrTariffReference,
    c.schedule,
    arm.line_item_code AS lineItemCode,
    arm.line_item_code_description AS lineItemCodeDescription,
    crbq.quantity_begin AS quantityBegin,
    crbq.quantity_end AS quantityEnd,
    c.mmbc,
    c.discount
  FROM
    contract c
  LEFT JOIN contract_file cf ON c.contract_file_id = cf.id
  LEFT JOIN (
    SELECT
      t.id AS contract_id,
      'contract' AS reference_table,
      t.id AS reference_id
    FROM
      contract t
    WHERE
      t.rate_mode <> 'contract_rate_by_quantity'
    UNION
      SELECT
        t.id AS contract_id,
        'contract_rate_by_quantity' AS reference_table,
        crbq.id AS reference_id
      FROM
        contract t
      LEFT JOIN contract_rate_by_quantity crbq ON crbq.contract_id = t.id
      WHERE
        t.rate_mode = 'contract_rate_by_quantity'
  ) refer ON c.id = contract_id
  LEFT JOIN contract_rate_by_quantity crbq ON (
    refer.reference_table = 'contract_rate_by_quantity'
    AND refer.reference_id = crbq.id
  )
  LEFT JOIN audit_reference_mapping arm ON (
    c.id = arm.audit_reference_id
    AND arm.audit_reference_type_id = 3
  )
  LEFT JOIN audit_rate_period arp ON (
    arp.reference_table = refer.reference_table
    AND arp.reference_id = refer.reference_id
  )
  WHERE
    1 = 1
  AND c.source = 'Rogers'
  AND c.rec_active_flag = 'Y'
  AND arm.rec_active_flag = 'Y'
  AND arp.rec_active_flag = 'Y';


update rate_rule_contract_original
set early_termination_fee = '50% of the monthly remaining fees'
where early_termination_fee is not null;

update rate_rule_contract_original
set early_termination_fee = '50% of $998.75 x remaining contract period'
where stripped_circuit_number in ('02LMXQ00400549LMXQ000067UCN001', '02LVXX00009249LVXX000007UCN001');

update rate_rule_contract_original
set early_termination_fee = '50% of $594 x remaining contract period'
where stripped_circuit_number in ('05LVXX00063899LVXX000355UCN001');

update rate_rule_contract_original
set early_termination_fee = '50% of $350 x remaining contract period'
where stripped_circuit_number in ('57LVXX00000702LVXX001406UCN001');

update rate_rule_contract_original
set early_termination_fee = '25% of the monthly remaining fees'
where rec_active_flag = 'Y'
and stripped_circuit_number = 'WLLXFA000016HTJ';

update rate_rule_contract_original
set discount = 0.10
where rec_active_flag = 'Y'
and key_field like '%CVPP%'
and rate_effective_date = '2017-07-17';

update rate_rule_contract_original
set discount = 0.11
where rec_active_flag = 'Y'
and key_field like '%CVPP%'
and rate_effective_date = '2018-07-17';



