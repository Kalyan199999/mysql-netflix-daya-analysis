create database if not exists netflix;

use netflix;

show tables;

-- Ensure the server variable is active
SET GLOBAL local_infile = 1;


-- Dropping and recreating with VARCHAR for date_added to prevent data truncation errors
DROP TABLE IF EXISTS netflix_titles;

CREATE TABLE netflix_titles (
    show_id VARCHAR(10) PRIMARY KEY,
    type VARCHAR(25),
    title VARCHAR(250),
    director VARCHAR(250),
    cast TEXT,
    country VARCHAR(250),
    date_added VARCHAR(50), -- Kept as VARCHAR for initial safety import
    releasing_year INT,
    rating VARCHAR(50),
    duration VARCHAR(50),
    listed_in TEXT,
    description TEXT
);

-- To load the data from local system to mysql workbench move the csv file to  C:/ProgramData/MySQL/MySQL Server 8.0/Uploads
--  SHOW VARIABLES LIKE 'secure_file_priv';  -- give the path from where to access the  csv file 

LOAD DATA  INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/netflix_titles.csv' 
INTO TABLE netflix_titles 
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select * from netflix_titles limit 5;

desc netflix_titles;

-- Temporarily turn off Safe Update Mode
SET SQL_SAFE_UPDATES = 0;

-- Run your date transformation query
-- Transform text like "September 25, 2021" into a real date object
UPDATE netflix_titles 
SET date_added = STR_TO_DATE(TRIM(date_added), '%M %e, %Y')
WHERE date_added IS NOT NULL AND date_added != '';

UPDATE netflix_titles 
SET date_added = NULL 
WHERE TRIM(date_added) = '' OR date_added = 'null';

-- Turn Safe Update Mode back on for security
SET SQL_SAFE_UPDATES = 1;

select * from netflix_titles where  trim(date_added) = '';
 
-- Change the column type from VARCHAR to permanent DATE
ALTER TABLE netflix_titles MODIFY COLUMN date_added DATE;

desc netflix_titles;