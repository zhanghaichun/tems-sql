


SELECT a.name
 FROM mysql.proc a
 WHERE 1 = 1
       AND a.db = 'ccm_db'
       AND a.body LIKE '%but cannot find the relevant rate in proposal.%'

       

call SP_AUDIT_INVOICE(574173);

SELECT * FROM  audit_result ar
where ar.rec_active_flag = 'Y'
  and ar.invoice_id = 574173
  and audit_reference_type_id = 2;

  select 0 + cast(1.000 as char);


  SELECT arp.rate
      FROM audit_rate_period arp
      WHERE arp.reference_table = 'tariff'
        AND arp.reference_id = 795
        AND '2018-07-04' >= arp.start_date
        AND (CASE
             WHEN arp.end_date IS NOT NULL
             THEN
                '2018-07-04' < arp.end_date
             ELSE
                arp.end_date IS NULL
          END)
        ORDER BY arp.rate DESC;

        250568279

select ii.start_date, i.invoice_date, i.invoice_start_date from proposal p 
left join invoice_item ii on p.invoice_item_id  = ii.id
left join invoice i on p.invoice_id = i.id
where p.id = 250568279;

select max(id) into @max_id from event_journal;
call SP_AUDIT_INVOICE(574173);
select * from event_journal
where id > @max_id;

 SELECT a.name
 FROM mysql.proc a
 WHERE 1 = 1
       AND a.db = 'ccm_db'
       AND a.body LIKE '%SP_AUDIT_RULE_RATE_BY_ANY%'



SELECT * FROM audit_reference_mapping
where rec_active_flag = 'Y' 
and audit_reference_type_id = 3
and vendor_name is not null;

SELECT * FROM audit_reference_mapping
where rec_active_flag = 'Y' 
and audit_reference_type_id = 18
and vendor_name is not null;

SELECT * FROM audit_key_field
where audit_reference_type_id = 3;

delete FROM audit_key_field
where id in (37, 39, 44, 45);

SELECT * FROM audit_key_field
where audit_reference_type_id = 18;

delete FROM audit_key_field
where id in (59, 61, 64);

SELECT CONVERT(100056.256 ,DECIMAL(12 , 2));
SELECT CASE(100056.256 AS DECIMAL(12 , 2));

SELECT POSITION('.' IN 1.2687);

SELECT LOCATE('.' , 1.2687);

SELECT * FROM  audit_result ar
where ar.rec_active_flag = 'Y'
  and ar.invoice_id = 571861
  and audit_reference_type_id = 3;

call SP_AUDIT_INVOICE(571861);

SELECT * FROM  rate_rule_contract_original
where rec_active_flag = 'Y'
and contract_name = 'Customer Volume Pricing Plan';

select * from audit_reference_mapping
where id = 3152;

update rate_rule_contract_original
set rec_active_flag = 'N'
where id = 3265;

select * from audit_rate_period
where id = 15177;

SELECT LEFT('this', 2); -- 'th'
SELECT RIGHT('this', 2); -- 'is'

SELECT SUBSTRING_INDEX('telus or bell', ' or ', 1) -- 'teles'
SELECT SUBSTRING_INDEX('telus or bell', ' or ', -1) -- 'bell'
SELECT SUBSTRING_INDEX('telus or bell', ' or ', -2) -- 'telus or bell'

SELECT LOCATE('is', 'thisandthis', 5) -- 10

select audit_reference_id from prod_audit_reference_mapping_backup
where rec_active_flag = 'Y'
  and audit_reference_type_id = 2
  and vendor_name = 'TELUS (BC)'
  and line_item_code = '8071';

-- 541
select * from prod_audit_rate_period_backup
where rec_active_flag = 'Y'
  and reference_table = 'tariff'
  and reference_id = 541;


update prod_audit_rate_period_backup
set rules_details = '7. Optional Features (a) Calling Line Identification'
where rec_active_flag = 'Y'
  and reference_table = 'tariff'
  and reference_id = 541;

-- 603732
SELECT * from audit_result
group by invoice_id
order by invoice_id DESC
limit 20;

SELECT * from audit_result
where invoice_id = 603732
  and audit_reference_type_id = 2;

call SP_AUDIT_INVOICE(603732);

select length('this'); -- 4

select length('00/00/000');

select length( replace('00/00/000', '/', '') );

SELECT SUBSTRING( '00/12/000', POSITION('/' IN '00/12/000' ) + 1, 2 );

SELECT 1 = '01';

select max(id) into @max_id from event_journal;
select * from event_journal where id > @max_id;

select * from audit_key_field
where audit_reference_type_id = 2
and key_field_original like '%bill%';

delete from audit_key_field
  where audit_reference_type_id = 2
and key_field_original like '%bill%';


-- Item Description & SVN & Qty

select * from rate_rule_contract_original
order by id desc 
limit 10;

select * from rate_rule_contract_original
where id = 3228;

select * from prod_rate_rule_contract_original_backup
where id = 3228;

select * from ban
where rec_active_flag = 'Y'
and account_number = 'ZIPTEL';

-- vendor_id = 447
-- ban_id = 10410

select * from invoice
where rec_active_flag = 'Y'
and ban_id = 10410
and invoice_date > '2018-08-01'

alter table tmp_invoice_audit
change validation_flag validation_flag varchar(1) default 'N';

select * from tmp_invoice_audit;

select * from vendor_group;

select * from contract;

select * from tariff;

select * from tariff_file;

desc audit_reference_mapping;

desc contract_file;

desc contract;

select * from contract_file;

select * from contract;

select * from vendor_group;
select * from event_logs;

desc audit_mtm;
desc audit_reference_mapping_exclusion;

TRUNCATE event_logs;

DROP PROCEDURE IF EXISTS TEST;
CREATE PROCEDURE TEST()

BEGIN
  

  DECLARE V_GROUP_NAME VARCHAR(256);
  DECLARE V_GROUP_ID VARCHAR(256);
  DECLARE V_DONE BOOLEAN DEFAULT FALSE;

  DECLARE V_VENDOR_GROUP_CURSOR CURSOR FOR 
    SELECT id FROM vendor_group;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET V_DONE =TRUE;

  -- SELECT group_name INTO V_GROUP_NAME
  -- FROM vendor_group
  -- WHERE id = 300;

  OPEN V_VENDOR_GROUP_CURSOR;

    READ_LOOP: LOOP 

      FETCH V_VENDOR_GROUP_CURSOR INTO V_GROUP_ID;

      IF (V_DONE) THEN
        LEAVE READ_LOOP;
      END IF;

      SELECT group_name INTO V_GROUP_NAME
      FROM vendor_group
      WHERE id = 300;

      INSERT INTO event_logs(event_type, notes) 
      VALUES(V_DONE,'V_GROUP_NAME');

    END LOOP;
  CLOSE V_VENDOR_GROUP_CURSOR;
END;

call TEST();

update vendor_group
set group_name = null
where id = 1;

-- 在循环之外的 select into 语句是会改变 boolean 类型变量的默认值的
-- 但是使用 set 语句就不会。

TRUNCATE event_logs;
call TEST();
select * from event_logs;

create table department (  
    id int unsigned not null auto_increment,  
    name char(20) not null,  
    primary key (id)  
)engine=innodb default charset=utf8;  
  
insert department(id,name) values(1,'技术部'),(2,'行政部'),(3,'人力部'),(4,'运营部'),(5,'财务部'),(6,'法务部'),(7,'市场部'),(8,'商务部'),(9,'客服部'); 


create table employee (
  id int not null auto_increment primary key,
  name char(20) not null,
  entry_date date not null,
  department_id int unsigned not null,
  constraint fk_employee_department foreign key(department_id) references  department(id)
) engine=innodb default charset=utf8;
 
insert employee(id, name, entry_date, department_id) values(1, '张三', '2013-05-10',1),(2, '李四','2013-06-10',1),(3, '赵六','2013-05-10',2),(4, '薛七','2015-05-10',3),(5, '王麻子','2010-05-10',4),(6, '小六子','2013-08-10',5),(7, '赵云','2013-06-10',5),(8, '张飞','2013-10-10',5),(9, '关羽','2015-05-10',5),(10, '郭芙蓉','2013-01-10',9),(11, '凤姐','2012-05-10',9),(12, '芙蓉街','2013-01-10',9),(13, '魏延','2014-12-10',9),(14, '周瑜','2012-05-18',9),(15, '兵丁1','2014-03-10',9),(16, '王五','2016-01-10',2);

  比如有一个需求：部门表中要增加最近一次员工入职时间，并要求从员工表中找出每个部门中最近入职时间的员工入职时间设置到部门表中，如果有部门没有员工的话，则不管。
下面用存储过程实现，大概思路：先定义一个所有部门的游标，然后遍历此游标，根据游标中的部门id去员工表中查找最近一次入职的员工时间，存在的话，就更新部门记录。

alter table department
add latest_entry_date date after name;
desc department;

desc employee;

SELECT * FROM employee
order by department_id desc, entry_date desc;

SELECT * FROM employee limit 10;

SELECT department_id, count(*) FROM employee 
GROUP BY department_id;

SELECT department_id, count(*) as count FROM employee 
GROUP BY department_id
having count > 2;

select concat_ws(',', 'firstname', 'lastname', 'fullname'); -- 'firstname,lastname,fullname'
select concat_ws(',', 'firstname', 'lastname');
select concat_ws(2, 'firstname', 'lastname'); -- 'firstname2lastname'
select concat_ws(2, 3, 5);-- '325'
select concat_ws(',', 'firstname');

select concat_ws(',', 'firstname', 'lastname', null); -- 'firstname,lastname'
select concat_ws(null, 'firstname', 'lastname', null); -- null

select concat('1', '2w'); -- '12w'
select concat(null, '2w'); -- 'null'

desc proposal;

show index from proposal;

show procedure SP_AUDIT_INVOICE;

show columns from proposal;


-- 
select * from vendor
where rec_active_flag = 'Y'
and vendor_status_id =  1
and summary_vendor_name like '%LEVEL 3 COMMUNICATIONS, LLC%';

select * from vendor
where rec_active_flag = 'Y'
and vendor_status_id =  1
and summary_vendor_name like '%LLC%';


