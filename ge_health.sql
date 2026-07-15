CREATE DATABASE ge_healthcare;
USE ge_healthcare;

CREATE TABLE device_events (
    report_number VARCHAR(50),
    event_type VARCHAR(50),
    manufacturer_link_flag CHAR(1),
    type_of_report VARCHAR(255),
    product_problem_flag CHAR(1),
    date_received DATE,
    date_of_event DATE,
    noe_summarized VARCHAR(10),
    source_type VARCHAR(255),
    date_added DATE,
    date_changed DATE,
    summary_report_flag CHAR(1),
    date_report DATE,
    mdr_report_key VARCHAR(50),
    report_source_code VARCHAR(100),
    remedial_action VARCHAR(255),
    adverse_event_flag CHAR(1),
    device_name VARCHAR(255),
    device_brand VARCHAR(255),
    patient_age VARCHAR(20),
    event_description TEXT
);

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:\Users\Sneha Choudhary\Downloads\ge_final_clean_v2.csv'
INTO TABLE device_events
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

USE ge_healthcare;
SHOW TABLES;

USE ge_healthcare;

-- Event type breakdown--
SELECT event_type, COUNT(*) AS total
FROM device_events
GROUP BY event_type
ORDER BY total DESC;

-- Top 10 device categories by number of events---
SELECT device_name, COUNT(*) AS event_count
FROM device_events
WHERE device_name IS NOT NULL AND device_name != ''
GROUP BY device_name
ORDER BY event_count DESC
LIMIT 10;



-- Top 10 device brands with most issues--
SELECT device_brand, COUNT(*) AS event_count
FROM device_events
GROUP BY device_brand
ORDER BY event_count DESC
LIMIT 10;


-- which device type have high Death/Injury  risk--
SELECT device_name, event_type, COUNT(*) AS total
FROM device_events
WHERE device_name IS NOT NULL AND device_name != ''
GROUP BY device_name, event_type
ORDER BY device_name, total DESC;

SELECT device_name, COUNT(*) AS severe_events
FROM device_events
WHERE event_type IN ('Death', 'Injury')
  AND device_name IS NOT NULL AND device_name != ''
GROUP BY device_name
ORDER BY severe_events DESC
LIMIT 10;

SELECT YEAR(date_received) AS year, COUNT(*) AS total_events
FROM device_events
GROUP BY YEAR(date_received)
ORDER BY year;


SELECT 
    device_name,
    COUNT(*) AS total_events,
    SUM(CASE WHEN event_type IN ('Death','Injury') THEN 1 ELSE 0 END) AS severe_count,
    ROUND(SUM(CASE WHEN event_type IN ('Death','Injury') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS severe_percentage
FROM device_events
WHERE device_name IS NOT NULL AND device_name != ''
GROUP BY device_name
HAVING total_events >= 5
ORDER BY severe_percentage DESC
LIMIT 10;