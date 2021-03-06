




drop table if exists validation_analysis;
create table validation_analysis as

select  v.summary_vendor_name as "Summary Vendor Name", v.vendor_name as "Vendor Name",
b.account_number AS "BAN",i.invoice_date as "Invoice Date",date_format(i.invoice_date,'%Y%m') as "Invoice Month",i.invoice_number as "Invoice Number",
ii.circuit_number as "Circuit Number", ii.stripped_circuit_number as "Stripped Circuit Number", 
it.item_type_summary as "Charge Type",
if(p.invoice_item_id is null , 0 , (if(p.dispute_id is not null ,(ifnull(p.payment_amount,0) + ifnull(p.dispute_amount,0) ),(ifnull(p.payment_amount,0) + ifnull(p.credit_amount,0) )))) "Invoice Amount",
(case when r1.audit_status_id = 1 then 'Passed' 
         when r1.audit_status_id = 3 and r1.notes like '%does not exist in Master Inventory.' then 'Cannot Validate: Not Exists'
         when r1.audit_status_id = 3 and r1.notes like '%is TBD or UNKNOWN in Master Inventory.' then 'Cannot Validate: Service ID'
         end) as "Existence Validation",
         (case when r2.audit_status_id = 1 then 'Passed' 
         when r2.audit_status_id = 2 then 'Failed'
         when r2.audit_status_id = 3 and r2.notes like '%The circuit status is null, disconnection date is null' then 'Cannot Validate: Circuit Status is null, Disconnection Date is null'
         when r2.audit_status_id = 3 then 'Cannot Validate: Others'
         end) as "Circuit Status Validation",
         replace(s3.audit_source_notes,' Validation','') as "Rate Validation",
         as3.audit_status_name as "Rate Validation Status",
         i.invoice_start_date as "Invoice Start Date", i.invoice_end_date as "Invoice End Date", 
         ii.location as "Circuit Location",
          ii.line_item_code as "Line Item Code",ii.line_item_code_description as "Line Item Code Description",
          ii.start_date as "Item Start Date",ii.end_date as "Item End Date",p.usoc as "USOC",p.usoc_description as "USOC Description",
          p.item_name as "Item Name", ii.service_type as "Service Type",
          if(d.flag_shortpaid = 'Y', p.dispute_amount,0)		as "Short Paid Dispute Amount",
		      if(d.flag_shortpaid = 'N', p.dispute_amount,0)		as "Paid Dispute Amount",
         r3.actual_amount as "Actual Amount",  r3.expect_amount as "Expect Amount",p.rate as "Actual Rate", r3.rate as "Expect Rate",r3.rate_effective_date as "Rate Effective Date",
         (ifnull(p.quantity,0) + ifnull(p.driect_quantity,0)) as "Quantity",
         ac.account_code_name as "SCOA",
         pd.product_name as "Product",pc.component_name as "Sub Product",
         prvn.province_acronym as "Province", ps.province_source_name as "Province Source",
         rm.key_field_original as "Key Field",
         mi.service_id as "Service ID",mi.unique_circuit_id as "Unique Circuit ID",mi.service_id_match_status as "Service Id Match Status",mi.circuit_status as "Circuit Status",
  mi.disconnection_date as "Disconnection Date",mi.cost_type as "Cost Type",i.id as "Invoice Id",p.id as "Proposal Id",
         concat( u.first_name,' ',u.last_name) AS "Analyst"
from invoice i
inner join ban b on i.ban_id = b.id
inner join vendor v on b.vendor_id  = v.id
inner join invoice_item ii on ii.invoice_id = i.id
inner join proposal p on p.invoice_item_id = ii.id
left join item_type it on it.id = p.item_type_id
left join product pd on pd.id = p.product_id
left join product_component pc on pc.id = p.product_component_id
left join audit_reference_mapping rm on rm.id = p.audit_reference_mapping_id
left join user u on u.id = b.analyst_id
left join account_code ac on ac.id = p.account_code_id
left join dispute d on p.dispute_id = d.id
left join audit_result r1 on r1.proposal_id = p.id and r1.audit_source_id =  4001
left join audit_result r2 on r2.proposal_id = p.id and r2.audit_source_id =  4
left join audit_result r3 on r3.proposal_id = p.id and (r3.audit_source_id  = 1 or r3.audit_source_id like '20%' or r3.audit_source_id like '30%' or r3.audit_source_id like '18%' )
left join audit_status as3 on r3.audit_status_id = as3.id
left join audit_source s3 on r3.audit_source_id = s3.id
  LEFT JOIN (SELECT mi.ban_id, mi.stripped_circuit_number, mi.service_id,mi.service_id_match_status,mi.circuit_status,
  mi.disconnection_date,mi.cost_type,unique_circuit_id
              FROM master_inventory mi 
              GROUP BY mi.ban_id, mi.stripped_circuit_number) mi on mi.ban_id = b.id and mi.stripped_circuit_number = ii.stripped_circuit_number
left join province prvn on prvn.id = p.province_id
left join province_source ps on ps.id = p.province_source_id
where i.invoice_date between '2018-12-01' and '2019-01-31'
and p.proposal_flag = 1
and p.rec_active_flag = 'Y'
and i.invoice_status_id >= 9
and i.invoice_status_id <> 98
-- and (ii.item_type_id = 13 or  ii.item_type_id like '3%')
and ii.item_amount <> 0
order by v.summary_vendor_name, b.account_number,i.invoice_date,ii.stripped_circuit_number
;














select  v.summary_vendor_name as "Summary Vendor Name", 
b.account_number AS "BAN", concat( u.first_name,' ',u.last_name) AS "Analyst",
count(1) as "MRC Count",

 sum((case when r1.audit_status_id = 1 
 and  r2.audit_status_id in(1,2)
 and r3.id is not null
  then 1  else 0 end)) as "Overall Score",
  
   round(    sum((case when r1.audit_status_id = 1 
 and  r2.audit_status_id in(1,2)
 and r3.id is not null
  then 1  else 0 end))/count(1),4) as "Overall Score Percentage",
  
   sum((case when r1.audit_status_id = 1 
 and  r2.audit_status_id in(1)
 and r3.id is not null
  then 1  else 0 end)) as "Overall Passed",
  
   round(    sum((case when r1.audit_status_id = 1 
 and  r2.audit_status_id in(1)
 and r3.id is not null
  then 1  else 0 end))/count(1),4) as "Overall Passed Percentage",

   sum((case when r1.audit_status_id = 1 
 and  r2.audit_status_id in(2)
 and r3.id is not null
  then 1  else 0 end)) as "Overall Failed",
  
   round(    sum((case when r1.audit_status_id = 1 
 and  r2.audit_status_id in(2)
 and r3.id is not null
  then 1  else 0 end))/count(1),4) as "Overall Failed Percentage",
  
 sum((case when r1.audit_status_id = 1 then 1  else 0 end)) as "Existence Passed",
         
          round( sum((case when r1.audit_status_id = 1 then 1  else 0 end))/count(1),4) as "Existence Passed Percentage",
          
  sum((case when r1.audit_status_id = 1 or (r1.audit_status_id = 3 and r1.notes like '%is TBD or UNKNOWN in Master Inventory.') then 1  else 0 end)) as "Existence (Include Service ID Failed)",
         
          round( sum((case when r1.audit_status_id = 1 or (r1.audit_status_id = 3 and r1.notes like '%is TBD or UNKNOWN in Master Inventory.') then 1  else 0 end))/count(1),4) as "Existence (Include Service ID Failed) Percentage",    
          
       sum(   (case when r2.audit_status_id in(1,2) then 1
         else 0
         end)) as "Circuit Status",
         
        round( sum(   (case when r2.audit_status_id in(1,2) then 1
         else 0
         end))/count(1),4) as "Circuit Status Percentage",
         
        sum(  (case when r3.id is not null
         then 1
         else 0
         end)) as "Rate",
         
        round(  sum(  (case when r3.id is not null
         then 1
         else 0
         end))/count(1),4) as "Rate Percentage",
         
        sum(  (case when pd.id is not null
         then 1
         else 0
         end)) as "Product",
         
               
        round(  sum(  (case when pd.id is not null
         then 1
         else 0
         end))/count(1),4) as "Product Percentage",
         
          sum(  (case when  pd.id is not null 
         and pc.id is not null
         then 1
         else 0
         end)) as "Product/Sub Product",
         
         
          round(  sum(  (case when  pd.id is not null 
         and pc.id is not null
         then 1
         else 0
         end))/count(1),4) as "Product/Sub Product Percentage",
         
         
           sum(  (case when  prvn.id is not null 
         then 1
         else 0
         end)) as "Province",
         
         round(    sum(  (case when  prvn.id is not null 
         then 1
         else 0
         end))/count(1),4) as "Province Percentage",
         
        
         sum(  (case when mi.service_id is not null
         and mi.service_id <> ''
         then 1
         else 0
         end))  as "Service ID",
        
         round(  sum(  (case when mi.service_id is not null
         and mi.service_id <> ''
         then 1
         else 0
         end))/count(1),4)  as "Service ID Percentage"
         
        
from invoice i
inner join ban b on i.ban_id = b.id
inner join vendor v on b.vendor_id  = v.id
inner join invoice_item ii on ii.invoice_id = i.id
inner join proposal p on p.invoice_item_id = ii.id
left join product pd on pd.id = p.product_id
left join product_component pc on pc.id = p.product_component_id
left join audit_reference_mapping rm on rm.id = p.audit_reference_mapping_id
left join user u on u.id = b.analyst_id
left join account_code ac on ac.id = p.account_code_id
left join dispute d on p.dispute_id = d.id
left join audit_result r1 on r1.proposal_id = p.id and r1.audit_source_id =  4001
left join audit_result r2 on r2.proposal_id = p.id and r2.audit_source_id =  4
left join audit_result r3 on r3.proposal_id = p.id and (r3.audit_source_id like '20%' or r3.audit_source_id like '30%' or r3.audit_source_id like '18%' )
left join audit_source s3 on r3.audit_source_id = s3.id
  LEFT JOIN (SELECT mi.ban_id, mi.stripped_circuit_number, mi.service_id,mi.service_id_match_status,mi.circuit_status,
  mi.disconnection_date,mi.cost_type
              FROM master_inventory mi 
              GROUP BY mi.ban_id, mi.stripped_circuit_number) mi on mi.ban_id = b.id and mi.stripped_circuit_number = ii.stripped_circuit_number
left join province prvn on prvn.id = p.province_id
left join province_source ps on ps.id = p.province_source_id
where i.invoice_date between '2019-01-01' and '2019-01-31'
and p.proposal_flag = 1
and p.rec_active_flag = 'Y'
and i.invoice_status_id >= 9
and i.invoice_status_id <> 98
and (ii.item_type_id = 13 or  ii.item_type_id like '3%')
and ii.item_amount <> 0
group by v.summary_vendor_name, b.account_number
order by v.summary_vendor_name, b.account_number
;














drop table if exists validation_analysis;
create table validation_analysis as
select  v.summary_vendor_name as "Summary Vendor Name", v.vendor_name as "Vendor Name",
b.account_number AS "BAN",i.invoice_date as "Invoice Date",date_format(i.invoice_date,'%Y%m') as "Invoice Month",i.invoice_number as "Invoice Number",
ii.circuit_number as "Circuit Number", ii.stripped_circuit_number as "Stripped Circuit Number", 
it.item_type_summary as "Charge Type",
if(p.invoice_item_id is null , 0 , (if(p.dispute_id is not null ,(ifnull(p.payment_amount,0) + ifnull(p.dispute_amount,0) ),(ifnull(p.payment_amount,0) + ifnull(p.credit_amount,0) )))) "Invoice Amount",
(case when r1.audit_status_id = 1 then 'Passed' 
         when r1.audit_status_id = 3 and r1.notes like '%does not exist in Master Inventory.' then 'Cannot Validate: Not Exists'
         when r1.audit_status_id = 3 and r1.notes like '%is TBD or UNKNOWN in Master Inventory.' then 'Cannot Validate: Service ID'
         end) as "Existence Validation",
         (case when r2.audit_status_id = 1 then 'Passed' 
         when r2.audit_status_id = 2 then 'Failed'
         when r2.audit_status_id = 3 and r2.notes like '%The circuit status is null, disconnection date is null' then 'Cannot Validate: Circuit Status is null, Disconnection Date is null'
         when r2.audit_status_id = 3 then 'Cannot Validate: Others'
         end) as "Circuit Status Validation",
         replace(s3.audit_source_notes,' Validation','') as "Rate Validation",
         as3.audit_status_name as "Rate Validation Status",
         i.invoice_start_date as "Invoice Start Date", i.invoice_end_date as "Invoice End Date", 
         ii.location as "Circuit Location",
          ii.line_item_code as "Line Item Code",ii.line_item_code_description as "Line Item Code Description",
          ii.start_date as "Item Start Date",ii.end_date as "Item End Date",p.usoc as "USOC",p.usoc_description as "USOC Description",
          p.item_name as "Item Name", 
          if(d.flag_shortpaid = 'Y', p.dispute_amount,0)		as "Short Paid Dispute Amount",
		      if(d.flag_shortpaid = 'N', p.dispute_amount,0)		as "Paid Dispute Amount",
         r3.actual_amount as "Actual Amount",  r3.expect_amount as "Expect Amount",p.rate as "Actual Rate", r3.rate as "Expect Rate",r3.rate_effective_date as "Rate Effective Date",
         (ifnull(p.quantity,0) + ifnull(p.driect_quantity,0)) as "Quantity",
         ac.account_code_name as "SCOA",
         pd.product_name as "Product",pc.component_name as "Sub Product",
         prvn.province_acronym as "Province", ps.province_source_name as "Province Source",
         rm.key_field_original as "Key Field",
         mi.service_id as "Service ID",mi.unique_circuit_id as "Unique Circuit ID",mi.service_id_match_status as "Service Id Match Status",mi.circuit_status as "Circuit Status",
  mi.disconnection_date as "Disconnection Date",mi.cost_type as "Cost Type",i.id as "Invoice Id",p.id as "Proposal Id",
         concat( u.first_name,' ',u.last_name) AS "Analyst",
         a_street_number as "A Street Number",a_street_name as "A Street Name",a_unit as "A Unit",
         a_city as "A City",a_postal_code as "A Postal Code",a_province as "A Province",a_country as "A Country",
z_street_number as "Z Street Number",z_street_name as "Z Street Name",z_unit as "Z Unit",
z_city as "Z City",z_postal_code as "Z Postal Code",z_province as "Z Province",z_country as "Z Country",
b.line_of_business AS "LOB", cf.term_combined as "Term" , cf.expiry_date as "Expiry Date",
concat((case when p.audit_reference_type_id = 2 then 'Tariff'
when p.audit_reference_type_id = 3 then 'Contract'
when p.audit_reference_type_id = 18 then 'MtM'
end),'_',p.audit_reference_id) as "Rate Id"
from invoice i
inner join ban b on i.ban_id = b.id
inner join vendor v on b.vendor_id  = v.id
inner join invoice_item ii on ii.invoice_id = i.id
inner join proposal p on p.invoice_item_id = ii.id
left join item_type it on it.id = p.item_type_id
left join product pd on pd.id = p.product_id
left join product_component pc on pc.id = p.product_component_id
left join audit_reference_mapping rm on rm.id = p.audit_reference_mapping_id
left join user u on u.id = b.analyst_id
left join account_code ac on ac.id = p.account_code_id
left join dispute d on p.dispute_id = d.id
left join audit_result r1 on r1.proposal_id = p.id and r1.audit_source_id =  4001
left join audit_result r2 on r2.proposal_id = p.id and r2.audit_source_id =  4
left join audit_result r3 on r3.proposal_id = p.id and (r3.audit_source_id  = 1 or r3.audit_source_id like '20%' or r3.audit_source_id like '30%' or r3.audit_source_id like '18%' )
left join audit_status as3 on r3.audit_status_id = as3.id
left join audit_source s3 on r3.audit_source_id = s3.id
left join contract c on p.audit_reference_type_id = 3 and p.audit_reference_id = c.id
left join contract_file cf on cf.id = c.contract_file_id
  LEFT JOIN (SELECT mi.ban_id, mi.stripped_circuit_number, mi.service_id,mi.service_id_match_status,mi.circuit_status,
  mi.disconnection_date,mi.cost_type,unique_circuit_id,
  a_street_number,a_street_name,a_unit,a_city,a_postal_code,a_province,a_country,
z_street_number,z_street_name,z_unit,z_city,z_postal_code,z_province,z_country
              FROM master_inventory mi 
              GROUP BY mi.ban_id, mi.stripped_circuit_number) mi on mi.ban_id = b.id and mi.stripped_circuit_number = ii.stripped_circuit_number
left join province prvn on prvn.id = p.province_id
left join province_source ps on ps.id = p.province_source_id
where i.invoice_date between '2018-12-01' and '2018-12-31'
and p.proposal_flag = 1
and p.rec_active_flag = 'Y'
and i.invoice_status_id >= 9
and i.invoice_status_id <> 98
-- and (ii.item_type_id = 13 or  ii.item_type_id like '3%')
and ii.item_amount <> 0
order by v.summary_vendor_name, b.account_number,i.invoice_date,ii.stripped_circuit_number



