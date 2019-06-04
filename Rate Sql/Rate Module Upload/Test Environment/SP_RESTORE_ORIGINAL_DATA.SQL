DROP PROCEDURE IF EXISTS SP_RESTORE_ORIGINAL_DATA;
CREATE PROCEDURE SP_RESTORE_ORIGINAL_DATA()

BEGIN
	
	SET FOREIGN_KEY_CHECKS = 0;
	
	truncate audit_rate_period;
	insert into audit_rate_period
	select * from bill_keep_audit_rate_period_backup;

	truncate audit_reference_mapping;
	insert into audit_reference_mapping
	select * from bill_keep_audit_reference_mapping_backup;

	truncate rate_rule_tariff_original;
	insert into rate_rule_tariff_original
	select * from bill_keep_rate_rule_tariff_original_backup;

	truncate tariff_file;
	insert into tariff_file
	select * from bill_keep_tariff_file_backup;

	truncate tariff;
	insert into tariff
	select * from bill_keep_tariff_backup;

	truncate tariff_rate_by_quantity;
	insert into tariff_rate_by_quantity
	select * from bill_keep_tariff_rate_by_quantity_backup;

	truncate tariff_rate_by_bill_keep;
	insert into tariff_rate_by_bill_keep
	select * from bill_keep_tariff_rate_by_bill_keep_backup;

	truncate vendor_group;
	insert into vendor_group
	select * from bill_keep_vendor_group_backup;

	truncate vendor_group_vendor;
	insert into vendor_group_vendor
	select * from bill_keep_vendor_group_vendor_backup;

END;