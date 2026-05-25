
select * from layoffs;
create table layoff_staging select * from layoffs;
select * from layoff_staging;


#CHECKING  DUPLICATE ROWS


select * ,ROW_NUMBER() OVER (PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) 
as "row_num" from layoff_staging;

with duplicate_cte as (select * ,ROW_NUMBER() OVER (PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',
stage,country,funds_raised_millions) as "row_num" from layoff_staging)
select * from duplicate_cte where row_num>1;

select * from layoff_staging where company='casper';
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

insert into layoffs_staging2 select * ,ROW_NUMBER() OVER (PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) 
as "row_num" from layoff_staging;
select * from layoffs_staging2;
SET SQL_SAFE_UPDATES = 0;
delete from layoffs_staging2 where row_num>1;

select * from layoffs_staging2 where row_num>1;



# Standardizing data 

update layoffs_staging2 set company=TRIM(company) ;

select distinct(industry) from layoffs_staging2;

update layoffs_staging2 set industry ="Crypto" where industry like "Crypto%";

SELECT distinct(COUNTRY) FROM layoffs_staging2 ORDER BY 1;

UPDATE layoffs_staging2 set country = "United States" where country ="United States.";

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

alter table layoffs_staging2 modify column `date` DATE;

SELECT * FROM layoffs_staging2	;

# DELETING NULL VALUES


delete from layoffs_staging2 where total_laid_off is NULL and percentage_laid_off is NULL ;
select * from layoffs_staging2;
select * from layoffs_staging2 where percentage_laid_off is NULL;

#DELETING USELESS COLUMN

ALTER TABLE layoffs_staging2 drop column row_num;