
/**
 * Update records including multiple vendor within summary_vendor_name or vendor name
 * in production environment.
 */


-- some multiple vendor record : including summary_vendor_name and vendor name。
select * from audit_reference_mapping
where rec_active_flag = 'Y'
  and (summary_vendor_name like '% or %' or vendor_name like '% or %');

-- 
update audit_reference_mapping
set vendor_group_id = 93, vendor_name = 'TELUS (AGT)'
where id = 279;

insert into vendor_group
values(108, 'TELUS COMMUNICATIONS INC.', '291', 'TELUS COMMUNICATIONS INC. vendor');

insert into vendor_group_vendor(vendor_group_id, vendor_id)
values(108, 291);

INSERT INTO audit_reference_mapping(vendor_group_id, summary_vendor_name, vendor_name, key_field, key_field_original, charge_type, usoc, usoc_description, sub_product, line_item_code, line_item_code_description, audit_reference_type_id, audit_reference_id, created_timestamp)
 VALUES ( 108, 'TELUS', 'TELUS COMMUNICATIONS INC.', 'line_item_code', 'Line Item Code & SVN & VN', 'MRC', NULL, NULL, 'Call Display', '8071', 'PRI CALL DISPLAY*',2, 562, current_timestamp);


-- 
update audit_reference_mapping
set vendor_group_id = 93, vendor_name = 'TELUS (AGT)'
where id = 293;

insert into vendor_group
values(116, 'TELUS (ED)', '289', 'TELUS (ED) vendor');

insert into vendor_group_vendor(vendor_group_id, vendor_id)
values(116, 289);

INSERT INTO audit_reference_mapping(vendor_group_id, summary_vendor_name, vendor_name, key_field, key_field_original, charge_type, usoc, usoc_description, sub_product, line_item_code, line_item_code_description, audit_reference_type_id, audit_reference_id, created_timestamp)
 VALUES (116, 'TELUS', 'TELUS (ED)', 'usoc', 'USOC & SVN & VN', 'MRC', 'TPPS9', 'EMERGENCY SERVICE 9-1-1, TRUNKS BETWEEN', 'Trunks', NULL, NULL, 2, 576, current_timestamp);

-- 
update audit_reference_mapping
set vendor_group_id = 93, vendor_name = 'TELUS (AGT)'
where id = 5969;

insert into vendor_group
values(117, 'TELUS', '284', 'TELUS vendor');

insert into vendor_group_vendor(vendor_group_id, vendor_id)
values(117, 284);

INSERT INTO audit_reference_mapping(vendor_group_id, summary_vendor_name, vendor_name, key_field, key_field_original, charge_type, usoc, usoc_description, sub_product, line_item_code, line_item_code_description, audit_reference_type_id, audit_reference_id, created_timestamp)
VALUES (116, 'TELUS', 'TELUS (ED)', 'usoc', 'USOC & SVN & VN & Qty', 'MRC', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL,  2, 804, current_timestamp ),
(117, 'TELUS', 'Telus', 'usoc', 'USOC & SVN & VN & Qty', 'MRC', 'TPPUC', 'CLEC LOCAL TRANSITING ', 'Local Transit', NULL, NULL,  2, 804, current_timestamp);

-- 

update audit_reference_mapping
set vendor_group_id = 1, vendor_name = NULL, summary_vendor_name = 'BELL CANADA'
where id = 6011;


INSERT INTO audit_reference_mapping(vendor_group_id, summary_vendor_name, vendor_name, key_field, key_field_original, charge_type, usoc, usoc_description, sub_product, line_item_code, line_item_code_description, audit_reference_type_id, audit_reference_id, created_timestamp)
 VALUES (12, 'VIDEOTRON', NULL, 'line_item_code_description', 'Line Item Code Description & SVN', 'OCC', NULL, NULL, NULL, NULL, 'Port out cancellation charge%', 2, 828, current_timestamp);

-- 


update audit_reference_mapping
set vendor_group_id = 108, vendor_name = 'TELUS COMMUNICATIONS INC.'
where id in (6055, 6056);

insert into vendor_group
values(118, 'TELUS COMMUNICATIONS (CALGARY)', '290', 'TELUS COMMUNICATIONS (CALGARY) vendor');

insert into vendor_group_vendor(vendor_group_id, vendor_id)
values(118, 290);

INSERT INTO audit_reference_mapping(vendor_group_id, summary_vendor_name, vendor_name, key_field, key_field_original, charge_type, usoc, usoc_description, sub_product, line_item_code, line_item_code_description, audit_reference_type_id, audit_reference_id, created_timestamp)
 VALUES ( 118, 'TELUS', 'TELUS COMMUNICATIONS (CALGARY)', 'line_item_code', 'Line Item Code & SVN & VN', 'MRC', NULL, NULL, 'TNI Link', '9N000', 'RADIO PAGING ACCESS CHANNEL ANALOG', 2, 859, current_timestamp),
    (118, 'TELUS', 'TELUS COMMUNICATIONS (CALGARY)', 'line_item_code', 'Line Item Code & SVN & VN', 'MRC', NULL, NULL, 'TRadio Paging Numbers', '9001N', 'RADIO PAGING NUMBERS*/', 2, 860, current_timestamp);


