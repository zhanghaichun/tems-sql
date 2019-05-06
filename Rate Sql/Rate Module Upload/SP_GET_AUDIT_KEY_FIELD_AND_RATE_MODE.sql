
DROP PROCEDURE IF EXISTS SP_GET_AUDIT_KEY_FIELD_AND_RATE_MODE;
CREATE PROCEDURE SP_GET_AUDIT_KEY_FIELD_AND_RATE_MODE(
  IN PARAM_ORIGINAL_KEY_FIELD VARCHAR(64),
  IN RATE_TYPE VARCHAR(32),
  OUT PARAM_AUDIT_KEY_FIELD VARCHAR(64),
  OUT PARAM_RATE_MODE VARCHAR(64),
  OUT PARAM_REFERENCE_TABLE VARCHAR(64)
)

BEGIN
  
    IF(RATE_TYPE = 'contract') THEN

        SELECT 
            key_field,
            rate_mode,
            reference_table
                INTO
                    PARAM_AUDIT_KEY_FIELD,
                    PARAM_RATE_MODE,
                    PARAM_REFERENCE_TABLE
        FROM audit_key_field 
        WHERE audit_reference_type_id = 3
            AND key_field_original = PARAM_ORIGINAL_KEY_FIELD
        LIMIT 1;

    ELSEIF(RATE_TYPE = 'tariff') THEN

        SELECT 
            key_field,
            rate_mode,
            reference_table
                INTO
                    PARAM_AUDIT_KEY_FIELD,
                    PARAM_RATE_MODE,
                    PARAM_REFERENCE_TABLE
        FROM audit_key_field 
        WHERE audit_reference_type_id = 2
            AND key_field_original = PARAM_ORIGINAL_KEY_FIELD
        LIMIT 1;

    ELSEIF(RATE_TYPE = 'mtm') THEN

        SELECT 
            key_field,
            rate_mode,
            reference_table
                INTO
                    PARAM_AUDIT_KEY_FIELD,
                    PARAM_RATE_MODE,
                    PARAM_REFERENCE_TABLE
        FROM audit_key_field 
        WHERE audit_reference_type_id = 18
            AND key_field_original = PARAM_ORIGINAL_KEY_FIELD
        LIMIT 1;

    END IF;

END;