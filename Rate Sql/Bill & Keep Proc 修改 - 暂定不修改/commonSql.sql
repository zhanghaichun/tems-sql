
-- rate_rule_tariff_original 新加的字段
-- bill_keep_ban_id, bill_keep_ban, province, provider,
-- imbalance_start, imbalance_end

alter table rate_rule_tariff_original
add bill_keep_ban_id int after item_description,
add bill_keep_ban varchar(64) after quantity_end,
add province varchar(16) after bill_keep_ban,
add provider varchar(64) after province,
add imbalance_start double(20, 5) after provider,
add imbalance_end double(20, 5) after imbalance_start;


SELECT COUNT(1) INTO V_COUNT 
FROM audit_reference_mapping 
WHERE ban_id = V_BAN_ID
	and rec_active_flag = 'Y';

-- 更新逻辑不明确的 ban 的 rec_active_flag = 'N'
update audit_reference_mapping
set rec_active_flag = 'N'
where ban_id in (11343,
11684,
11759
);

-- 无效的 BAN
update audit_reference_mapping
set rec_active_flag = 'N'
where ban_id in (
4376,
3087,
11641);

update rate_rule_tariff_original
set rec_active_flag = 'N'
where bill_keep_ban_id in (
4376,
3087,
11641);

alter table tariff_rate_by_bill_keep
add column rec_active_flag char(1) default 'Y';

select bk.ban, bk.ban_id from audit_reference_mapping arm
	left join bill_keep_ban bk on arm.ban_id = bk.ban_id
where arm.key_field = 'bill_keep_ban'
	and bk.rec_active_flag = 'Y'
	and arm.audit_reference_type_id = 2;

select max(id) from tariff; -- 1068
select max(id) from tariff_file; -- 65

-- tariff_name: TELUS/18008/215.4(2)b)(i) 
-- tariff_page : 57

insert into tariff_file(tariff_name, created_timestamp)
values('TELUS CRTC 18008', now()); -- tariff_file_id = 66

insert into tariff(tariff_file_id, name, rate_mode, page, part_section, item_number, source, created_timestamp)
values(10, 'TELUS CRTC 18008/215.4(2)b)(i)', 'tariff_rate_by_bill_keep', 57, null, '215.4(2)b)(i)', 'Rogers', now()); -- tariff_id = 1069

-- 1070 => 862
-- 1071 => 862 
-- 1072 => 869
-- 1073 => 870
-- 插入重复的 tariff name 记录，目的是让 mapping 表中的每一条记录单独对应一个 tariff.
insert into tariff(tariff_file_id, name, rate_mode, page, part_section, item_number, source, created_timestamp)
values(51, 'Bell Canada ACCESS SERVICE TARIFF CRTC 7516/2/105.4 (d)(1)', 'tariff_rate_by_bill_keep', 37.15, 2, '105.4 (d)(1)', 'Rogers', now()),
(51, 'Bell Canada ACCESS SERVICE TARIFF CRTC 7516/2/105.4 (d)(1)', 'tariff_rate_by_bill_keep', 37.15, 2, '105.4 (d)(1)', 'Rogers', now()),
(58, 'TELUS CARRIER ACCESS TARIFF CRTC 18008/215.4 (2)(b)(i)', 'tariff_rate_by_bill_keep', 57, null, '215.4(2)b)(i)', 'Rogers', now()),
(59, 'Telus Quebec Access Services Tariff CRTC 25082/1.05/1.05.04 (d)(1)', 'tariff_rate_by_bill_keep', 79, 1.05, '1.05.04 (d)(1)', 'Rogers', now());

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
	and t.trunk_start = b.trunk_start;

-- 通过导出 excel来整理 tariff_rate_by_bill_keep 表中的数据
-- 和 audit_rate_period 表中的数据

update tariff_rate_by_bill_keep
set trunk_end = null
where trunk_start = 97
	and trunk_end = 97;

insert into rate_rule_tariff_original(
	`audit_reference_mapping_id`,
	`bill_keep_ban_id`,
	`audit_rate_period_id`,
	`key_field`,
	`rate_effective_date`,
	`summary_vendor_name`,
	`vendor_name`,
	`province`,
	`provider`,
	`imbalance_start`,
	`imbalance_end`,
	`quantity_begin`,
	`quantity_end`,
	`tariff_file_name`,
	`tariff_name`,
	`rate`,
	`tariff_page`,
	`part_section`,
	`item_number`,
	`crtc_number`
)

select 
	arm.id as auditReferenceMappingId,
	arm.ban_id,
	arp.id as auditRatePeriodId,
	arm.key_field_original AS keyField,
	arp.start_date AS rateEffectiveDate,
	arm.summary_vendor_name AS summaryVendorName,
	arm.vendor_name AS vendorName,
	tr.province,
	tr.provider,
	tr.imbalance_start,
	tr.imbalance_end,
	tr.trunk_start AS quantityBegin,
	tr.trunk_end AS quantityEnd,
	tf.tariff_name,
	t.name AS contractNumberOrTariffReference,
	arp.rate AS rate,
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
	) AS crtcNumber
from tariff t
left join tariff_file tf on t.tariff_file_id = tf.id
left join audit_reference_mapping arm on t.id = arm.audit_reference_id
left join tariff_rate_by_bill_keep tr on tr.tariff_id = arm.audit_reference_id
left join audit_rate_period arp on tr.id = arp.reference_id
where arm.audit_reference_type_id = 2
	and arp.reference_table = 'tariff_rate_by_bill_keep'
	and arm.key_field = 'bill_keep_ban'
	and t.rate_mode = 'tariff_rate_by_bill_keep'
	and arp.rec_active_flag = 'Y'
	-- and arm.rec_active_flag = 'Y'
	and tr.rec_active_flag = 'Y'
	and t.rec_active_flag = 'Y';

-- 更新 bill_keep_ban 字段。
update rate_rule_tariff_original r
set bill_keep_ban = (
	select account_number from ban
	where id = r.bill_keep_ban_id
)
where r.bill_keep_ban_id is not null;


select * from tariff_rate_by_bill_keep;

-- 添加 key field.
insert into audit_key_field (audit_reference_type_id,key_field_original,key_field,rate_mode,reference_table) 
VALUES(2, 'Bill & Keep', 'bill_keep_ban', 'tariff_rate_by_bill_keep', 'tariff_rate_by_bill_keep'); 


CALL SP_UPDATE_AUDIT_RATE_STATUS();


update audit_rate_period
set start_date = '2017-06-01', end_date = '2018-05-31'
where reference_table = 'tariff_rate_by_bill_keep'
and reference_id between 1661 and 1840
and end_date is not null;

update audit_rate_period
set start_date = '2018-06-01'
where reference_table = 'tariff_rate_by_bill_keep'
and reference_id between 1661 and 1840
and end_date is null;

-- 531596 New Program
-- 531003 Old Program

create table bill_keep_audit_rate_period_backup as
select * from audit_rate_period;

create table bill_keep_audit_reference_mapping_backup as
select * from audit_reference_mapping;

create table bill_keep_rate_rule_tariff_original_backup as
select * from rate_rule_tariff_original;

create table bill_keep_tariff_file_backup as
select * from tariff_file;

create table bill_keep_tariff_backup as
select * from tariff;

create table bill_keep_tariff_rate_by_quantity_backup as
select * from tariff_rate_by_quantity;

create table bill_keep_tariff_rate_by_bill_keep_backup as
select * from tariff_rate_by_bill_keep;

create table bill_keep_vendor_group_backup as
select * from vendor_group;

create table bill_keep_vendor_group_vendor_backup as
select * from vendor_group_vendor;

-- 使用 sql 程序 SP_RESTORE_ORIGINAL_DATA 来进行数据的还原。

-- SP_AUDIT_MRC_OCC, SP_AUDIT_USAGE_RATE 中排除 bill_keep 对验证结果的影响