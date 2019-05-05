DROP PROCEDURE IF EXISTS SP_UPDATE_AUDIT_RATE_STATUS;
CREATE PROCEDURE SP_UPDATE_AUDIT_RATE_STATUS()

BEGIN
  /**
   * 
   * 更新 rate_rule_tariff_original,
   * rate_rule_contract_original,
   * rate_rule_mtm_original 表中的 rate_status,
   */
  
  DECLARE V_MTM_MASTER_TABLE_COUNT INT;
  DECLARE V_CONTRACT_MASTER_TABLE_COUNT INT;
  DECLARE V_TARIFF_MASTER_TABLE_COUNT INT;
  
  SELECT COUNT(1) INTO V_MTM_MASTER_TABLE_COUNT 
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_NAME = 'rate_rule_mtm_original';

  SELECT COUNT(1) INTO V_CONTRACT_MASTER_TABLE_COUNT 
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_NAME = 'rate_rule_contract_original';

  SELECT COUNT(1) INTO V_TARIFF_MASTER_TABLE_COUNT 
  FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_NAME = 'rate_rule_tariff_original';
  
  IF(V_TARIFF_MASTER_TABLE_COUNT > 0) THEN

    UPDATE rate_rule_tariff_original rrto
      LEFT JOIN audit_rate_period arp ON rrto.audit_rate_period_id = arp.id
    SET rrto.rate_status = (
        CASE
          WHEN arp.end_date IS NULL THEN
            'Active'
          ELSE
            'Inactive'
        END
      )
    WHERE 1 = 1
      AND rrto.rec_active_flag = 'Y'
      AND arp.rec_active_flag = 'Y';

  END IF;
  

  IF(V_CONTRACT_MASTER_TABLE_COUNT > 0) THEN

    UPDATE rate_rule_contract_original rrco
      LEFT JOIN audit_rate_period arp ON rrco.audit_rate_period_id = arp.id
    SET rrco.rate_status = (
        CASE
          WHEN arp.end_date IS NULL THEN
            'Active'
          ELSE
            'Inactive'
        END
      )
    WHERE 1 = 1
      AND rrco.rec_active_flag = 'Y'
      AND arp.rec_active_flag = 'Y';

  END IF;
  
  IF(V_MTM_MASTER_TABLE_COUNT > 0) THEN

    UPDATE rate_rule_mtm_original rrmo
      LEFT JOIN audit_rate_period arp ON rrmo.audit_rate_period_id = arp.id
    SET rrmo.rate_status = (
        CASE
          WHEN arp.end_date IS NULL THEN
            'Active'
          ELSE
            'Inactive'
        END
      )
    WHERE 1 = 1
      AND rrmo.rec_active_flag = 'Y'
      AND arp.rec_active_flag = 'Y';
      
  END IF;
  

END