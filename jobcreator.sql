-- Management funds for built-in Boss Menu and Gang Menu (society money).
-- Run once if you don't already have this table from rsg-bossmenu/rsg-gangmenu.
CREATE TABLE IF NOT EXISTS `management_funds` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `job_name` VARCHAR(50) NOT NULL,
    `amount` INT(100) NOT NULL,
    `type` ENUM('boss','gang') NOT NULL DEFAULT 'boss',
    PRIMARY KEY (`id`),
    UNIQUE KEY `job_name` (`job_name`),
    KEY `type` (`type`)
);
