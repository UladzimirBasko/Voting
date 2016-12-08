-- MySQL Script generated by MySQL Workbench
-- 12/03/16 21:22:44
-- Model: New Model    Version: 1.0
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema vote_db_schema
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `vote_db_schema` ;

-- -----------------------------------------------------
-- Schema vote_db_schema
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `vote_db_schema` DEFAULT CHARACTER SET utf8 ;
USE `vote_db_schema` ;

-- -----------------------------------------------------
-- Table `vote_db_schema`.`vt_region`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `vote_db_schema`.`vt_region` ;

CREATE TABLE IF NOT EXISTS `vote_db_schema`.`vt_region` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `vote_db_schema`.`vt_voted_passport`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `vote_db_schema`.`vt_voted_passport` ;

CREATE TABLE IF NOT EXISTS `vote_db_schema`.`vt_voted_passport` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `uni_number` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uni_number_UNIQUE` (`uni_number` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `vote_db_schema`.`vt_participant`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `vote_db_schema`.`vt_participant` ;

CREATE TABLE IF NOT EXISTS `vote_db_schema`.`vt_participant` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL,
  `region_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `region_fk_idx` (`region_id` ASC),
  CONSTRAINT `region_fk`
    FOREIGN KEY (`region_id`)
    REFERENCES `vote_db_schema`.`vt_region` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `vote_db_schema`.`vt_participant_result`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `vote_db_schema`.`vt_participant_result` ;

CREATE TABLE IF NOT EXISTS `vote_db_schema`.`vt_participant_result` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `vote_count` VARCHAR(45) NOT NULL,
  `participant_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `participant_fk_idx` (`participant_id` ASC),
  CONSTRAINT `participant_fk`
    FOREIGN KEY (`participant_id`)
    REFERENCES `vote_db_schema`.`vt_participant` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

USE `vote_db_schema`;

DELIMITER $$

USE `vote_db_schema`$$
DROP TRIGGER IF EXISTS `vote_db_schema`.`vt_participant_AFTER_INSERT` $$
USE `vote_db_schema`$$
CREATE DEFINER = CURRENT_USER TRIGGER `vote_db_schema`.`vt_participant_AFTER_INSERT` AFTER INSERT ON `vt_participant` FOR EACH ROW
BEGIN
	INSERT INTO `vote_db_schema`.`vt_participant_result`
   ( id,
     vote_count,
     participant_id)
   VALUES
   ( null,
     0,
     NEW.id );
END$$


DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
