


ALTER TABLE tariff ADD version VARCHAR(16) DEFAULT 'v1' AFTER tariff_file_id ;

ALTER TABLE audit_rate_period ADD version VARCHAR(16) DEFAULT 'v1' AFTER rules_details ;



CREATE TABLE tariff_history_version(
    `id` INT not null auto_increment  ,
    `tariff_id` INT,

    `tariff_file_id` int(11) DEFAULT NULL,
    `version` VARCHAR(16),
  `name` VARCHAR(1000) COLLATE utf8_unicode_ci DEFAULT NULL,
  
  `rate_mode` VARCHAR(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate_effective_date` VARCHAR(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate` double(20,6) DEFAULT NULL,
  `multiplier` double(20,5) DEFAULT NULL,
  `discount` double(20,5) DEFAULT NULL,
  `page` VARCHAR(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pdf_page` VARCHAR(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `part_section` VARCHAR(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_number` VARCHAR(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `paragraph` VARCHAR(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `band` VARCHAR(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `provider` VARCHAR(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `source` VARCHAR(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_timestamp` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `modified_timestamp` datetime DEFAULT NULL,
  `modified_by` int(11) DEFAULT NULL,
  `rec_active_flag` char(1) COLLATE utf8_unicode_ci DEFAULT 'Y',
PRIMARY key (`id`),
KEY `tariff_id` (`tariff_id`),
FOREIGN KEY (`tariff_id`) REFERENCES `tariff` (`id`)
);


UPDATE tariff
SET version = 'v2'
WHERE id BETWEEN 517 AND 520;


update audit_rate_period
set version = 'v2'
where reference_table = 'tariff'
and reference_id between 517 and 520
and end_date is null;




insert into tariff_history_version(tariff_id, tariff_file_id, version, name, rate_mode, rate_effective_date, rate,
page, pdf_page, part_section, item_number, source, created_timestamp)

values(517, 33, 'v1', 'Bell Aliant GT/21491/6/608/6(d)(viii)', 'rate', '2017/06/01', 0.86, '605.12', '442',
'6', '608', 'Rogers', now()),

(517, 33, 'v2', 'Bell Aliant GT/21491/6/608/6(d)(viii)(c)', 'rate', '2018/06/01', 0.85, '605.12', '445',
'6', '608', 'Rogers', now()),

(518, 33, 'v1', 'Bell Aliant GT/21491/6/608/6(d)(viii)', 'rate', '2017/06/01', 1.27, '605.12', '442',
'6', '608', 'Rogers', now()),

(518, 33, 'v2', 'Bell Aliant GT/21491/6/608/6(d)(viii)(c)', 'rate', '2018/06/01', 1.26, '605.12', '445',
'6', '608', 'Rogers', now()),

(519, 33, 'v1', 'Bell Aliant GT/21491/6/608/6(d)(viii)', 'rate', '2017/06/01', 1.1, '605.12', '442',
'6', '608', 'Rogers', now()),

(519, 33, 'v2', 'Bell Aliant GT/21491/6/608/6(d)(viii)(c)', 'rate', '2018/06/01', 1.09, '605.12', '445',
'6', '608', 'Rogers', now()),

(520, 33, 'v1', 'Bell Aliant GT/21491/6/608/6(d)(viii)', 'rate', '2017/06/01', 1.28, '605.12', '442',
'6', '608', 'Rogers', now()),

(520, 33, 'v2', 'Bell Aliant GT/21491/6/608/6(d)(viii)(c)', 'rate', '2018/06/01', 1.27, '605.12', '445',
'6', '608', 'Rogers', now());



/*
FN_GET_VERSIONED_FIELD_VALUE  
FN_GET_VALIDATION_RESULT_TARIFF_LINK
 */

/*

代码文件修改：
  
    RateSearchDaoImpl.java => 将普通字段的搜索调用存储过程搜索 "tariff_name", "pdf_page"
    invoiceDetailServiceImpl.java => queryValidationReferenceInfo 方法中另外传入一个参数，audit result id.
    IInvoiceDetailDao.java => 重写 queryValidationReferenceInfo 接口。
    InvoiceDetailDaoImpl.java => 修改了 queryValidationReferenceInfo 方法。
    MasterInventoryDaoImpl.java => searchMasterInventoryRateShowCol 中 tariff name 的获取改成了使用函数来获取。
 */