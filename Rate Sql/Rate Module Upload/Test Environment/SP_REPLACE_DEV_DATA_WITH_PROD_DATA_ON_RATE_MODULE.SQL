DROP PROCEDURE IF EXISTS SP_REPLACE_DEV_DATA_WITH_PROD_DATA_ON_RATE_MODULE;
CREATE PROCEDURE SP_REPLACE_DEV_DATA_WITH_PROD_DATA_ON_RATE_MODULE()

BEGIN
  
  TRUNCATE dev_tariff_backup;
  INSERT INTO dev_tariff_backup
  SELECT * FROM tariff;

  TRUNCATE dev_tariff_file_backup;
  INSERT INTO dev_tariff_file_backup
  SELECT * FROM tariff_file;

  TRUNCATE dev_tariff_rate_by_quantity_backup;
  INSERT INTO dev_tariff_rate_by_quantity_backup
  SELECT * FROM tariff_rate_by_quantity;

  TRUNCATE dev_contract_backup;
  INSERT INTO dev_contract_backup
  SELECT * FROM contract;

  TRUNCATE dev_contract_file_backup;
  INSERT INTO dev_contract_file_backup
  SELECT * FROM contract_file;

  TRUNCATE dev_contract_rate_by_quantity_backup;
  INSERT INTO dev_contract_rate_by_quantity_backup
  SELECT * FROM contract_rate_by_quantity;

  TRUNCATE dev_audit_mtm_backup;
  INSERT INTO dev_audit_mtm_backup
  SELECT * FROM audit_mtm;

  TRUNCATE dev_vendor_group_backup;
  INSERT INTO dev_vendor_group_backup
  SELECT * FROM vendor_group;

  TRUNCATE dev_vendor_group_vendor_backup;
  INSERT INTO dev_vendor_group_vendor_backup
  SELECT * FROM vendor_group_vendor;

  TRUNCATE dev_audit_reference_mapping_backup;
  INSERT INTO dev_audit_reference_mapping_backup
  SELECT * FROM audit_reference_mapping;

  TRUNCATE dev_audit_reference_mapping_exclusion_backup;
  INSERT INTO dev_audit_reference_mapping_exclusion_backup
  SELECT * FROM audit_reference_mapping_exclusion;

  TRUNCATE dev_audit_rate_period_backup;
  INSERT INTO dev_audit_rate_period_backup
  SELECT * FROM audit_rate_period;

  TRUNCATE dev_rate_rule_tariff_original_backup;
  INSERT INTO dev_rate_rule_tariff_original_backup
  SELECT * FROM rate_rule_tariff_original;

  TRUNCATE dev_rate_rule_contract_original_backup;
  INSERT INTO dev_rate_rule_contract_original_backup
  SELECT * FROM rate_rule_contract_original;

  TRUNCATE dev_rate_rule_mtm_original_backup;
  INSERT INTO dev_rate_rule_mtm_original_backup
  SELECT * FROM rate_rule_mtm_original;

END;