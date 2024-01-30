WITH inclusion_patients AS
(
SELECT distinct patient.id, patient.race --, MAX(bmi.date)
	FROM public.patient
	LEFT JOIN public.bmi on patient.id = bmi.patient
	WHERE DATE_PART('year', age(patient.deathdate, patient.birthdate)) >= 40 
	AND DATE_PART('year', age(patient.deathdate, patient.birthdate)) <= 70
	OR DATE_PART('year', age(patient.deathdate, patient.birthdate)) >= 18 
	AND DATE_PART('year', age(patient.deathdate, patient.birthdate)) < 40
	AND CAST(bmi.value AS NUMERIC) >= 25 
	AND (patient.race = 'black' OR patient.ethnicity = 'hispanic' OR (DATE_PART('year', age(patient.deathdate, patient.birthdate)) >=18 AND DATE_PART('year', age(patient.deathdate, patient.birthdate)) <= 70 AND CAST(bmi.value AS NUMERIC) >=23 AND patient.race = 'asian') )
)
, exclusion_patients as
(
 SELECT COUNT(distinct patient.id)
 	FROM patient
 	LEFT JOIN public.conditions on patient.id = conditions.patient
 	WHERE conditions.description LIKE '%pregnancy%' AND DATE_PART('year', conditions.stop) >= '2022'  
)
, high_a1c as (
SELECT inclusion_patients.id
	FROM inclusion_patients
	LEFT JOIN public.a1c on inclusion_patients.id = a1c.patient
	WHERE CAST(a1c.value as NUMERIC) > 7
)
-- , age_groups as (
-- SELECT inclusion_patients.id,
-- 	DATE_PART('year', age(patient.deathdate, patient.birthdate)) as age 
-- 	FROM inclusion_patients, patient
-- 	GROUP BY patient.age 
-- 	(CASE 
--             WHEN age >= 18 AND age < 30 THEN '18-30'
--             WHEN age >= 30 AND age < 40 THEN '30-40'
-- 	 		WHEN age >= 40 AND age <= 50 THEN '40-50'
-- 	 		WHEN age >= 60 THEN 'Above 60'
--             ELSE 'UNK'
--       END)
	
-- )
-- , race_groups as (
-- 	SELECT *
-- 	FROM inclusion_patients
-- 	GROUP BY inclusion_patients.race 
-- )
SELECT COUNT(distinct inclusion_patients) as inclusion, COUNT(distinct exclusion_patients) as exclusion, COUNT(distinct high_a1c) as high_a1c--, COUNT(exclusion_patients) as exclusion
FROM inclusion_patients, high_a1c, exclusion_patients;