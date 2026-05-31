-- ============================================================
-- PROJECT  : Tech Layoffs Data Cleaning
-- TOOL     : MySQL Workbench
-- DATASET  : Global Tech Layoffs (2020–2023)
-- AUTHOR   : Somya Kala
-- PURPOSE  : Clean raw layoffs data to prepare it for analysis
-- ============================================================

-- ============================================================
-- STEP 1 : INSPECT RAW DATA
-- ============================================================

SELECT * FROM layoffs;


-- ============================================================
-- STEP 2 : CREATE A STAGING TABLE
-- Never modify raw data directly. Work on a copy.
-- ============================================================

CREATE TABLE layoffs_staging 
SELECT * FROM layoffs;

SELECT * FROM layoffs_staging;


-- ============================================================
-- STEP 3 : REMOVE DUPLICATE ROWS
-- ============================================================

-- 3a. Identify duplicates using ROW_NUMBER()
--     Rows with row_num > 1 are duplicates

SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, 
                     total_laid_off, percentage_laid_off, 
                     `date`, stage, country, funds_raised_millions
    ) AS row_num
FROM layoffs_staging;


-- 3b. Create a second staging table with row_num column

CREATE TABLE layoffs_staging2 (
    `company`               TEXT,
    `location`              TEXT,
    `industry`              TEXT,
    `total_laid_off`        INT DEFAULT NULL,
    `percentage_laid_off`   TEXT,
    `date`                  TEXT,
    `stage`                 TEXT,
    `country`               TEXT,
    `funds_raised_millions` INT DEFAULT NULL,
    `row_num`               INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- 3c. Insert data with row numbers into staging2

INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry,
                     total_laid_off, percentage_laid_off,
                     `date`, stage, country, funds_raised_millions
    ) AS row_num
FROM layoffs_staging;


-- 3d. Verify duplicates before deleting

SELECT * FROM layoffs_staging2 WHERE row_num > 1;


-- 3e. Delete duplicate rows

SET SQL_SAFE_UPDATES = 0;

DELETE FROM layoffs_staging2 WHERE row_num > 1;


-- ============================================================
-- STEP 4 : STANDARDIZE DATA
-- ============================================================

-- 4a. Trim leading/trailing whitespace from company names

UPDATE layoffs_staging2 
SET company = TRIM(company);


-- 4b. Fix inconsistent industry names
--     e.g. 'Crypto Currency', 'CryptoCurrency' → 'Crypto'

SELECT DISTINCT industry 
FROM layoffs_staging2 
ORDER BY 1;

UPDATE layoffs_staging2 
SET industry = 'Crypto' 
WHERE industry LIKE 'Crypto%';


-- 4c. Fix inconsistent country names
--     e.g. 'United States.' → 'United States'

SELECT DISTINCT country 
FROM layoffs_staging2 
ORDER BY 1;

UPDATE layoffs_staging2 
SET country = 'United States' 
WHERE country = 'United States.';


-- 4d. Convert date column from TEXT to proper DATE format

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2 
MODIFY COLUMN `date` DATE;


-- ============================================================
-- STEP 5 : HANDLE NULL VALUES
-- ============================================================

-- 5a. Check which rows have nulls in key columns

SELECT * FROM layoffs_staging2 
WHERE total_laid_off IS NULL 
  AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_staging2 
WHERE percentage_laid_off IS NULL;


-- 5b. Remove rows where both layoff columns are NULL
--     (these rows have no analytical value)

DELETE FROM layoffs_staging2 
WHERE total_laid_off IS NULL 
  AND percentage_laid_off IS NULL;


-- ============================================================
-- STEP 6 : DROP HELPER COLUMN
-- ============================================================

-- row_num was only needed to remove duplicates — drop it now

ALTER TABLE layoffs_staging2 
DROP COLUMN row_num;


-- ============================================================
-- FINAL : VERIFY CLEANED DATASET
-- ============================================================

SELECT * FROM layoffs_staging2;

-- ============================================================
-- CLEANING SUMMARY
-- ============================================================
-- ✔ Created staging table to preserve raw data
-- ✔ Identified and removed duplicate rows using ROW_NUMBER()
-- ✔ Trimmed whitespace from company names
-- ✔ Standardized inconsistent industry and country values
-- ✔ Converted date column from TEXT to DATE format
-- ✔ Removed rows with no layoff data (both columns NULL)
-- ✔ Dropped helper column after use
-- ============================================================
