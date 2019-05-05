/*
Navicat MySQL Data Transfer

Source Server         : 192.168.0.71
Source Server Version : 50141
Source Host           : 192.168.0.71:3306
Source Database       : ccm_db

Target Server Type    : MYSQL
Target Server Version : 50141
File Encoding         : 65001

Date: 2019-02-20 14:50:59
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `rate_contact_length_import`
-- ----------------------------
DROP TABLE IF EXISTS `rate_contact_length_import`;
CREATE TABLE `rate_contact_length_import` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `row_no` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rate_id` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary_vendor_name` mediumtext COLLATE utf8_unicode_ci,
  `charge_type` mediumtext COLLATE utf8_unicode_ci,
  `key_field` mediumtext COLLATE utf8_unicode_ci,
  `usoc` mediumtext COLLATE utf8_unicode_ci,
  `usoc_long_description` mediumtext COLLATE utf8_unicode_ci,
  `stripped_circuit_number` mediumtext COLLATE utf8_unicode_ci,
  `sub_product` mediumtext COLLATE utf8_unicode_ci,
  `rate` mediumtext COLLATE utf8_unicode_ci,
  `effective_date` mediumtext COLLATE utf8_unicode_ci,
  `term` mediumtext COLLATE utf8_unicode_ci,
  `renewal_term_after_term_expiration` mediumtext COLLATE utf8_unicode_ci,
  `early_termination_fee` mediumtext COLLATE utf8_unicode_ci,
  `item_description` mediumtext COLLATE utf8_unicode_ci,
  `contract_name` mediumtext COLLATE utf8_unicode_ci,
  `contract_service_schedule_name` mediumtext COLLATE utf8_unicode_ci,
  `line_item_code` mediumtext COLLATE utf8_unicode_ci,
  `line_item_code_description` mediumtext COLLATE utf8_unicode_ci,
  `total_volume_begin` mediumtext COLLATE utf8_unicode_ci,
  `total_volume_end` mediumtext COLLATE utf8_unicode_ci,
  `mmbc` mediumtext COLLATE utf8_unicode_ci,
  `discount` mediumtext COLLATE utf8_unicode_ci,
  `notes` mediumtext COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=153 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- ----------------------------
-- Records of rate_contact_length_import
-- ----------------------------

-- ----------------------------
-- Table structure for `rate_length_import`
-- ----------------------------
DROP TABLE IF EXISTS `rate_length_import`;
CREATE TABLE `rate_length_import` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `row_no` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rate_id` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` mediumtext COLLATE utf8_unicode_ci,
  `key_field` mediumtext COLLATE utf8_unicode_ci,
  `rate_effective_date` mediumtext COLLATE utf8_unicode_ci,
  `summary_vendor_name` mediumtext COLLATE utf8_unicode_ci,
  `vendor_name` mediumtext COLLATE utf8_unicode_ci,
  `usoc` mediumtext COLLATE utf8_unicode_ci,
  `usoc_description` mediumtext COLLATE utf8_unicode_ci,
  `sub_product` mediumtext COLLATE utf8_unicode_ci,
  `line_item_code_description` mediumtext COLLATE utf8_unicode_ci,
  `line_item_code` mediumtext COLLATE utf8_unicode_ci,
  `item_type` mediumtext COLLATE utf8_unicode_ci,
  `item_description` mediumtext COLLATE utf8_unicode_ci,
  `quantity_begin` mediumtext COLLATE utf8_unicode_ci,
  `quantity_end` mediumtext COLLATE utf8_unicode_ci,
  `tariff_file_name` mediumtext COLLATE utf8_unicode_ci,
  `tariff_reference` mediumtext COLLATE utf8_unicode_ci,
  `base_amount` mediumtext COLLATE utf8_unicode_ci,
  `multiplier` mediumtext COLLATE utf8_unicode_ci,
  `rate` mediumtext COLLATE utf8_unicode_ci,
  `rules_details` mediumtext COLLATE utf8_unicode_ci,
  `tariff_page` mediumtext COLLATE utf8_unicode_ci,
  `pdf_page` mediumtext COLLATE utf8_unicode_ci,
  `part_section` mediumtext COLLATE utf8_unicode_ci,
  `item_number` mediumtext COLLATE utf8_unicode_ci,
  `crtc_number` mediumtext COLLATE utf8_unicode_ci,
  `discount` mediumtext COLLATE utf8_unicode_ci,
  `exclusion_ban` mediumtext COLLATE utf8_unicode_ci,
  `exclusion_item_descripton` mediumtext COLLATE utf8_unicode_ci,
  `notes` mediumtext COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4502 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- ----------------------------
-- Records of rate_length_import
-- ----------------------------

-- ----------------------------
-- Table structure for `rate_mtm_length_import`
-- ----------------------------
DROP TABLE IF EXISTS `rate_mtm_length_import`;
CREATE TABLE `rate_mtm_length_import` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `row_no` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rate_id` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` mediumtext COLLATE utf8_unicode_ci,
  `summary_vendor_name` mediumtext COLLATE utf8_unicode_ci,
  `key_field` mediumtext COLLATE utf8_unicode_ci,
  `usoc` mediumtext COLLATE utf8_unicode_ci,
  `usoc_long_description` mediumtext COLLATE utf8_unicode_ci,
  `stripped_circuit_number` mediumtext COLLATE utf8_unicode_ci,
  `sub_product` mediumtext COLLATE utf8_unicode_ci,
  `rate` mediumtext COLLATE utf8_unicode_ci,
  `effective_date` mediumtext COLLATE utf8_unicode_ci,
  `term` mediumtext COLLATE utf8_unicode_ci,
  `item_description` mediumtext COLLATE utf8_unicode_ci,
  `line_item_code` mediumtext COLLATE utf8_unicode_ci,
  `line_item_code_description` mediumtext COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=125 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- ----------------------------
-- Records of rate_mtm_length_import
-- ----------------------------

-- ----------------------------
-- Table structure for `rate_rule_contact_master_batch`
-- ----------------------------
DROP TABLE IF EXISTS `rate_rule_contact_master_batch`;
CREATE TABLE `rate_rule_contact_master_batch` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `row_no` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rate_id` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary_vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_field` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc_long_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `stripped_circuit_number` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sub_product` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate` double(20,6) DEFAULT NULL,
  `effective_date` date DEFAULT NULL,
  `term` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `renewal_term_after_term_expiration` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `early_termination_fee` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_description` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contract_name` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contract_service_schedule_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `total_volume_begin` int(11) DEFAULT NULL,
  `total_volume_end` int(11) DEFAULT NULL,
  `mmbc` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `discount` double(20,5) DEFAULT NULL,
  `notes` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=59 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- ----------------------------
-- Records of rate_rule_contact_master_batch
-- ----------------------------

-- ----------------------------
-- Table structure for `rate_rule_contact_master_import`
-- ----------------------------
DROP TABLE IF EXISTS `rate_rule_contact_master_import`;
CREATE TABLE `rate_rule_contact_master_import` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `row_no` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rate_id` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary_vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_field` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc_long_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `stripped_circuit_number` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sub_product` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `effective_date` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `term` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `renewal_term_after_term_expiration` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `early_termination_fee` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_description` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contract_name` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contract_service_schedule_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `total_volume_begin` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `total_volume_end` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mmbc` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `discount` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=128 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- ----------------------------
-- Records of rate_rule_contact_master_import
-- ----------------------------

-- ----------------------------
-- Table structure for `rate_rule_mtm_master_batch`
-- ----------------------------
DROP TABLE IF EXISTS `rate_rule_mtm_master_batch`;
CREATE TABLE `rate_rule_mtm_master_batch` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `row_no` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rate_id` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary_vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_field` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc_long_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `stripped_circuit_number` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sub_product` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate` double(20,6) DEFAULT NULL,
  `effective_date` date DEFAULT NULL,
  `term` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_description` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=54 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- ----------------------------
-- Records of rate_rule_mtm_master_batch
-- ----------------------------

-- ----------------------------
-- Table structure for `rate_rule_mtm_master_import`
-- ----------------------------
DROP TABLE IF EXISTS `rate_rule_mtm_master_import`;
CREATE TABLE `rate_rule_mtm_master_import` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `row_no` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rate_id` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary_vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_field` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc_long_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `stripped_circuit_number` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sub_product` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `effective_date` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `term` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_description` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=100 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- ----------------------------
-- Records of rate_rule_mtm_master_import
-- ----------------------------

-- ----------------------------
-- Table structure for `rate_rule_tariff_master_batch`
-- ----------------------------
DROP TABLE IF EXISTS `rate_rule_tariff_master_batch`;
CREATE TABLE `rate_rule_tariff_master_batch` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `row_no` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rate_id` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_field` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate_effective_date` date DEFAULT NULL,
  `summary_vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sub_product` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_description` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `quantity_begin` int(11) DEFAULT NULL,
  `quantity_end` int(11) DEFAULT NULL,
  `tariff_file_name` varchar(42) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tariff_name` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `base_amount` double(20,5) DEFAULT NULL,
  `multiplier` double(20,5) DEFAULT NULL,
  `rate` double(20,6) DEFAULT NULL,
  `rules_details` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tariff_page` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pdf_page` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `part_section` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_number` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `crtc_number` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `discount` double(20,5) DEFAULT NULL,
  `exclusion_ban` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `exclusion_item_description` varchar(256) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=967 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- ----------------------------
-- Records of rate_rule_tariff_master_batch
-- ----------------------------

-- ----------------------------
-- Table structure for `rate_rule_tariff_master_import`
-- ----------------------------
DROP TABLE IF EXISTS `rate_rule_tariff_master_import`;
CREATE TABLE `rate_rule_tariff_master_import` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `row_no` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rate_id` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_type` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key_field` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate_effective_date` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary_vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `vendor_name` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `usoc_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sub_product` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_code` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_type` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_description` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `quantity_begin` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `quantity_end` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tariff_file_name` varchar(42) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tariff_reference` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `base_amount` varchar(11) COLLATE utf8_unicode_ci DEFAULT NULL,
  `multiplier` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rate` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `rules_details` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tariff_page` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pdf_page` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL,
  `part_section` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `item_number` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `crtc_number` varchar(12) COLLATE utf8_unicode_ci DEFAULT NULL,
  `discount` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `exclusion_ban` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `exclusion_item_descripton` varchar(256) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4493 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- ----------------------------
-- Records of rate_rule_tariff_master_import
-- ----------------------------
