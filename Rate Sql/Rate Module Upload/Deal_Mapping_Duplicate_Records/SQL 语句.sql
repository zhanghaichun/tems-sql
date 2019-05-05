/**
 * 系统中 一条 tariff 对应多条 mapping 数据的记录都得修改，
 * 正常的逻辑应该是每个 mapping 都对应一个 tariff, 即使 tariff 是重复的。
 */

alter table audit_reference_mapping
add old_audit_reference_id int after audit_reference_type_id;

update audit_reference_mapping
set old_audit_reference_id = audit_reference_id;

-- 
select old_audit_reference_id, audit_reference_id from audit_reference_mapping
where old_audit_reference_id = '378';

select * from audit_rate_period
where rec_active_flag = 'Y'
and reference_table = 'tariff'
and reference_id in (378, 906);



select * from rate_module_tables_current_state;

call SP_DISPOSE_OLD_ONE_TO_MORE_MAPPING_DATA();

select id, old_audit_reference_id, audit_reference_id from audit_reference_mapping
where rec_active_flag = 'Y'
  and audit_reference_type_id = 2
  and old_audit_reference_id in (492);


select * from audit_reference_mapping
where rec_active_flag = 'Y'
  and old_audit_reference_id = 492;

select * from tariff_rate_by_quantity
where tariff_id in (871,
1066
);

select * from audit_rate_period
where rec_active_flag = 'Y'
and reference_table = 'tariff'
and reference_id in (492,
946,
947,
948,
949,
950,
951,
952,
);

