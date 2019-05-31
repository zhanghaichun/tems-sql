
-- @@TARIFF
-- 查询出来的字段多数保存在 rate_rule_tariff_original 表中
-- 但是需要将 audit_reference_type_id 和 audit_reference_id 查询出来

-- 从 rate_rule_tariff_original 表中查询所需数据 (*)
select
	arm.audit_reference_type_id,
	arm.audit_reference_id,
	rrto.tariff_name,
	rrto.tariff_file_name,
	rrto.tariff_page,
	rrto.crtc_number,
	rrto.part_section,
	rrto.item_number 
from rate_rule_tariff_original rrto
	left join audit_reference_mapping arm on rrto.audit_reference_mapping_id = arm.id
where rrto.rec_active_flag = 'Y'
	and arm.rec_active_flag = 'Y'
	and arm.audit_reference_type_id = 2
-- 	and rrto.rate = 0.13
group by arm.audit_reference_id, rrto.tariff_name;

-- 搜索 rate 总结性信息。（*）
select FN_GET_AUDIT_RATE_TEXT('tariff', 378) as rateText;

-- 修改单条 rate 时候的查询信息
-- 参数也是 audit_reference_type_id 和 audit_reference_id
-- 首先需要查询出 rate mode , 然后查询相关字段的 id, 以此来确定唯一的那个字段值
-- audit_reference_type = 2, reference_table = 'tariff'
-- audit_reference_type = 3, reference_table = 'contract'
-- audit_reference_type = 18, reference_table = 'audit_mtm'

-- 1. Rate Mode: rate , audit_reference_type = 2
select * from audit_rate_period arp
where rec_active_flag = 'Y'
	and reference_table = 'tariff'
	and reference_id = @audit_reference_id;

-- 返回一个 list ,判断 list 的个数
Rate Mode: Rate. <br> 
Active Rate: 6.15, Effective Date: 2018-06-01. <br>
Inactive Rate: 6.15, Effective Date: 2018-05-01. <br>

-- mapping rule 和 rate 关联的 sql 语句