-- 不做 修改 tariff_name 和 tariff file 的标记了。
update tariff_file
set tariff_name = 'Bell AST/7516' -- 系统数据库中包含这条记录 tariff_file_id = 32
where tariff_name = 'Bell Canada ACCESS SERVICE TARIFF CRTC 7516'
	and id = 50;

update tariff_file
set tariff_name = 'Bell MTS/24006'
where tariff_name = 'Bell MTS CRTC 24006'
	and id = 51;

update tariff_file
set tariff_name = 'SaskTel CAT/21414' -- 系统数据库中包含这条记录 tariff_file_id = 41
where tariff_name = 'SaskTel COMPETITOR ACCESS TARIFF CRTC 21414'
	and id = 52;

update tariff_file
set tariff_name = 'TELUS CAT/1017'
where tariff_name = 'TELUS CARRIER ACCESS TARIFF CRTC 1017'
	and id = 53;

update tariff_file
set tariff_name = 'Telus Quebec AST/25082'
where tariff_name = 'Telus Quebec Access Services Tariff CRTC 25082'
	and id = 54;

update tariff_file
set tariff_name = 'TELUS CAT/18008'
where tariff_name = 'TELUS CARRIER ACCESS TARIFF CRTC 18008'
	and id = 55;

update tariff_file
set tariff_name = 'Iristel AST/21670'
where tariff_name = 'Iristel ACCESS SERVICES TARIFF CRTC 21670'
	and id = 56;

update tariff_file
set tariff_name = 'Shaw Telecom G.P./21520'
where tariff_name = 'Shaw Telecom G.P. CRTC 21520'
	and id = 57;

update tariff_file
set tariff_name = 'Allstream AST/21170'
where tariff_name = 'Allstream ACCESS SERVICES TARIFF CRTC 21170'
	and id = 58;

update tariff_file
set tariff_name = 'Telebec GT/25140' -- 系统数据库中包含这条记录 tariff_file_id = 45
where tariff_name = 'Telebec General CRTC 25140'
	and id = 59;

-- 更新 tariff 表的 bill keep 相关信息。
update tariff
set tariff_file_id = 32
where id = 862;

update tariff
set tariff_file_id = 41
where id = 865;

update tariff
set tariff_file_id = 45
where id = 867;

update tariff
set name = 'Bell AST/7516/2/105.4 (d)(1)'
where id = 862;

update tariff
set name = 'SaskTel CAT/21414/610.18.4.3(a)'
where id = 865;

update tariff
set name = 'Telebec GT/25140/7/7.8.4 (8) a) (v)'
where id = 867;

update tariff
set name = 'Bell MTS/24006/II/105.4 (D)(1)'
where id = 863;

update tariff
set name = 'TELUS CAT/1017/150 (D) 4 (a)'
where id = 868;

update tariff
set name = 'Telus Quebec AST/25082/1.05/1.05.04 (d)(1)'
where id = 870;

update tariff
set name = 'TELUS CAT/18008/215.4 (2)(b)(i)'
where id = 869;

update tariff
set name = 'Iristel AST/21670/B/201'
where id = 864;

update tariff
set name = 'Shaw Telecom G.P./21520/B/201'
where id = 866;

update tariff
set name = 'Allstream AST/21170/B/201'
where id = 861;