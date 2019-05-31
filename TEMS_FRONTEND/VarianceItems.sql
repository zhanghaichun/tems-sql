select count(1) from (
    select 
    p.id,
    ar.audit_status_id,
    au.audit_status_name,
    ii.stripped_circuit_number as strippedCircuitNumber,
    it.item_type_name as chargeType,
    p.payment_amount as currentAmount,
    (
        select payment_amount from proposal
        where id = p.previous_proposal_id
    ) as previousAmount,
    p.previous_proposal_id,
    ifnull(ii.description, ii.item_name) as itemDescription,
    ii.usoc as usoc,
    ii.line_item_code as lineItemCode,
    ii.line_item_code_description as lineItemCodeDescription,
    ii.start_date as fromDate,
    ii.end_date as toDate,
    'Tariff' as referenceType,
    ar.rate as rate,
    ar.rate_effective_date as rateEffectiveDate,
    t.rate_mode AS rateMode,
    pt.product_name as product,
    pc.component_name as subProduct,
    rrto.tariff_file_name as tariffFileName,
    rrto.tariff_page as tariffPage,
    rrto.part_section as tariffPartSection,
    rrto.item_number as itemNumber,
    rrto.crtc_number as crtcNumber,
    rrto.rules_details as ruleDetails,
    null as contractFileName,
    null as contractTermMonth,
    null as contractServiceScheduleName,
    null as contractEarlyTerminationFee

from audit_result ar
    left join audit_status au on ar.audit_status_id = au.id
    left join proposal p on ar.proposal_id = p.id
    left join invoice i on i.id = p.invoice_id
    left join invoice_item ii on p.invoice_item_id = ii.id
    left join product pt on p.product_id = pt.id
    left join product_component pc on p.product_component_id = pc.id
    left join item_type it on it.id = p.item_type_id
    left join tariff t on t.id = p.audit_reference_id
    left join rate_rule_tariff_original rrto on rrto.audit_reference_mapping_id = p.audit_reference_mapping_id

where ii.stripped_circuit_number = '4180102210'
    and p.invoice_id = 534348
    and ar.audit_status_id != 1
    and ( p.item_type_id in (13, 15) or p.item_type_id LIKE '3%' or p.item_type_id LIKE '5%' )
    and ar.audit_source_id not in (4001, 4)
    and p.audit_reference_type_id = 2
    and p.rec_active_flag = 'Y'
    and ii.rec_active_flag = 'Y'
    and p.proposal_flag = 1

union

select 
    p.id,
    ar.audit_status_id,
    au.audit_status_name,
    ii.stripped_circuit_number as strippedCircuitNumber,
    it.item_type_name as chargeType,
    p.payment_amount as currentAmount,
    (
        select payment_amount from proposal
        where id = p.previous_proposal_id
    ) as previousAmount,
    p.previous_proposal_id,
    ifnull(ii.description, ii.item_name) as itemDescription,
    ii.usoc as usoc,
    ii.line_item_code as lineItemCode,
    ii.line_item_code_description as lineItemCodeDescription,
    ii.start_date as fromDate,
    ii.end_date as toDate,
    'Contract' as referenceType,
    ar.rate as rate,
    ar.rate_effective_date as rateEffectiveDate,
    c.rate_mode AS rateMode,
    pt.product_name as product,
    pc.component_name as subProduct,
    null as tariffFileName,
    null as tariffPage,
    null as tariffPartSection,
    null as itemNumber,
    null as crtcNumber,
    null as ruleDetails,
    rrto.contract_name as contractFileName,
    rrto.term_months as contractTermMonth,
    rrto.contract_service_schedule_name as contractServiceScheduleName,
    rrto.early_termination_fee as contractEarlyTerminationFee

from audit_result ar
    left join audit_status au on ar.audit_status_id = au.id
    left join proposal p on ar.proposal_id = p.id
    left join invoice i on i.id = p.invoice_id
    left join invoice_item ii on p.invoice_item_id = ii.id
    left join product pt on p.product_id = pt.id
    left join product_component pc on p.product_component_id = pc.id
    left join item_type it on it.id = p.item_type_id
    left join contract c on c.id = p.audit_reference_id
    left join rate_rule_contract_original rrto on rrto.audit_reference_mapping_id = p.audit_reference_mapping_id

where ii.stripped_circuit_number = '4180102210'
    and p.invoice_id = 534348
    and ar.audit_status_id != 1
    and ( p.item_type_id in (13, 15) or p.item_type_id LIKE '3%' or p.item_type_id LIKE '5%' )
    and ar.audit_source_id not in (4001, 4)
    and p.audit_reference_type_id = 3
    and p.rec_active_flag = 'Y'
    and ii.rec_active_flag = 'Y'
    and p.proposal_flag = 1


union

select 
    p.id,
    ar.audit_status_id,
    au.audit_status_name,
    ii.stripped_circuit_number as strippedCircuitNumber,
    it.item_type_name as chargeType,
    p.payment_amount as currentAmount,
    (
        select payment_amount from proposal
        where id = p.previous_proposal_id
    ) as previousAmount,
    p.previous_proposal_id,
    ifnull(ii.description, ii.item_name) as itemDescription,
    ii.usoc as usoc,
    ii.line_item_code as lineItemCode,
    ii.line_item_code_description as lineItemCodeDescription,
    ii.start_date as fromDate,
    ii.end_date as toDate,
    'Vendor Rate'as referenceType,
    ar.rate as rate,
    ar.rate_effective_date as rateEffectiveDate,
    am.rate_mode AS rateMode,
    pt.product_name as product,
    pc.component_name as subProduct,
    null as tariffFileName,
    null as tariffPage,
    null as tariffPartSection,
    null as itemNumber,
    null as crtcNumber,
    null as ruleDetails,
    null as contractFileName,
    null as contractTermMonth,
    null as contractServiceScheduleName,
    null as contractEarlyTerminationFee

from audit_result ar
    left join audit_status au on ar.audit_status_id = au.id
    left join proposal p on ar.proposal_id = p.id
    left join invoice i on i.id = p.invoice_id
    left join invoice_item ii on p.invoice_item_id = ii.id
    left join product pt on p.product_id = pt.id
    left join product_component pc on p.product_component_id = pc.id
    left join item_type it on it.id = p.item_type_id
    left join audit_mtm am on am.id = p.audit_reference_id
    left join rate_rule_mtm_original rrto on rrto.audit_reference_mapping_id = p.audit_reference_mapping_id

where ii.stripped_circuit_number = '4180102210'
    and p.invoice_id = 534348
    and ar.audit_status_id != 1
    and ( p.item_type_id in (13, 15) or p.item_type_id LIKE '3%' or p.item_type_id LIKE '5%' )
    and ar.audit_source_id not in (4001, 4)
    and p.audit_reference_type_id = 18
    and p.rec_active_flag = 'Y'
    and ii.rec_active_flag = 'Y'
    and p.proposal_flag = 1

)  r 

group by r.id 