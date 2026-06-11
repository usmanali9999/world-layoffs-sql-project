-- =================================================================================
-- PROJECT: World Layoffs Data Cleaning & Exploratory Data Analysis (EDA)
-- AUTHOR: Muhammad Usman Ali
-- DATABASE ENGINE: MySQL Workbench
-- FILE PURPOSE: Step-by-Step Data Cleaning Pipeline & Analytical Queries
-- =================================================================================

-- ---------------------------------------------------------------------------------
-- STEP 1: ENVIRONMENT SETUP & RAW DATA IMPORT
-- ---------------------------------------------------------------------------------
-- 1. Create a brand new database
CREATE DATABASE world_layoffs;

-- 2. Activate the database
USE world_layoffs;

-- 3. Create the initial raw table structure
CREATE TABLE `layoffs` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * from layoffs;


-- ---------------------------------------------------------------------------------
-- STEP 2: CREATE FIRST STAGING TABLE (DATA BACKUP)
-- ---------------------------------------------------------------------------------

-- Create an empty copy structural clone of the raw table
CREATE TABLE layoffs_staging LIKE layoffs;

-- Copy and insert all raw data into the staging table
INSERT INTO layoffs_staging 
SELECT * FROM layoffs;

-- Verify the staging data was copied successfully
SELECT * FROM layoffs_staging;

-- ---------------------------------------------------------------------------------
-- STEP 3: IDENTIFY AND REMOVE DUPLICATE RECORDS
-- ---------------------------------------------------------------------------------
-- Part A: Run a CTE check to see identical rows (row_num > 1)
WITH duplicate_cte AS
(
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY company, location,
            industry, total_laid_off, percentage_laid_off, `date`, stage,
            country, funds_raised_millions
        ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Part B: Create the physical table 'layoffs_staging_2' to allow row deletion
CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging_2;


-- Part C: Populate 'layoffs_staging2' with calculated row numbers
INSERT INTO layoffs_staging_2
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location,
        industry, total_laid_off, percentage_laid_off, `date`, stage,
        country, funds_raised_millions
    ) AS row_num
FROM layoffs_staging;


-- Part D: Delete duplicate entries safely
DELETE 
FROM layoffs_staging_2
WHERE row_num > 1;


-- Part E: Remove the temporary 'row_num' helper column
ALTER TABLE layoffs_staging_2
DROP COLUMN row_num;


-- Part F: Verify final structural check of cleaned table
SELECT * FROM layoffs_staging_2;

-- ---------------------------------------------------------------------------------
-- STEP 4: STANDARDIZING MESSY DATA FIELDS
-- ---------------------------------------------------------------------------------

-- Part A: Trim accidental leading and trailing white spaces from text columns
UPDATE world_layoffs.layoffs_staging_2
SET 
    company = TRIM(company),
    location = TRIM(location),
    industry = TRIM(industry),
    stage = TRIM(stage),
    country = TRIM(country);


-- Part B: Consolidate variations of 'Crypto' into one standardized name
UPDATE world_layoffs.layoffs_staging_2
SET 
    industry = 'Crypto'
WHERE industry LIKE 'crypto%';


-- Part C: Strip trailing periods from country names (e.g., "United States.")
UPDATE world_layoffs.layoffs_staging_2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


-- Part D: Convert text 'date' column into standard MySQL Date string format
UPDATE world_layoffs.layoffs_staging_2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');


-- Part E: Permanently change the column's physical data type to DATE
ALTER TABLE world_layoffs.layoffs_staging_2
MODIFY COLUMN `date` DATE;


-- Part F: Verify the cleaned data standards
SELECT company, industry, country, `date` FROM world_layoffs.layoffs_staging_2 LIMIT 10;

-- ---------------------------------------------------------------------------------
-- STEP 5: HANDLING MISSING AND NULL VALUES
-- ---------------------------------------------------------------------------------

-- Part A: Convert empty strings ('') into true database NULL values for the industry column
UPDATE layoffs_staging_2
SET industry = NULL
WHERE industry = '';


-- Part B: Preview the missing industry rows alongside matching companies that DO have industry data
SELECT t1.company, t1.industry, t2.industry
FROM layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
  ON t1.company = t2.company
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


-- Part C: Use a self-join to populate those missing industry values automatically
UPDATE layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


-- Part D: Review rows where both 'total_laid_off' and 'percentage_laid_off' are completely NULL
SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- Part E: Delete these completely blank rows since they provide no metrics for EDA
DELETE FROM layoffs_staging_2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- Part F: Final verification of your master cleaned table
SELECT * FROM layoffs_staging_2;

-- ---------------------------------------------------------------------------------
-- PHASE 2: EXPLORATORY DATA ANALYSIS (EDA)
-- ---------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------
-- STEP 1: INITIAL METRIC OVERVIEWS
-- ---------------------------------------------------------------------------------

-- Part A: Look at the absolute maximums to find the biggest single layoff event
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging_2;


-- Part B: View companies that completely went under (100% laid off) ordered by size
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;


-- Part C: View companies that went under ordered by funding raised
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC; 

-- ---------------------------------------------------------------------------------
-- STEP 2: HIGH-LEVEL AGGREGATIONS (WHO HIT THE HIGHEST TOTALS OVERALL)
-- ---------------------------------------------------------------------------------

-- Part A: Total layoffs by company (All-time highest losses)
SELECT company, SUM(total_laid_off) AS total_losses
FROM layoffs_staging_2
GROUP BY company
ORDER BY SUM(total_laid_off) DESC;


-- Part B: Total layoffs by industry sector
SELECT industry, SUM(total_laid_off) AS total_losses
FROM layoffs_staging_2
GROUP BY industry
ORDER BY SUM(total_laid_off) DESC;


-- Part C: Total layoffs by country
SELECT country, SUM(total_laid_off) AS total_losses
FROM layoffs_staging_2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;

-- ---------------------------------------------------------------------------------
-- STEP 3: TIME-SERIES ANALYSIS & TRENDS OVER TIME
-- ---------------------------------------------------------------------------------

-- Part A: Find the start and end dates of the entire dataset
SELECT MIN(`date`) AS start_date, MAX(`date`) AS end_date
FROM layoffs_staging_2; 


-- Part B: Total layoffs grouped by Year
SELECT YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_losses
FROM layoffs_staging_2
GROUP BY YEAR(`date`)
ORDER BY `year` DESC;


-- Part C: Total layoffs grouped by Month (using text substrings)
SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS total_losses
FROM layoffs_staging_2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC;


-- Part D: Cumulative monthly rolling total across the entire timeline
WITH Rolling_Total AS
(
    SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS total_off
    FROM layoffs_staging_2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `month`
    ORDER BY `month` ASC
)
SELECT `month`, total_off, 
       SUM(total_off) OVER(ORDER BY `month`) AS rolling_cumulative_total          
FROM Rolling_Total;

-- ---------------------------------------------------------------------------------
-- STEP 4: ADVANCED RANKING (TOP 5 WORST COMPANIES BY LAYOFFS PER YEAR)
-- ---------------------------------------------------------------------------------

-- CTE 1: Aggregate total layoffs per company per year
WITH Company_Year (company, years, total_laid_off) AS
(
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging_2
    GROUP BY company, YEAR(`date`)
),

-- CTE 2: Rank the companies within each specific year based on layoff size
Company_Year_Rank AS
(
    SELECT *, 
        DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_Year
    WHERE years IS NOT NULL
)

-- Final Filter: Pull only the top 5 ranked companies for each year
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;









