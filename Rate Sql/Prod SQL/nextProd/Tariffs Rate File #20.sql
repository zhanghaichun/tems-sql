select max(id) from tariff; -- 903 (0.71 环境上)
select max(id) from tariff; -- 899 (UAT 环境上)

insert into tariff(id, tariff_file_id, name, rate_mode, page, part_section,  item_number, source, created_timestamp)
values(900, 33, 'Bell Aliant GT/21491/6/612/4(b)', 'rate', '607.5', '6', '612', 'rogers', now()),
(901, 29, 'Bell GT/6716/2/70/4', 'rate', '51-1C.1', '2', '70', 'rogers', now()),
(902, 30, 'Bell SFT 7396/G/G21/(d)(1)a', 'rate', 'G21.4', 'G', 'G21', 'rogers', now()),
(903, 30, 'Bell SFT 7396/G/G21/(d)(1)a', 'rate', 'G21.4', 'G', 'G21', 'rogers', now()),
(904, 30, 'Bell SFT 7396/G/G21/(d)(1)a', 'rate', 'G21.4', 'G', 'G21', 'rogers', now()),
(905, 29, 'Bell GT/6716/2/1400/6e', 'rate', '137E-1', '2', '1400', 'rogers', now());

select max(id) from audit_reference_mapping; -- 7265 (0.71 环境上)
select max(id) from audit_reference_mapping; -- 7192 (UAT 环境上)

insert into audit_reference_mapping(vendor_group_id, summary_vendor_name, key_field, key_field_original, charge_type, sub_product, usoc, usoc_description, item_description, audit_reference_type_id, audit_reference_id, created_timestamp)
values(1, 'BELL CANADA', 'usoc', 'USOC & SVN','MRC', 'Access', 'CKA1B', 'NB CDN ACCESS DS-1, BAND B', NULL, 2, 900, now()),
( 1, 'BELL CANADA', 'usoc', 'USOC & SVN','MRC', 'Megalink', 'MLFPT', 'Bell Relay Charge on Megalink PSTN', NULL, 2, 901 , now()),
( 1, 'BELL CANADA', 'item_description', 'Item Description & SVN','OCC', '911', null, null, '%NAS E911%', 2, 902 , now()),
( 1, 'BELL CANADA', 'item_description', 'Item Description & SVN','OCC', '911', null, null, '%PH II%', 2, 903, now() ),
( 1, 'BELL CANADA', 'item_description', 'Item Description & SVN','OCC', '911', null, null, '%NAS T911%', 2, 904, now() ),
( 1, 'BELL CANADA', 'item_description', 'Item Description & SVN','OCC', 'Access', null, null,'%NAS CNT%', 2, 905, now() );


select max(id) from audit_rate_period; -- 14888 (0.71 环境上)
select max(id) from audit_rate_period; -- 15891 (UAT 环境上)

insert into audit_rate_period(reference_table, reference_id, start_date, end_date, rate, rules_details)
  values('tariff', 900, '2015-10-18', null, 79.38, 'CDN Access – DS-1 } Band B, NB'),
  ('tariff', 901, '2017-08-17', null, 0.13, '4. Bell Canada Relay Service (BCRS) - Megalink service, each PSTN Connection'),
  ('tariff', 902, '2016-04-28', null, 0.0184, '1 Wireless Service Provider Enhanced 911 Service a. Phase I'),
  ('tariff', 903, '2016-04-28', null, 0.0191, '1 Wireless Service Provider Enhanced 911 Service b. Phase II'),
  ('tariff', 904, '2016-04-28', null, 0.0028, '1 Wireless Service Provider Enhanced 911 Service c. T9-1-1 Service'),
  ('tariff', 905, '2019-01-01', null, 0.06, 'Wireless Access services'),
  ('tariff', 905, '2017-01-01', '2018-12-31',0.0065, 'Wireless Access services');

  select max(id) from rate_rule_tariff_original; -- 947(0.71 环境上)
  select max(id) from rate_rule_tariff_original; -- 1029(UAT 环境上)

