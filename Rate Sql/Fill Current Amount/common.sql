


proposal_id(一月份对应的 proposal_id), current_amount(1 月份账单的 actual amount), ii.service_type


-- 创建 current_amount_fill 表。
DROP TABLE IF EXISTS current_amount_fill;
CREATE TABLE current_amount_fill(
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  old_proposal_id int,
  new_proposal_id int,
  current_amount double(20, 5),
  service_type varchar(255),
  created_timestamp timestamp
);

alter table current_amount_fill add account_number varchar(255) after new_proposal_id; 
alter table current_amount_fill add stripped_circuit_number varchar(255) after account_number; 

alter table current_amount_fill 
  add usoc varchar(32) after stripped_circuit_number,
  add line_item_code varchar(32) after usoc,
  add line_item_code_description varchar(255) after line_item_code,
  add item_description varchar(255) after line_item_code_description;

-- 更新 service type.
update current_amount_fill c
  left join proposal p on c.old_proposal_id = p.id
  left join invoice_item ii on p.invoice_item_id = ii.id
set c.service_type = ii.service_type
where  p.rec_active_flag = 'Y'
  and ii.rec_active_flag = 'Y'
  and p.proposal_flag = 1;

-- 查询 rate date
select ii.service_type, ii.start_date, i.invoice_start_date, i.invoice_date from proposal p 
left join invoice_item ii on p.invoice_item_id = ii.id
left join invoice i on p.invoice_id = i.id 
where p.rec_active_flag = 'Y'
and p.proposal_flag = 1
and ii.rec_active_flag = 'Y'
and p.id = 254277442;

update current_amount_fill c 
  left join proposal p on c.old_proposal_id = p.id
  left join audit_reference_mapping arm on arm.id = p.audit_reference_mapping_id
set
  c.usoc = arm.usoc,
  c.line_item_code = arm.line_item_code,
  c.line_item_code_description = arm.line_item_code_description,
  c.item_description = arm.item_description
where p.rec_active_flag = 'Y'
  and arm.rec_active_flag = 'Y'
  and p.proposal_flag = 'Y';

select distinct(arm.key_field) from current_amount_fill c 
  left join proposal p on p.id = c.old_proposal_id
  left join audit_reference_mapping arm on arm.id = p.audit_reference_mapping_id
where p.rec_active_flag = 'Y'
  and arm.rec_active_flag =  'Y'
  and p.proposal_flag = 1;

select c.stripped_circuit_number, ii.stripped_circuit_number, ii.line_item_code_description, 
ii.item_description from current_amount_fill c 
  left join proposal p on p.id = c.old_proposal_id
  left join invoice_item ii on ii.id = p.invoice_item_id
  left join audit_reference_mapping arm on arm.id = p.audit_reference_mapping_id
where p.rec_active_flag = 'Y'
  and arm.rec_active_flag =  'Y'
  and p.proposal_flag = 1;


  select c.old_proposal_id, p.audit_reference_mapping_id, p.audit_reference_type_id, arm.key_field, c.stripped_circuit_number, ii.stripped_circuit_number, ii.line_item_code_description, 
ii.description from current_amount_fill c 
  left join proposal p on p.id = c.old_proposal_id
  left join invoice_item ii on ii.id = p.invoice_item_id
  left join audit_reference_mapping arm on arm.id = p.audit_reference_mapping_id
where p.rec_active_flag = 'Y'
  and arm.rec_active_flag =  'Y'
  and p.proposal_flag = 1;

select IF(
            p.invoice_item_id IS NULL , 
            0 , 
            (
              IF(
                  p.dispute_id IS NOT NULL ,
                  (IFNULL(p.payment_amount,0) + IFNULL(p.dispute_amount,0) ),
                  (IFNULL(p.payment_amount,0) + IFNULL(p.credit_amount,0) )
                )
            )
          ), from proposal p
left join invoice_item ii on p.invoice_item_id = ii.id
where p.rec_active_flag = 'Y'
  and ii.rec_active_flag = 'Y'
  and p.id = '254277442'
  and ii.stripped_circuit_number = '5062100563'


/*line_item_code_description
usoc
line_item_code
item_description
stripped_circuit_number & item_description
stripped_circuit_number & line_item_code_description
stripped_circuit_number*/
