
/**
 * 首先是修改 UAT 环境上的数据。
 *
 * audit_reference_mapping_id: 279 293 5969 6011 7141 7142
 */

-- summary vendor name 或 vendor name 中含有 ' or ' 关键字的数据。
select * from audit_reference_mapping
where rec_active_flag = 'Y'
  and (summary_vendor_name like '% or %' or vendor_name like '% or %');


-- 
update audit_reference_mapping
set vendor_group_id = 93, vendor_name = 'TELUS (AGT)'
where id = 279;

INSERT INTO audit_reference_mapping(`vendor_group_id`, `ban_id`, `summary_vendor_name`, `vendor_name`, `key_field`, `key_field_original`, `charge_type`, `usoc`, `usoc_description`, `sub_product`, `line_item_code`, `line_item_code_description`, `usage_item_type`, `circuit_number`, `service_description`, `item_description`, `audit_reference_type_id`, `old_audit_reference_id`, `audit_reference_id`, `product_id`, `product_component_id`, `notes`, `created_timestamp`, `created_by`, `modified_timestamp`, `modified_by`, `rec_active_flag`) VALUES (108, NULL, 'TELUS', 'TELUS COMMUNICATIONS INC.', 'line_item_code', 'Line Item Code & SVN & VN', 'MRC', NULL, NULL, 'Call Display', '8071', 'PRI CALL DISPLAY*', NULL, NULL, NULL, NULL, 2, 562, 562, NULL, NULL, NULL, '2018-5-9 11:12:08', NULL, NULL, NULL, 'Y');

-- update rate_rule_tariff_original
-- set vendor_name = 'TELUS (AGT)'
-- where id = 268;

/*INSERT INTO rate_rule_tariff_original VALUES (1030, 'Y', 'Y', 7193, 1721, 'Active', 'MRC', 'Line Item Code & SVN & VN', '2009-6-1', 'TELUS', 'TELUS COMMUNICATIONS INC.', NULL, NULL, 'Call Display', 'PRI CALL DISPLAY*', '8071', NULL, NULL, NULL, NULL, 'Telus GT/18001', 'Telus GT/18001/495/4(c)', NULL, NULL, 3.000000, 'c. Other Optional Features for Access and Link Connections:\n(Available only on ISDN-PRI) > Call Display', '403', '', '495', '18001', NULL, NULL, NULL, NULL, NULL, NULL);*/

-- 
update audit_reference_mapping
set vendor_group_id = 93, vendor_name = 'TELUS (AGT)'
where id = 293;

insert into vendor_group
values(116, 'TELUS (ED)', '289', 'TELUS (ED) vendor');

insert into vendor_group_vendor(vendor_group_id, vendor_id)
values(116, 289);

INSERT INTO audit_reference_mapping(`vendor_group_id`, `ban_id`, `summary_vendor_name`, `vendor_name`, `key_field`, `key_field_original`, `charge_type`, `usoc`, `usoc_description`, `sub_product`, `line_item_code`, `line_item_code_description`, `usage_item_type`, `circuit_number`, `service_description`, `item_description`, `audit_reference_type_id`, `old_audit_reference_id`, `audit_reference_id`, `product_id`, `product_component_id`, `notes`, `created_timestamp`, `created_by`, `modified_timestamp`, `modified_by`, `rec_active_flag`) VALUES ( 116, NULL, 'TELUS', 'TELUS (ED)', 'usoc', 'USOC & SVN & VN', 'MRC', 'TPPS9', 'EMERGENCY SERVICE 9-1-1, TRUNKS BETWEEN', 'Trunks', NULL, NULL, NULL, NULL, NULL, NULL, 2, 576, 576, NULL, NULL, NULL, '2018-5-9 11:20:34', NULL, NULL, NULL, 'Y');
/*
update rate_rule_tariff_original
set vendor_name = 'TELUS (AGT)'
where id in (282, 591);

INSERT INTO rate_rule_tariff_original VALUES (1031, 'Y', 'Y', 7194, 1735, 'Inactive', 'MRC', 'USOC & SVN & VN', '2017-6-1', 'TELUS', 'TELUS (ED)', 'TPPS9', 'EMERGENCY SERVICE 9-1-1, TRUNKS BETWEEN      ', 'Trunks', NULL, NULL, NULL, NULL, NULL, NULL, 'Telus GT/18008', 'Telus GT/18008/215/4.2 (iv) (2) (ii)', NULL, NULL, 39.380000, 'ii) 9-1-1 tandem trunks between the CLEC’s local switch and the Company’s 9-1-1 tandem switch', '51', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO rate_rule_tariff_original VALUES (1032, 'Y', 'Y', 7194, 8475, 'Active', 'MRC', 'USOC & SVN & VN', '2018-6-1', 'TELUS', 'TELUS (ED)', 'TPPS9', 'EMERGENCY SERVICE 9-1-1, TRUNKS BETWEEN      ', 'Trunks', NULL, NULL, NULL, NULL, NULL, NULL, 'Telus GT/18008', 'Telus GT/18008/215/4.2 (iv) (2) (ii)', NULL, NULL, 39.020000, 'ii) 9-1-1 tandem trunks between the CLEC’s local switch and the Company’s 9-1-1 tandem switch', '51', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);*/

-- 
update audit_reference_mapping
set vendor_group_id = 93, vendor_name = 'TELUS (AGT)'
where id = 5969;

insert into vendor_group
values(117, 'TELUS', '284', 'TELUS vendor');

insert into vendor_group_vendor(vendor_group_id, vendor_id)
values(117, 284);

INSERT INTO audit_reference_mapping(`vendor_group_id`, `ban_id`, `summary_vendor_name`, `vendor_name`, `key_field`, `key_field_original`, `charge_type`, `usoc`, `usoc_description`, `sub_product`, `line_item_code`, `line_item_code_description`, `usage_item_type`, `circuit_number`, `service_description`, `item_description`, `audit_reference_type_id`, `old_audit_reference_id`, `audit_reference_id`, `product_id`, `product_component_id`, `notes`, `created_timestamp`, `created_by`, `modified_timestamp`, `modified_by`, `rec_active_flag`) VALUES ( 116, NULL, 'TELUS', 'TELUS (ED)', 'usoc', 'USOC & SVN & VN & Qty', 'MRC', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, NULL, NULL, 2, 804, 804, NULL, NULL, NULL, '2018-6-29 02:08:06', NULL, '2018-9-4 21:50:04', NULL, 'Y'),
( 117, NULL, 'TELUS', 'Telus', 'usoc', 'USOC & SVN & VN & Qty', 'MRC', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, NULL, NULL, 2,804,  804, NULL, NULL, NULL, '2018-6-29 02:08:06', NULL, '2018-9-4 21:50:04', NULL, 'Y');

/*update rate_rule_tariff_original
set vendor_name = 'TELUS (AGT)'
where id between 688 and 692;

INSERT INTO rate_rule_tariff_original VALUES (1033, 'Y', 'Y', 7195, 8532, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'TELUS (ED)', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 1, 24, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 26.500000, 'Transit Charge } up to 24 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO rate_rule_tariff_original VALUES (1034, 'Y', 'Y', 7195, 8533, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'TELUS (ED)', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 25, 48, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 27.140000, 'Transit Charge } up to 48 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO rate_rule_tariff_original VALUES (1035, 'Y', 'Y', 7195, 8534, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'TELUS (ED)', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 49, 72, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 27.370000, 'Transit Charge } up to 72 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO rate_rule_tariff_original VALUES (1036, 'Y', 'Y', 7195, 8535, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'TELUS (ED)', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 73, 96, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 27.460000, 'Transit Charge } up to 96 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO rate_rule_tariff_original VALUES (1037, 'Y', 'Y', 7195, 8536, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'TELUS (ED)', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 97, NULL, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 27.510000, 'Transit Charge } more than 96 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO rate_rule_tariff_original VALUES (1038, 'Y', 'Y', 7196, 8532, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'Telus', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 1, 24, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 26.500000, 'Transit Charge } up to 24 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO rate_rule_tariff_original VALUES (1039, 'Y', 'Y', 7196, 8533, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'Telus', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 25, 48, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 27.140000, 'Transit Charge } up to 48 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO rate_rule_tariff_original VALUES (1040, 'Y', 'Y', 7196, 8534, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'Telus', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 49, 72, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 27.370000, 'Transit Charge } up to 72 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO rate_rule_tariff_original VALUES (1041, 'Y', 'Y', 7196, 8535, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'Telus', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 73, 96, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 27.460000, 'Transit Charge } up to 96 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO rate_rule_tariff_original VALUES (1042, 'Y', 'Y', 7196, 8536, 'Active', 'MRC', 'USOC & SVN & VN & Qty', '2005-5-29', 'TELUS', 'Telus', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL, NULL, NULL, 97, NULL, 'Telus GT/18008', 'Telus GT/18008/215/4/2(v)', NULL, NULL, 27.510000, 'Transit Charge } more than 96 trunks, each trunk.', '54', '', '215', '18008', NULL, NULL, NULL, NULL, NULL, NULL);*/

-- 

update audit_reference_mapping
set vendor_group_id = 1, vendor_name = NULL, summary_vendor_name = 'BELL CANADA'
where id = 6011;


INSERT INTO audit_reference_mapping(`vendor_group_id`, `ban_id`, `summary_vendor_name`, `vendor_name`, `key_field`, `key_field_original`, `charge_type`, `usoc`, `usoc_description`, `sub_product`, `line_item_code`, `line_item_code_description`, `usage_item_type`, `circuit_number`, `service_description`, `item_description`, `audit_reference_type_id`, `old_audit_reference_id`, `audit_reference_id`, `product_id`, `product_component_id`, `notes`, `created_timestamp`, `created_by`, `modified_timestamp`, `modified_by`, `rec_active_flag`) VALUES ( 12, NULL, 'VIDEOTRON', NULL, 'line_item_code_description', 'Line Item Code Description & SVN', 'OCC', NULL, NULL, NULL, NULL, 'Port out cancellation charge%', NULL, NULL, NULL, NULL, 2, 828, 828, NULL, NULL, NULL, '2018-9-10 03:20:32', NULL, NULL, NULL, 'Y');

/*update rate_rule_tariff_original
set summary_vendor_name = 'BELL CANADA'
where id = 769;

INSERT INTO rate_rule_tariff_original VALUES (1043, 'Y', 'Y', 7197, 8637, 'Active', 'OCC', 'Line Item Code Description & SVN', '2013-4-18', 'VIDEOTRON', NULL, NULL, NULL, NULL, 'Port out cancellation charge%', NULL, NULL, NULL, NULL, NULL, 'Bell AST/7516', 'Bell AST/7516/2/115/4(f)', NULL, NULL, 50.340000, '(LNP) Local Number Portability } (f) Port-Out Cancellation Charge', '45.8', '2', '115', '7516', NULL, NULL, NULL, NULL, NULL, NULL);*/

-- 


update audit_reference_mapping
set vendor_group_id = 108, vendor_name = 'TELUS COMMUNICATIONS INC.'
where id in (7141, 7142);

insert into vendor_group
values(118, 'TELUS COMMUNICATIONS (CALGARY)', '290', 'TELUS COMMUNICATIONS (CALGARY) vendor');

insert into vendor_group_vendor(vendor_group_id, vendor_id)
values(118, 290);

INSERT INTO audit_reference_mapping(`vendor_group_id`, `ban_id`, `summary_vendor_name`, `vendor_name`, `key_field`, `key_field_original`, `charge_type`, `usoc`, `usoc_description`, `sub_product`, `line_item_code`, `line_item_code_description`, `usage_item_type`, `circuit_number`, `service_description`, `item_description`, `audit_reference_type_id`, `old_audit_reference_id`, `audit_reference_id`, `product_id`, `product_component_id`, `notes`, `created_timestamp`, `created_by`, `modified_timestamp`, `modified_by`, `rec_active_flag`) VALUES ( 118, NULL, 'TELUS', 'TELUS COMMUNICATIONS (CALGARY)', 'line_item_code', 'Line Item Code & SVN & VN', 'MRC', NULL, NULL, 'TNI Link', '9N000', 'RADIO PAGING ACCESS CHANNEL ANALOG', NULL, NULL, NULL, NULL, 2, 859, 859, NULL, NULL, NULL, '2018-11-21 01:12:35', NULL, NULL, NULL, 'Y'),
(118, NULL, 'TELUS', 'TELUS COMMUNICATIONS (CALGARY)', 'line_item_code', 'Line Item Code & SVN & VN', 'MRC', NULL, NULL, 'TRadio Paging Numbers', '9001N', 'RADIO PAGING NUMBERS*/', NULL, NULL, NULL, NULL, 2, 860, 860, NULL, NULL, NULL, '2018-11-21 01:12:35', NULL, NULL, NULL, 'Y');

-- update rate_rule_tariff_original
-- set vendor_name = 'TELUS COMMUNICATIONS INC.'
-- where id in (829, 830);

-- INSERT INTO rate_rule_tariff_original VALUES (1044, 'Y', 'Y', 7198, 10795, 'Active', 'MRC', 'Line Item Code & SVN & VN', '2018-6-1', 'TELUS', 'TELUS COMMUNICATIONS (CALGARY)', NULL, NULL, 'TNI Link', 'RADIO PAGING ACCESS CHANNEL ANALOG', '9N000', NULL, NULL, NULL, NULL, 'Telus GT/21461', 'Telus GT/21461/II/219/4/2', NULL, NULL, 30.470000, 'TNA Link } Alberta, excluding the City of Edmonton', '219-5', 'II', '219', '21461', NULL, NULL, NULL, NULL, NULL, NULL);
-- INSERT INTO rate_rule_tariff_original VALUES (1045, 'Y', 'Y', 7199, 10796, 'Active', 'MRC', 'Line Item Code & SVN & VN', '2018-6-1', 'TELUS', 'TELUS COMMUNICATIONS (CALGARY)', NULL, NULL, 'TRadio Paging Numbers', 'RADIO PAGING NUMBERS', '9001N', NULL, NULL, NULL, NULL, 'Telus GT/21461', 'Telus GT/21461/II/219/4/3.b', NULL, NULL, 4.670000, 'Each block of 100 assigned numbers', '219-6', 'II', '219', '21461', NULL, NULL, NULL, NULL, NULL, NULL);




