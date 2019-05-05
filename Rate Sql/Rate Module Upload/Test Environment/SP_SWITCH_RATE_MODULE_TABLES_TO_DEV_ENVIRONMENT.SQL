DROP PROCEDURE IF EXISTS SP_SWITCH_RATE_MODULE_TABLES_TO_DEV_ENVIRONMENT;
CREATE PROCEDURE SP_SWITCH_RATE_MODULE_TABLES_TO_DEV_ENVIRONMENT()

BEGIN 

  /*CREATE TABLE dev_tariff_backup AS
  SELECT * FROM tariff;

  CREATE TABLE dev_tariff_file_backup AS
  SELECT * FROM tariff_file;

  CREATE TABLE dev_tariff_rate_by_quantity_backup AS
  SELECT * FROM tariff_rate_by_quantity;

  CREATE TABLE dev_contract_backup AS
  SELECT * FROM contract;

  CREATE TABLE dev_contract_file_backup AS
  SELECT * FROM contract_file;

  CREATE TABLE dev_contract_rate_by_quantity_backup AS
  SELECT * FROM contract_rate_by_quantity;

  --
  CREATE TABLE dev_audit_mtm_backup AS
  SELECT * FROM audit_mtm;

  CREATE TABLE dev_vendor_group_backup AS
  SELECT * FROM vendor_group;

  CREATE TABLE dev_vendor_group_vendor_backup AS
  SELECT * FROM vendor_group_vendor;

  CREATE TABLE dev_audit_rate_period_backup AS
  SELECT * FROM audit_rate_period;

  CREATE TABLE dev_audit_reference_mapping_backup AS
  SELECT * FROM audit_reference_mapping;

  CREATE TABLE dev_audit_reference_mapping_exclusion_backup AS
  SELECT * FROM audit_reference_mapping_exclusion;

  CREATE TABLE dev_rate_rule_tariff_original_backup AS
  SELECT * FROM rate_rule_tariff_original;

  CREATE TABLE dev_rate_rule_contract_original_backup AS
  SELECT * FROM rate_rule_contract_original;

  CREATE TABLE dev_rate_rule_mtm_original_backup AS
  SELECT * FROM rate_rule_mtm_original;*/

  TRUNCATE prod_tariff_backup;
  INSERT INTO prod_tariff_backup
  SELECT * FROM tariff;

  TRUNCATE prod_tariff_file_backup;
  INSERT INTO prod_tariff_file_backup
  SELECT * FROM tariff_file;

  TRUNCATE prod_tariff_rate_by_quantity_backup;
  INSERT INTO prod_tariff_rate_by_quantity_backup
  SELECT * FROM tariff_rate_by_quantity;

  TRUNCATE prod_contract_backup;
  INSERT INTO prod_contract_backup
  SELECT * FROM contract;

  TRUNCATE prod_contract_file_backup;
  INSERT INTO prod_contract_file_backup
  SELECT * FROM contract_file;

  TRUNCATE prod_contract_rate_by_quantity_backup;
  INSERT INTO prod_contract_rate_by_quantity_backup
  SELECT * FROM contract_rate_by_quantity;

  TRUNCATE prod_audit_mtm_backup;
  INSERT INTO prod_audit_mtm_backup
  SELECT * FROM audit_mtm;

  TRUNCATE prod_vendor_group_backup;
  INSERT INTO prod_vendor_group_backup
  SELECT * FROM vendor_group;

  TRUNCATE prod_vendor_group_vendor_backup;
  INSERT INTO prod_vendor_group_vendor_backup
  SELECT * FROM vendor_group_vendor;

  TRUNCATE prod_audit_reference_mapping_backup;
  INSERT INTO prod_audit_reference_mapping_backup
  SELECT * FROM audit_reference_mapping;

  TRUNCATE prod_audit_reference_mapping_exclusion_backup;
  INSERT INTO prod_audit_reference_mapping_exclusion_backup
  SELECT * FROM audit_reference_mapping_exclusion;

  TRUNCATE prod_audit_rate_period_backup;
  INSERT INTO prod_audit_rate_period_backup
  SELECT * FROM audit_rate_period;

  TRUNCATE prod_rate_rule_tariff_original_backup;
  INSERT INTO prod_rate_rule_tariff_original_backup
  SELECT * FROM rate_rule_tariff_original;

  TRUNCATE prod_rate_rule_contract_original_backup;
  INSERT INTO prod_rate_rule_contract_original_backup
  SELECT * FROM rate_rule_contract_original;

  TRUNCATE prod_rate_rule_mtm_original_backup;
  INSERT INTO prod_rate_rule_mtm_original_backup
  SELECT * FROM rate_rule_mtm_original;

  /**
   * 将 DEV 模式的数据导入进主流程表中。
   */
  SET FOREIGN_KEY_CHECKS = 0;
  TRUNCATE tariff;
  INSERT INTO tariff
  SELECT * FROM dev_tariff_backup;

  TRUNCATE tariff_file;
  INSERT INTO tariff_file
  SELECT * FROM dev_tariff_file_backup;


  TRUNCATE tariff_rate_by_quantity;
  INSERT INTO tariff_rate_by_quantity
  SELECT * FROM dev_tariff_rate_by_quantity_backup;

  TRUNCATE contract;
  INSERT INTO contract
  SELECT * FROM dev_contract_backup;

  TRUNCATE contract_file;
  INSERT INTO contract_file
  SELECT * FROM dev_contract_file_backup;

  TRUNCATE contract_rate_by_quantity;
  INSERT INTO contract_rate_by_quantity
  SELECT * FROM dev_contract_rate_by_quantity_backup;

  TRUNCATE audit_mtm;
  INSERT INTO audit_mtm
  SELECT * FROM dev_audit_mtm_backup;

  TRUNCATE vendor_group;
  INSERT INTO vendor_group
  SELECT * FROM dev_vendor_group_backup;

  TRUNCATE vendor_group_vendor;
  INSERT INTO vendor_group_vendor
  SELECT * FROM dev_vendor_group_vendor_backup;

  TRUNCATE audit_reference_mapping;
  INSERT INTO audit_reference_mapping
  SELECT * FROM dev_audit_reference_mapping_backup;

  TRUNCATE audit_reference_mapping_exclusion;
  INSERT INTO audit_reference_mapping_exclusion
  SELECT * FROM dev_audit_reference_mapping_exclusion_backup;

  TRUNCATE audit_rate_period;
  INSERT INTO audit_rate_period
  SELECT * FROM dev_audit_rate_period_backup;

  TRUNCATE rate_rule_tariff_original;
  INSERT INTO rate_rule_tariff_original
  SELECT * FROM dev_rate_rule_tariff_original_backup;

  TRUNCATE rate_rule_contract_original;
  INSERT INTO rate_rule_contract_original
  SELECT * FROM dev_rate_rule_contract_original_backup;

  TRUNCATE rate_rule_mtm_original;
  INSERT INTO rate_rule_mtm_original
  SELECT * FROM dev_rate_rule_mtm_original_backup;

END;