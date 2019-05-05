DROP PROCEDURE IF EXISTS SP_SHOW_CVPP_BELL_AND_ALIANT_INVOICE_ITEM;
CREATE PROCEDURE `SP_SHOW_CVPP_BELL_AND_ALIANT_INVOICE_ITEM`(V_INVOICE_ID INT(11))
BEGIN

  /**
   * Query CVPP invoice item.
   * SUMMARY_VENDOR_NAME: BELL CANADA & ALIANT
   */
  
  DECLARE V_SUMMARY_VENDOR_NAME VARCHAR(128);

  DROP TABLE IF EXISTS tmp_cvpp_proposal;
  CREATE TEMPORARY TABLE tmp_cvpp_proposal(
    summary_vendor_name VARCHAR(128),
    BAN VARCHAR(64),
    invoice_id INT,
    proposal_id INT,
    payment_amount DOUBLE(20,5),
    usoc VARCHAR(32),
    usoc_description VARCHAR(256),
    item_description VARCHAR(256)
  );
      
  SET V_SUMMARY_VENDOR_NAME = (
      SELECT v.summary_vendor_name
      FROM vendor v, invoice i
      WHERE i.vendor_id = v.id AND i.id = V_INVOICE_ID
    );

  IF V_SUMMARY_VENDOR_NAME = 'BELL CANADA' THEN

    INSERT INTO tmp_cvpp_proposal (
        summary_vendor_name,
        BAN,
        invoice_id,
        proposal_id,
        payment_amount,
        usoc,
        usoc_description,
        item_description
      )
    SELECT 
      v.summary_vendor_name,
      b.account_number,
      i.id,
      p.id, 
      (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0)) AS payment_amount,
      p.usoc,
      p.usoc_description,
      p.description
    FROM proposal p, invoice i, ban b, vendor v
    WHERE i.id = p.invoice_id
      AND i.ban_id = b.id
      AND i.vendor_id = v.id
      AND p.invoice_id = V_INVOICE_ID
      AND (p.item_type_id IN (13) OR p.item_type_id LIKE '3%')
      AND (
        (b.account_number = 'B1ES2A5201102' AND p.usoc IN('1HWNS','1HWMS') )
        OR 
        (b.account_number = 'B1ES4A0318555' AND p.usoc = '1HWMS')
        OR 
        (b.account_number = 'B1ES9A8501304' AND p.usoc = '1HWNS')
        OR 
        (b.account_number = 'B1ES9B1616135' AND p.usoc = '1HWMS')
        OR 
        (b.account_number = 'B1FS1Q0911102' AND p.usoc IN('1HWNS','1HWMS'))
        OR 
        (b.account_number = 'B1FS4O1823165' AND p.usoc = '1HWMS')
        OR 
        (b.account_number = 'B1FS7A0031555' AND p.usoc = '1HWMS')
        OR 
        (b.account_number = 'N9550000' AND p.usoc = 'MPDSB')
        OR (
              p.usoc IN ('DTBD1', 'M3ABA', 'MGSD1', 'MGSL4', 'MPAC1', 'MPACD',
                        'MPDS1', 'MPDS3', 'MPDSA', 'MPDSP', 'MPDSR', 'MRSPT', 'MTBPT')
              AND 
              b.account_number = 'T6011329'
            )
      )
      AND p.proposal_flag = 1
      AND p.rec_active_flag = 'Y';
                    
  ELSEIF V_SUMMARY_VENDOR_NAME = 'ALIANT' THEN

    INSERT INTO tmp_cvpp_proposal (
        summary_vendor_name,
        BAN,
        invoice_id,
        proposal_id,
        payment_amount,
        usoc,
        usoc_description,
        item_description
      )
    SELECT 
      v.summary_vendor_name,
      b.account_number,
      i.id,
      p.id, 
      (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0)) AS payment_amount,
      p.usoc,
      p.usoc_description,
      p.description
    FROM proposal p, invoice i, ban b, vendor v
    WHERE p.invoice_id = V_INVOICE_ID
      AND i.id = p.invoice_id
      AND i.ban_id = b.id
      AND i.vendor_id = v.id
      AND (p.item_type_id IN (13) OR p.item_type_id LIKE '3%')
      AND (
        p.description LIKE '%INTER OFFICE DIGITAL CHANNEL DS-0%'
        OR p.description LIKE '%INTER-OFFICE DIGITAL CHANNEL DS-0%'
      )
      AND p.proposal_flag = 1
      AND p.rec_active_flag = 'Y';

  END IF;

  INSERT INTO tmp_cvpp_proposal (
      summary_vendor_name,
      BAN,
      invoice_id,
      proposal_id,
      payment_amount,
      usoc,
      usoc_description,
      item_description
    )
  SELECT 
    v.summary_vendor_name,
    b.account_number,
    i.id,
    p.id, 
    (IFNULL(p.payment_amount, 0) + IFNULL(p.credit_amount, 0)) AS payment_amount,
    p.usoc,
    p.usoc_description,
    p.description
  FROM proposal p, invoice i, ban b, vendor v
  WHERE p.invoice_id = V_INVOICE_ID
    AND (p.item_type_id IN (15) OR p.item_type_id LIKE '5%')
    AND p.usoc IN ('1HWNS','MPDSB','DTBD1','M3ABA','MGSD1','MGSL4','MPAC1',
                    'MPACD','MPDS1','MPDS3','MPDSA','MPDSP','MPDSR','MRSPT','MTBPT')
    AND (
      p.description LIKE '%CREDIT FOR ACCESS SERVICE REMOVED%'
      OR p.description LIKE '%CREDIT FOR SERVICE REMOVED%'
      OR p.description LIKE '%CHARGE FOR ACCESS SERVICE ADDED%'
      OR p.description LIKE '%CHARGE FOR SERVICE ADDED%'
    )
    AND p.proposal_flag = 1
    AND p.rec_active_flag = 'Y';

  SELECT * FROM tmp_cvpp_proposal;
          
END;