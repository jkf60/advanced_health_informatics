-- Assignment 1: Abnormal Blood Glucose and Type 2 Diabetes Mellitus Screening --
-- CTE 'subject_pop' to hold initial subject population and exclude all subjects with pregnancy within the pat year --
WITH subject_pop AS (
	-- age is calculated by subtracting birthdate and deathdate or birthdate and current date if subject is living -- 
	SELECT CASE WHEN patient.deathdate IS NULL
	THEN DATE_PART('year', age(CURRENT_DATE, birthdate)) 
	ELSE DATE_PART('year', age(patient.deathdate, birthdate)) END ages, 
	patient.id, patient.race, patient.ethnicity, bmi.value bvalue, bmi.date bdate,
	-- bmi records are ranked descending to by date to select the most recent value for each subject -- 
	RANK() OVER(PARTITION BY patient.id ORDER BY bmi.date desc) AS R
	FROM public.patient
	-- inner joining bmi table on patient table matching on patient id --
	INNER JOIN public.bmi on patient.id = bmi.patient
	AND EXISTS ( SELECT 1 FROM conditions c 
				WHERE patient.id = c.patient
				-- only selecting patients who have a record of diabetes or prediabetes --
				AND (c.description LIKE '%Diabetes' OR c.description LIKE '%Prediabetes')
	) AND NOT EXISTS (
		-- removing all subject who meet exclusion criteria from cohort --
		SELECT 1 FROM conditions C
		WHERE patient.id = c.patient
		-- if a subject has record of pregnancy within the past year or current, they are not included in the cohort --
		AND (c.description like '%pregnancy%')
		AND (DATE_PART('year', age(CURRENT_DATE, c.stop)) <= 1 
			 OR c.stop IS NULL 
			)
	)
), 
-- CTE to hold inclusion criteria --
inclusion_pop as (
	-- selecting distinct subjects from subject population created above --
	SELECT distinct subject_pop.id, race, ages 
	FROM subject_pop
	WHERE (
		-- Patient is >=40 years old AND <=70 years old AND BMI >=25kg/m2 --
		(ages BETWEEN 40 AND 70)
		AND CAST(subject_pop.bvalue AS DECIMAL) >=25
	)
	OR (
		-- Patient is >=18 years old and <40 years old AND BMI >=25kg/m2 MOST RECENT VALUE --
		R = 1
		AND (ages >= 18 AND ages < 40)
		AND CAST(subject_pop.bvalue AS DECIMAL) >= 25
		AND UPPER(ethnicity) = 'hispanic'
		-- the query lines below can be commented/uncommented to meet one of more of the following: OR race = black or native OR ethnicity = Hispanic -- 
		--AND (UPPER(race) IN ('black', 'native') OR UPPER(ethnicity) = 'hispanic')
		--AND UPPER(race) = 'black' OR UPPER(race) = 'native'
		-- the subject population meeting inclusion criterion stays 20062 subjects with each line commented/uncommented --
	)
	OR (
		-- Patient is >=18 years old and <=70 years old AND BMI >=23kg/m2  MOST RECENT VALUE AND race = asian --
		R = 1
		AND (ages BETWEEN 18 AND 70)
		AND cast(subject_pop.bvalue AS DECIMAL) >=23
		AND UPPER(race) IN ('asian')
	)
)
SELECT COUNT(distinct inclusion_pop.id)
FROM inclusion_pop
-- 1. How many patients meet the inclusion criteria?
-- 20062 subjects meet the inclusion criteria (excluding patients meeting exclusion criteria 1)

-- For the next set of questions, I commented/uncommented each SELECT query and ran with the subject_pop and inclusion_pop CTEs --
-- 2. what is the percentage of patients with HbA1c > 7%?
-- calculating the percentage of subjects with a recorded HbA1c > 7 over the entire subject population --
SELECT COUNT(*)*100.0/(SELECT COUNT(*) FROM inclusion_pop)
	FROM inclusion_pop
	INNER JOIN a1c on inclusion_pop.id = a1c.patient 
	WHERE CAST(a1c.value AS DECIMAL) > 7
-- 2.1% of subjects have an HbA1c value > 7.

-- 3. Group by age (18-30; 30 – 40; 40-50 and above 60)
-- assigning subjects to age groups based on grouping criteria 
SELECT SUM(CASE WHEN ages >= 18 AND ages <=30 THEN 1 ELSE 0 END) AS 
"18 to 30", 
	SUM(CASE WHEN ages >= 30 AND ages <= 40 THEN 1 ELSE 0 END) AS "30 to 40",
	SUM(CASE WHEN ages >= 51 AND ages <= 60 THEN 1 ELSE 0 END) AS "40 to 50", 
	SUM(CASE WHEN ages > 60 THEN 1 ELSE 0 END) AS "above 60"
	FROM inclusion_pop
-- Ages 18-30: 0 subjects, Ages 30 – 40: 335 subjects, 40-50: 8103 subjects, and above 60: 8168 subjects)

-- 4. Group by race
-- grouping patients by race 
SELECT COUNT(distinct inclusion_pop.id), race 
	FROM inclusion_pop
	GROUP BY race 
-- Number of asian subjects: 1551
-- Number of black subjects: 1850
-- Number of native subjects: 92
-- Number of white subjects: 16551
-- Number of other subjects: 18