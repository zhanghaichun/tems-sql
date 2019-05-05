
/**
 * 功能：【Bill & Keep Imbalance Rates Transfer to Rate Module】
 * 1. 将 tariff_rate_by_bill_keep 表直接放到产品环境上。
 * 2. 向 tariff_file 表中插入数据
 * 3. 向 tariff 表中插入数据
 * 4. 向 vendor_group 和 vendor_group_vendor 表中插入数据
 * 5. 向 audit_reference_mapping 表中添加 ban_id 字段， 使用 @1 中语句。
 * 6. 向 audit_reference_mapping 表中插入数据
 * 7. 向 audit_rate_period 表中插入数据。
 *
 * 8. 下面是需要修改的 SQL 程序：
 *   SP_AUDIT_INVOICE_BILL_KEEP
 *   SP_AUDIT_REFERENCE_MAPPING
 *     下面的这两个存储过程中都需要剔除 key_field 是 bill_keep_ban 的记录
 *   SP_AUDIT_USAGE_RATE
 *   SP_AUDIT_MRC_OCC
 */

-- @1 
alter table audit_reference_mapping
add ban_id int after vendor_group_id;


