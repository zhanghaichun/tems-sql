DROP PROCEDURE IF EXISTS SP_SWITCH_RATE_MODULE_TABLES_TO_PROD_ENVIRONMENT;
CREATE PROCEDURE SP_SWITCH_RATE_MODULE_TABLES_TO_PROD_ENVIRONMENT()

BEGIN 

  /*CREATE TABLE prod_tariff_backup AS
  SELECT * FROM tariff;

  CREATE TABLE prod_tariff_file_backup AS
  SELECT * FROM tariff_file;

  CREATE TABLE prod_tariff_rate_by_quantity_backup AS
  SELECT * FROM tariff_rate_by_quantity;

  CREATE TABLE prod_contract_backup AS
  SELECT * FROM contract;

  CREATE TABLE prod_contract_file_backup AS
  SELECT * FROM contract_file;

  CREATE TABLE prod_contract_rate_by_quantity_backup AS
  SELECT * FROM contract_rate_by_quantity;

  --
  CREATE TABLE prod_audit_mtm_backup AS
  SELECT * FROM audit_mtm;

  CREATE TABLE prod_vendor_group_backup AS
  SELECT * FROM vendor_group;

  CREATE TABLE prod_vendor_group_vendor_backup AS
  SELECT * FROM vendor_group_vendor;

  CREATE TABLE prod_audit_rate_period_backup AS
  SELECT * FROM audit_rate_period;

  CREATE TABLE prod_audit_reference_mapping_backup AS
  SELECT * FROM audit_reference_mapping;

  CREATE TABLE prod_audit_reference_mapping_exclusion_backup AS
  SELECT * FROM audit_reference_mapping_exclusion;

  CREATE TABLE prod_rate_rule_tariff_original_backup AS
  SELECT * FROM rate_rule_tariff_original;

  CREATE TABLE prod_rate_rule_contract_original_backup AS
  SELECT * FROM rate_rule_contract_original;

  CREATE TABLE prod_rate_rule_mtm_original_backup AS
  SELECT * FROM rate_rule_mtm_original;*/

  /**
   * 将 CURRENT_RATE_MODULES 中的数据备份到 dev_bak 表中。
   */
  
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

  /**
   * 将 prod_bak 的数据导入到 CURRENT_RATE_MODULES 中。
   */
  SET FOREIGN_KEY_CHECKS = 0;
  TRUNCATE tariff;
  INSERT INTO tariff
  SELECT * FROM prod_tariff_backup;

  TRUNCATE tariff_file;
  INSERT INTO tariff_file
  SELECT * FROM prod_tariff_file_backup;

  TRUNCATE tariff_rate_by_quantity;
  INSERT INTO tariff_rate_by_quantity
  SELECT * FROM prod_tariff_rate_by_quantity_backup;

  TRUNCATE contract;
  INSERT INTO contract
  SELECT * FROM prod_contract_backup;

  TRUNCATE contract_file;
  INSERT INTO contract_file
  SELECT * FROM prod_contract_file_backup;

  TRUNCATE contract_rate_by_quantity;
  INSERT INTO contract_rate_by_quantity
  SELECT * FROM prod_contract_rate_by_quantity_backup;

  TRUNCATE audit_mtm;
  INSERT INTO audit_mtm
  SELECT * FROM prod_audit_mtm_backup;

  TRUNCATE vendor_group;
  INSERT INTO vendor_group
  SELECT * FROM prod_vendor_group_backup;

  TRUNCATE vendor_group_vendor;
  INSERT INTO vendor_group_vendor
  SELECT * FROM prod_vendor_group_vendor_backup;

  TRUNCATE audit_reference_mapping;
  INSERT INTO audit_reference_mapping
  SELECT * FROM prod_audit_reference_mapping_backup;

  TRUNCATE audit_reference_mapping_exclusion;
  INSERT INTO audit_reference_mapping_exclusion
  SELECT * FROM prod_audit_reference_mapping_exclusion_backup;

  TRUNCATE audit_rate_period;
  INSERT INTO audit_rate_period
  SELECT * FROM prod_audit_rate_period_backup;

  TRUNCATE rate_rule_tariff_original;
  INSERT INTO rate_rule_tariff_original
  SELECT * FROM prod_rate_rule_tariff_original_backup;

  TRUNCATE rate_rule_contract_original;
  INSERT INTO rate_rule_contract_original
  SELECT * FROM prod_rate_rule_contract_original_backup;

  TRUNCATE rate_rule_mtm_original;
  INSERT INTO rate_rule_mtm_original
  SELECT * FROM prod_rate_rule_mtm_original_backup;

END;