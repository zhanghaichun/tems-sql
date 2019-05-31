
-- 向 rate_rule_tariff_original 表中加 3 个字段
-- ban_id， imbalance_start， imbalance_end
alter table rate_rule_tariff_original
add ban_id int after quantity_end,
add imbalance_start double(20, 5) after ban_id,
add imbalance_end double(20, 5) after imbalance_start;

alter table rate_rule_tariff_original
add province varchar(16) after imbalance_end,
add provider varchar(64) after province;

-- 修改不规则的 tariff file
update tariff_file
set tariff_name = 'Bell AST/7516' -- 系统数据库中包含这条记录 tariff_file_id = 32
where tariff_name = 'Bell Canada ACCESS SERVICE TARIFF CRTC 7516'
	and id = 50;

update tariff_file
set tariff_name = 'Bell MTS/24006'
where tariff_name = 'Bell MTS CRTC 24006'
	and id = 51;

update tariff_file
set tariff_name = 'SaskTel CAT/21414' -- 系统数据库中包含这条记录 tariff_file_id = 41
where tariff_name = 'SaskTel COMPETITOR ACCESS TARIFF CRTC 21414'
	and id = 52;


update tariff_file
set tariff_name = 'TELUS CAT/1017'
where tariff_name = 'TELUS CARRIER ACCESS TARIFF CRTC 1017'
	and id = 53;

update tariff_file
set tariff_name = 'Telus Quebec AST/25082'
where tariff_name = 'Telus Quebec Access Services Tariff CRTC 25082'
	and id = 54;

update tariff_file
set tariff_name = 'TELUS CAT/18008'
where tariff_name = 'TELUS CARRIER ACCESS TARIFF CRTC 18008'
	and id = 55;

update tariff_file
set tariff_name = 'Iristel AST/21670'
where tariff_name = 'Iristel ACCESS SERVICES TARIFF CRTC 21670'
	and id = 56;

update tariff_file
set tariff_name = 'Shaw Telecom G.P./21520'
where tariff_name = 'Shaw Telecom G.P. CRTC 21520'
	and id = 57;

update tariff_file
set tariff_name = 'Allstream AST/21170'
where tariff_name = 'Allstream ACCESS SERVICES TARIFF CRTC 21170'
	and id = 58;

update tariff_file
set tariff_name = 'Telebec GT/25140' -- 系统数据库中包含这条记录 tariff_file_id = 45
where tariff_name = 'Telebec General CRTC 25140'
	and id = 59;

-- 更新 tariff 表的 bill keep 相关信息。
update tariff
set tariff_file_id = 32
where id = 862;

update tariff
set tariff_file_id = 41
where id = 865;

update tariff
set tariff_file_id = 45
where id = 867;

update tariff
set name = 'Bell AST/7516/2/105.4 (d)(1)'
where id = 862;

update tariff
set name = 'SaskTel CAT/21414/610.18.4.3(a)'
where id = 865;

update tariff
set name = 'Telebec GT/25140/7/7.8.4 (8) a) (v)'
where id = 867;

update tariff
set name = 'Bell MTS/24006/II/105.4 (D)(1)'
where id = 863;

update tariff
set name = 'TELUS CAT/1017/150 (D) 4 (a)'
where id = 868;

update tariff
set name = 'Telus Quebec AST/25082/1.05/1.05.04 (d)(1)'
where id = 870;

update tariff
set name = 'TELUS CAT/18008/215.4 (2)(b)(i)'
where id = 869;

update tariff
set name = 'Iristel AST/21670/B/201'
where id = 864;

update tariff
set name = 'Shaw Telecom G.P./21520/B/201'
where id = 866;

update tariff
set name = 'Allstream AST/21170/B/201'
where id = 861;


select max(id) from tariff; -- 1068
select max(id) from tariff_file; -- 65

-- tariff_name: TELUS/18008/215.4(2)b)(i) 
-- tariff_page : 57

insert into tariff_file(tariff_name, created_timestamp)
values('TELUS/18008', now()); -- tariff_file_id = 66

insert into tariff(tariff_file_id, name, rate_mode, page, part_section, item_number, source, created_timestamp)
values(66, 'TELUS/18008/215.4(2)b)(i)', 'tariff_rate_by_bill_keep', 57, null, '215.4(2)b)(i)', 'Rogers', now()); -- tariff_id = 1069

-- 1070 => 862
-- 1071 => 862 
-- 1072 => 869
-- 1073 => 870
-- 插入重复的 tariff name 记录，目的是让 mapping 表中的每一条记录单独对应一个 tariff.
insert into tariff(tariff_file_id, name, rate_mode, page, part_section, item_number, source, created_timestamp)
values(32, 'Bell AST/7516/2/105.4 (d)(1)', 'tariff_rate_by_bill_keep', 37.15, 2, '105.4 (d)(1)', 'Rogers', now()),
(32, 'Bell AST/7516/2/105.4 (d)(1)', 'tariff_rate_by_bill_keep', 37.15, 2, '105.4 (d)(1)', 'Rogers', now()),
(55, 'TELUS CAT/18008/215.4 (2)(b)(i)', 'tariff_rate_by_bill_keep', 57, null, '215.4(2)b)(i)', 'Rogers', now()),
(54, 'Telus Quebec AST/25082/1.05/1.05.04 (d)(1)', 'tariff_rate_by_bill_keep', 79, 1.05, '1.05.04 (d)(1)', 'Rogers', now());

select max(id) from vendor_group; -- 117

insert into vendor_group (group_name, vendor_ids, notes)
values('TELUS', 284, 'Telus vendor'); -- 119

insert into audit_reference_mapping(vendor_group_id, ban_id, vendor_name, key_field, key_field_original, 
	audit_reference_type_id, audit_reference_id, created_timestamp) 
values(119, 10787, 'TELUS', 'bill_keep_ban', 'Bill & Keep', 2, 1069, now());

update audit_reference_mapping
set audit_reference_id = 1070
where ban_id = 654;

update audit_reference_mapping
set audit_reference_id = 1071
where ban_id = 927;

update audit_reference_mapping
set audit_reference_id = 1072
where ban_id = 9194;

update audit_reference_mapping
set audit_reference_id = 1073
where ban_id = 11641;

select max(id) from tariff_rate_by_bill_keep; -- 1645

select distinct tariff_id from tariff_rate_by_bill_keep;

alter table tariff_rate_by_bill_keep
add rec_active_flag char(1) default 'Y';

insert into tariff_rate_by_bill_keep(tariff_id, province, provider, imbalance_start, imbalance_end, trunk_start, trunk_end)
select 1069, territory, provider, imbalance_start, imbalance_end, trunk_start, trunk_end
from bill_keep_ban_tariff_mapping
where ban_id = 10787;

select * from audit_rate_period
where rec_active_flag = 'Y'
	and reference_table = 'tariff_rate_by_bill_keep';

-- 1646 ~ 1660

insert into audit_rate_period(reference_table, reference_id, start_date, rate)
select 'tariff_rate_by_bill_keep', t.id, '2018-06-01', b.rate
from tariff_rate_by_bill_keep t, bill_keep_ban_tariff_mapping b
where t.rec_active_flag ='Y'
	and t.tariff_id = 1069
	and b.ban_id = 10787
	and t.imbalance_start = b.imbalance_start
	and t.imbalance_end = b.imbalance_end
	and t.trunk_start = b.trunk_start
	and t.trunk_end = b.trunk_end;

-- 查询 bill keep 的 charge type，发现有多种情况。
select DISTINCT p.item_type_id from audit_result ar
left join proposal p on p.id = ar.proposal_id 
where audit_source_id between 10001 and 10004
order by ar.id DESC
limit 200;

select arp.* from tariff t
left join tariff_file tf on t.tariff_file_id = tf.id
left join audit_reference_mapping arm on t.id = arm.audit_reference_id
left join tariff_rate_by_bill_keep tr on tr.tariff_id = arm.audit_reference_id
left join audit_rate_period arp on tr.id = arp.reference_id
where arm.audit_reference_type_id = 2
	and arp.reference_table = 'tariff_rate_by_bill_keep'
	and arm.key_field = 'bill_keep_ban'
	and arp.rec_active_flag = 'Y'
	and arm.rec_active_flag = 'Y'
	and tr.rec_active_flag = 'Y'
	and t.rec_active_flag = 'Y';


select * from tariff_rate_by_bill_keep;

-- 添加 key field.
insert into audit_key_field (audit_reference_type_id,key_field_original,key_field,rate_mode,reference_table) 
VALUES(2, 'Bill & Keep', 'bill_keep_ban', 'tariff_rate_by_bill_keep', 'tariff_rate_by_bill_keep'); 
