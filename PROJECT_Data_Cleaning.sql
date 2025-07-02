-- PROJECT: Data Cleaning

SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. NULL Values or Blank Values
-- 4. Remove Any Columns

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging; -- copy of the raw data


-- 1. Remove Duplicates

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicat_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicat_cte
WHERE row_num > 1 ;

-- right click on layoffs_staging --> Copy to clipboard --> Create statement :
CREATE TABLE `layoffs_staging2` (
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

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;



-- 2. Standardizing the Data

SELECT DISTINCT(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company); -- erases the white spaces before the names of the companies


SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- there are references to the same inustry (crypto) with different names like 'Crypto Industries'
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; 

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


SELECT DISTINCT(location)
FROM layoffs_staging2
ORDER BY 1;
-- everything looks fine

SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1;

-- there is a final dot written in some of the references to United Satates
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'; 

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country); -- we remove dots and white spaces in the beggining

-- change Text format of the column 'date' to a Date format:
UPDATE layoffs_staging2
SET `date`= str_to_date(`date`, '%m/%d/%Y'); 

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. NULL Values or Blank Values

-- Change every Blank on industry into a NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL;


SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1 
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;
-- there are companies with missing inudstry associated in somw rows

-- we update the missing industries:
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- 4. Remove Any Columns

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- erase all the rows with laid off information NULL
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- eliminate the auxiliar column we created at the beggining
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- FINAL CLEANED DATA:
SELECT *
FROM layoffs_staging2;


