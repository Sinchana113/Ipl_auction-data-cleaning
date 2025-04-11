SELECT * 
FROM raw_ipl_auction_data ;

-- Step 1: Standardize team names

UPDATE RAW_IPL_AUCTION_DATA
SET TEAM = CASE
WHEN LOWER(TEAM) LIKE '%rcb%' OR LOWER(TEAM) LIKE 'ROYAL CHALLENGERS' THEN 'RCB'
WHEN LOWER(TEAM) LIKE '%mumbai%' OR LOWER(TEAM) LIKE 'mi' THEN 'MI'
WHEN LOWER(TEAM) LIKE '%chennai%' OR LOWER(TEAM) LIKE 'csk'THEN 'CSK'
ELSE TEAM
END;

-- Step 2: Clean auction status

UPDATE RAW_IPL_AUCTION_DATA
SET `auction status` = CASE
WHEN LOWER(`auction status`) LIKE '%SOLD%' THEN 'Sold'
WHEN LOWER(`auction status`) LIKE '%unSOLD%' THEN 'UnSold'
else 'unknown'
end;

-- Step 3: Fix invalid ages

UPDATE raw_ipl_auction_data
SET age = NULL
WHERE age <= 0 OR age IS NULL; 

-- Fill missing ages with average (rounded)

UPDATE raw_ipl_auction_data
SET age = (
    SELECT ROUND(AVG(age))
    FROM (SELECT age FROM raw_ipl_auction_data WHERE age IS NOT NULL) AS avg_age
)
WHERE age IS NULL;

-- Step 4: Standardize country names

UPDATE raw_ipl_auction_data
SET country = CASE
    WHEN LOWER(country) IN ('ind', 'india') THEN 'India'
    WHEN LOWER(country) IN ('aus', 'australia') THEN 'Australia'
    WHEN LOWER(country) LIKE '%south africa%' THEN 'South Africa'
    ELSE 'Unknown'
END;

-- Step 5: Clean phone numbers (remove non-numeric)

UPDATE raw_ipl_auction_data
SET phone = REGEXP_REPLACE(phone, '[^0-9]', '');

-- Set phone to NULL if invalid

UPDATE raw_ipl_auction_data
SET phone = NULL
WHERE LENGTH(phone) < 10;

-- Step 6: Clean invalid emails

UPDATE raw_ipl_auction_data
SET email = NULL
WHERE email IS NULL
  OR email = ''
  OR email NOT LIKE '%@%'
  OR email LIKE '%@@%';

-- Step 7: Clean date format

  ALTER TABLE raw_ipl_auction_data ADD COLUMN dob_clean DATE;

UPDATE raw_ipl_auction_data
SET dob_clean = 
  CASE
    WHEN `date of birth` REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN STR_TO_DATE(`date of birth`, '%d/%m/%Y')
    WHEN `date of birth` REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN STR_TO_DATE(`date of birth`, '%Y-%m-%d')
    ELSE NULL
  END;
  
  UPDATE raw_ipl_auction_data
SET `Base Price` = '100L'
WHERE LOWER(`Base Price`) IN ('1 cr', 'one crore');

UPDATE raw_ipl_auction_data
SET `Base Price` = '200L'
WHERE LOWER(`Base Price`) = '2 crore';

UPDATE raw_ipl_auction_data
SET Email = 'not_provided@email.com'
WHERE Email IS NULL;

UPDATE raw_ipl_auction_data
SET Phone = '0000000000'
WHERE Phone IS NULL;

UPDATE raw_ipl_auction_data
SET dob_clean = STR_TO_DATE(`Date of Birth`, '%d/%m/%Y')
WHERE `Date of Birth` LIKE '__/__/____';

UPDATE raw_ipl_auction_data
SET dob_clean = STR_TO_DATE(`Date of Birth`, '%Y-%m-%d')
WHERE `Date of Birth` LIKE '____-__-__';

UPDATE raw_ipl_auction_data
SET dob_clean = STR_TO_DATE(`Date of Birth`, '%m-%d-%Y')
WHERE `Date of Birth` LIKE '__-__-____';

-- EXPLORATORY DATA ANALYSIS(EDA)
-- 1.TOTAL PLAYERS AND TEAM

SELECT COUNT(*) AS TOTAL_PLAYERS
FROM raw_ipl_auction_data ;

SELECT COUNT(DISTINCT TEAM) AS TOTAL_TEAM
FROM raw_ipl_auction_data ;

-- 2 PLAYERS PER TEAM

SELECT TEAM,COUNT(*) AS TOTAL_PLAYERS_PER_TEAM
FROM raw_ipl_auction_data
GROUP BY TEAM
ORDER BY TOTAL_PLAYERS_PER_TEAM DESC ;

-- 3 PLAYERS BY AUCTION STATUS

SELECT `AUCTION STATUS`,COUNT(*) AS COUNT
FROM raw_ipl_auction_data
GROUP BY `AUCTION STATUS` ;

-- 4 AVG AND MAX BASE PRICE BY TEAM
-- Convert base price to numeric and analyze

SELECT 
  Team,
  AVG(CAST(REPLACE(`Base Price`, 'L', '') AS UNSIGNED)) AS avg_base_price,
  MAX(CAST(REPLACE(`Base Price`, 'L', '') AS UNSIGNED)) AS max_base_price
FROM raw_ipl_auction_data
WHERE `Base Price` IS NOT NULL
GROUP BY Team
ORDER BY avg_base_price DESC;

-- 5 COUNTRY WISE PLAYER COUNT
SELECT Country, COUNT(*) AS player_count
FROM raw_ipl_auction_data
GROUP BY Country
ORDER BY player_count DESC;

-- 6 MOST EXPENSIVE BASE PRICE PLAYERS

SELECT `Player Name`, Team, Country, `Base Price`
FROM raw_ipl_auction_data
ORDER BY CAST(REPLACE(`Base Price`, 'L', '') AS UNSIGNED) DESC
LIMIT 10;

-- 7 AGE DESCRIPTION OF PLAYER

SELECT Age, COUNT(*) AS player_count
FROM raw_ipl_auction_data
GROUP BY Age
ORDER BY Age;

-- 8 SOLD VS UNSOLD BY THE TEAM

SELECT Team, `Auction Status`, COUNT(*) AS count
FROM raw_ipl_auction_data
GROUP BY Team, `Auction Status`
ORDER BY Team;

-- 9 PLAYERS WITH DUPLICATE PHONE NUMBER

SELECT Phone, COUNT(*) AS count
FROM raw_ipl_auction_data
GROUP BY Phone
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- 10 SIMILAR WITH EMAIL

SELECT `Player Name`, Email
FROM raw_ipl_auction_data
WHERE Email LIKE '%not_provided%' OR Email LIKE '%email.com%';

-- 11 Team Composition by Country (Nationality Diversity)
SELECT Team, Country, COUNT(*) AS player_count
FROM raw_ipl_auction_data
GROUP BY Team, Country
ORDER BY Team, player_count DESC;

-- 12 Top Countries by Average Base Price
SELECT Country,
  AVG(CAST(REPLACE(`Base Price`, 'L', '') AS UNSIGNED)) AS avg_base_price
FROM raw_ipl_auction_data
WHERE `Base Price` IS NOT NULL AND Country IS NOT NULL
GROUP BY Country
ORDER BY avg_base_price DESC;










