-- Query two months items.
select 
    p.previous_proposal_id,
    p.id as proposalId,
    ii.item_name as itemName,
    p.payment_amount as paymentAmount,
    p.dispute_amount as disputeAmount,
    p.credit_amount as creditAmount,
    ac.account_code_name  as scoa,
    ii.circuit_number as circuitNumber,
    ii.stripped_circuit_number as strippedCircuitNumber,
    pt.product_name as product,
    pc.component_name as component,
    ii.start_date as fromDate,
    ii.end_date as toDate,
    p.billing_number as billingNumber,
    p.quantity as quantity,
    ii.usoc as usoc,
    ii.usoc_description as usocDescription,
    ii.line_item_code as lineItemCode,
    ii.line_item_code_description as lineItemCodeDescription
from audit_result ar
    left join proposal p on ar.proposal_id = p.id
    left join account_code ac on ac.id = p.account_code_id
    left join invoice i on i.id = p.invoice_id
    left join invoice_item ii on p.invoice_item_id = ii.id
    left join item_type it on it.id = p.item_type_id
    left join product pt on p.product_id = pt.id
    left join product_component pc on p.product_component_id = pc.id
where ii.stripped_circuit_number = '4180102210'
    and (
            ( p.invoice_id = 534348 
                and ( p.item_type_id in (13, 15) or p.item_type_id LIKE '3%' or p.item_type_id LIKE '5%') )
            OR 
            (p.invoice_id = 534348 and (p.item_type_id in (13) or p.item_type_id LIKE '3%') )
        )
    and ar.audit_reference_type_id not in (4001, 4)
    and p.rec_active_flag = 'Y'
    and ii.rec_active_flag = 'Y'
    and p.proposal_flag = 1;


SELECT bi.id
FROM invoice bi, invoice i
WHERE bi.ban_id = i.ban_id
    AND bi.invoice_date < i.invoice_date
    AND bi.rec_active_flag = 'Y'
    AND bi.invoice_status_id >= 9
    AND bi.invoice_status_id NOT IN (80, 98)
    AND i.id = V_IN_INVOICE_ID
ORDER BY bi.invoice_date DESC LIMIT 1