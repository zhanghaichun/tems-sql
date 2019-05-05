
/**
 * @desc 功能： 在 leftMenu 中添加 external approve bucket.
 *       涉及到表中字段添加， 同时表附有触发器，则相应的触发器也需要修改。
 */

-- 下面的两条 SQL 语句分别向 ban 表和 invoice 表添加 external_approve_flag
alter table ban
add external_approve_flag char(1) default 'N'
after manual_adjustment_approval_flag;

alter table invoice
add external_approve_flag char(1) default 'N'
after rec_active_flag;

-- 修改了下面四个触发器
`ccm_db`.`trace_ban_trigger_update`;
`ccm_db`.`trace_ban_trigger_delete`;
`ccm_db`.`transaction_history_by_invoice_update`;
`ccm_db`.`trace_invoice_trigger_delete`;

/**
 * 1. 左侧添加 External Approve Bucket
 * 2. Admin Tab 下的 BAN Maintenance 界面中添加一个 External Approve Flag field， 
 *  然后修改了一些样式. banDetailPage.jsp
 * 3. 左侧栏中的 count 刷新修改了相关的 js 文件。
 * 4. 邮件发送之后，点击 Approve 或者是 Reject 都有不同的操作逻辑。
 *  方法是 invoiceDetailsService#externalApproveBack.
 */
