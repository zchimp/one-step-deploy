CREATE DATABASE IF NOT EXISTS `random-monitor` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `random-monitor`;

DROP TABLE IF EXISTS `rdm_agent`;
CREATE TABLE `rdm_agent` (
  `agent_id` CHAR(36) NOT NULL,
  `tenant_id` CHAR(36) NOT NULL,
  `host_name` VARCHAR(65),
  `ip` VARCHAR(65) NOT NULL,
  `version` VARCHAR(65) NOT NULL,
  `apps` blob,
  `tags` blob,
  `modified_time` datetime,
  `online_status` VARCHAR(65),
  PRIMARY KEY (`tenant_id`,`agent_id`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COMMENT = 'Agent信息表';

DROP TABLE IF EXISTS `rdm_agent_config`;
CREATE TABLE `rdm_agent_config` (
  `agent_id` CHAR(36) NOT NULL,
  `tenant_id` CHAR(36) NOT NULL,
  `file_name` VARCHAR(65),
  `file_size` int(11),
  `verification` VARCHAR(65) NOT NULL,
  `modified_time` datetime,
  `sync_time` datetime,
  `config_content` blob,
  PRIMARY KEY (`tenant_id`,`agent_id`,`file_name`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = utf8mb4 COMMENT = 'Agent配置文件表';

DROP TABLE IF EXISTS `rdm_agent_tag`;
CREATE TABLE `rdm_agent_tag` (
  `agent_id` CHAR(36) NOT NULL,
  `tenant_id` CHAR(36) NOT NULL,
  `tag_key` varchar(65) NOT NULL,
  `tag_value` varchar(65) NOT NULL,
  PRIMARY KEY (`agent_id`,`tenant_id`,`tag_key`)
) ENGINE = InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent标签表';