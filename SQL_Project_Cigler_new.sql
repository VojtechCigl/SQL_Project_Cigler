# USE TABLES countries, economies, life_expectancy, religions, covid19_basic_differences, covid19_testing, weather, lookup_table
# VIEWS IN PROJECT:

#1. v_covid_variables 
#2. v_economies_population
#3. v_life_expectancy 
#4. v_religion
#5. v_weather_calculation

# Main project view t_vojtech_cigler_projekt_SQL_final contains all variables from previoues views

# Auxiliary tables and views:

#    v_total_population - calculation of total population for every country 2020
#    v_weather_converting - for converting weather variables

# view v_economies_population. Creating variables code_of_season,population_density,median_age_2018
# Using day_of_the_week and MONTH function. Èasové promìnné binární promìnná pro víkend / pracovní den roèní období daného dne (zakódovat jako 0 až 3)


# OPTIONS FOR replace Czechia by Czech republic
#Copy source table covid19_basic_differences to auxiliar table (replace Czechia by Czech republic)
#CREATE TABLE aux_covid19_basic_differences LIKE covid19_basic_differences;
#INSERT INTO aux_covid19_basic_differences SELECT * FROM covid19_basic_differences;
#Another option for value Czech republic- update covid19_detail_global_differences set country='Czech republic' where country in ('Czechia');

#create or replace table aux_covid19_basic_differences as
#select replace(country,'Czechia','Czech republic') as 'country',confirmed,deaths,recovered; 

#Modify column country from MEDIUM TEXT to TEXT - 
#alter table aux_covid19_basic_differences 
#MODIFY country TEXT;

#VIEW v_covid_variables
#Covid variables - confirmed,test_performed,test_positivity_rate,tests_per_capita


CREATE OR REPLACE VIEW v_covid_variables AS
 SELECT cbd.`date`,
        cbd.country,
        cbd.confirmed,
        ct.tests_performed,
        ROUND((cbd.confirmed/ct.tests_performed)*100,2) AS 'test_positivity_rate',
        ROUND((ct.tests_performed/c.population)*100,2) AS 'tests_per_capita',       
         CASE WHEN DAYOFWEEK(cbd.`date`) IN ('1','7') THEN 0 ELSE 1
              END AS day_of_the_week,
         CASE WHEN (MONTH (cbd.`date`) IN ('3') AND CONVERT(DAYOFMONTH(cbd.date),INT) >= 20) OR (MONTH(cbd.`date`) IN ('4','5'))  OR (MONTH (cbd.`date`) IN ('6') AND CONVERT(DAYOFMONTH(cbd.date),INT) <= 20) THEN 0
              WHEN (MONTH (cbd.`date`) IN ('6') AND CONVERT(DAYOFMONTH(cbd.date),INT) >= 21) OR (MONTH (cbd.`date`)IN ('7','8'))  OR (MONTH (cbd.`date`) IN ('9') AND CONVERT(DAYOFMONTH(cbd.date),INT) <= 21) THEN 1
              WHEN (MONTH (cbd.`date`) IN ('9') AND CONVERT(DAYOFMONTH(cbd.date),INT) >= 22) OR (MONTH(cbd.`date`) IN ('10','11'))OR (MONTH (cbd.`date`) IN ('12')AND CONVERT(DAYOFMONTH(cbd.date),INT) <= 20) THEN 2
              WHEN (MONTH (cbd.`date`) IN ('12')AND CONVERT(DAYOFMONTH(cbd.date),INT) >= 21) OR (MONTH(cbd.`date`) IN ('1','2'))  OR (MONTH (cbd.`date`) IN ('3') AND CONVERT(DAYOFMONTH(cbd.date),INT) <= 19) THEN 3 
              END AS season_code           
 FROM covid19_basic_differences cbd
 JOIN covid19_tests ct 
      ON  ct.country = cbd.country
      AND ct.`date`  = cbd.`date`
 JOIN countries c 
      ON cbd.country = c.country
 WHERE
         ct.tests_performed  IS NOT NULL
     AND cbd.confirmed       IS NOT NULL
 GROUP BY cbd.`date`,cbd.country 
 ORDER BY cbd.`date` DESC,cbd.country ASC;



#View v_economies_and_population

CREATE OR REPLACE VIEW v_economies_and_population AS
 SELECT cnt.*,v1.GDPR_per_capita,v2.gini_coeff,v3.mortality_under5
 FROM
     (SELECT c.country,c.capital_city,c.population,c.population_density,median_age_2018 FROM countries c) cnt
  LEFT JOIN
     (SELECT e.country, MAX(`YEAR`),
             ROUND(e.GDP/e.population, 2) AS 'GDPR_per_capita'
      FROM  economies e 
      WHERE e.GDP IS NOT NULL AND population>0
      GROUP BY country) v1
    ON  cnt.country = v1.country
  LEFT JOIN 
     (SELECT e.country,MAX(`YEAR`),
             e.gini AS 'gini_coeff'
      FROM   economies e
      WHERE  e.gini IS NOT NULL
      GROUP BY country) v2
   ON cnt.country = v2.country
  LEFT JOIN
     (SELECT e.country,MAX(`YEAR`),
	         e.mortaliy_under5 AS 'mortality_under5'
      FROM economies e
      WHERE e.mortaliy_under5 IS NOT NULL
      GROUP BY country)v3
   ON cnt.country = v3.country;

# Vypoèet podílu jednotlivých náboženství - použijeme jako proxy promìnnou pro kulturní specifika.
# Pro každé náboženství v daném státì bych chtìl procentní podíl jeho pøíslušníkù na celkovém obyvatelstvu.
#Pomocí Select Distinct zjistím kolik celkem náboženství se vyskytuje ve sloupci religion a pro každé náboženství vytvoøím sloupec, který bude výsledkem porovnání s celkovou populací dané zemì.
#Pro každou zemi zjištuji, zda je poèet obyvatel hlásící se k danému náboženství vyplnìn, pokud ne, tak dosadím hodnotu 0. Tou se ale nesmí dìlit.


# VIEW v_total_population
CREATE OR REPLACE VIEW v_total_population AS
 SELECT r.country , r.year,SUM(r.population) AS total_population_2020
        FROM religions r 
        WHERE r.year = 2020
        GROUP BY r.country;

CREATE OR REPLACE VIEW v_religion AS
 SELECT r1.country, r1.population, 
       ROUND(r1.Christianity/tp.total_population_2020*100, 2)    AS 'Christianity', 
       ROUND(r1.Islam/tp.total_population_2020*100, 2)           AS 'Islam', 
       ROUND(r1.Unaffiliated_religions/tp.total_population_2020*100, 2) AS 'Unaffiliated_religions',
       ROUND(r1.Hinduism/tp.total_population_2020*100, 2)        AS 'Hinduism',
       ROUND(r1.Buddhism/tp.total_population_2020*100, 2)        AS 'Buddhism',
       ROUND(r1.Folk_religions/tp.total_population_2020*100, 2)  AS 'Folk_religions',
       ROUND(r1.Other_religions/tp.total_population_2020*100, 2) AS 'Other_religions',
       ROUND(r1.Judaism/tp.total_population_2020*100, 2)         AS 'Judaism'
 FROM
  (SELECT country, SUM(population) AS 'population', 
          SUM(CASE WHEN religion = 'Christianity' THEN population ELSE 0 END) AS 'Christianity',
          SUM(CASE WHEN religion = 'Islam' THEN population ELSE 0 END) AS 'Islam',
          SUM(CASE WHEN religion = 'Unaffiliated Religions' THEN population ELSE 0 END) AS 'Unaffiliated_religions', 
          SUM(CASE WHEN religion = 'Hinduism' THEN population ELSE 0 END) AS 'Hinduism', 
          SUM(CASE WHEN religion = 'Buddhism' THEN population ELSE 0 END) AS 'Buddhism', 
          SUM(CASE WHEN religion = 'Folk Religions' THEN population ELSE 0 END) AS 'Folk_religions',
          SUM(CASE WHEN religion = 'Other Religions' THEN population ELSE 0 END) AS 'Other_religions',
          SUM(CASE WHEN religion = 'Judaism' THEN population ELSE 0 END) AS 'Judaism'
   FROM religions r WHERE year = 2020 AND population > 0 GROUP BY country) r1
 JOIN v_total_population tp
   ON r1.country = tp.country
GROUP BY r1.country;



#Calculation of life_expectancy. VARIABLE life_exp_ratio - rozdíl mezi oèekávanou dobou dožití v roce 1965 a v roce 2015

CREATE OR REPLACE VIEW v_life_expectancy AS
  SELECT a.country, a.life_exp_1965 , b.life_exp_2015,
         ROUND( b.life_exp_2015 / a.life_exp_1965, 2 ) AS life_exp_ratio
  FROM (
    SELECT le.country , le.life_expectancy AS life_exp_1965
    FROM life_expectancy le 
    WHERE year = 1965
    ) a JOIN (
    SELECT le.country , le.life_expectancy AS life_exp_2015
    FROM life_expectancy le 
    WHERE year = 2015
    ) b
          ON a.country = b.country;
    
CREATE OR REPLACE VIEW v_weather_converting AS
 SELECT DATE(w.`date`) as 'date',w.`time`,w.city,c.country,
        CONVERT(REPLACE(w.temp,' °c',''),INT) AS 'daily_avg_temp',
        CONVERT(REPLACE(w.rain,' mm',''),DECIMAL) AS 'rainy_hours',
        CONVERT(REPLACE(w.gust,' km/h',''),INT) AS 'max_wind_gust'
  FROM countries c
  JOIN weather w
        ON c.capital_city = w.city
  WHERE
       w.city IS NOT NULL
  ORDER BY w.`date` DESC,w.city ASC;


CREATE OR REPLACE VIEW v_weather_calculation AS
 SELECT v1.*,
        CASE WHEN v2.rainy_hours IS NULL THEN 0 ELSE v2.rainy_hours END AS rainy_hours,
        v3.max_wind_gust
 FROM
          (SELECT `date`,city,country,AVG(daily_avg_temp) AS 'daily_avg_temp'  
           FROM v_weather_converting vwc2 
           WHERE `time` IN ('06:00','09:00','12:00','15:00','18:00') 
           GROUP BY `date`,city,country
           ORDER BY `date` DESC,city ASC) v1
 LEFT JOIN
          (SELECT DISTINCT `date`,city,country,Count(rainy_hours) AS 'rainy_hours' FROM v_weather_converting vwc2
           WHERE rainy_hours>0
           GROUP BY `date`,city,country) v2
     #having COUNT(rainy_hours)>0 ORDER BY `date` DESC,city ASC
           ON v1.country = v2.country
           AND v1.`date`= v2.`date`
 LEFT JOIN
           (SELECT `date`,city,country,MAX(max_wind_gust) as 'max_wind_gust'  
            FROM v_weather_converting vwc2
            GROUP BY `date`,city,country
            ORDER BY `date` DESC,city ASC) v3
            ON  v1.country = v3.country
           AND  v1.`date`= v3.`date`;
      
      
 #FINAL VIEW from all previous views - v_vojtech_cigler_projekt_SQL

CREATE OR REPLACE TABLE t_vojtech_cigler_projekt_SQL_final AS
 SELECT covid_var.*,
        countries.capital_city,countries.population,countries.population_density,countries.median_age_2018,countries.GDPR_per_capita,countries.gini_coeff,countries.mortality_under5,
        life_expect.life_exp_ratio,
        religion.Christianity,religion.Islam,religion.Unaffiliated_religions,
        weather.daily_avg_temp,weather.rainy_hours,weather.max_wind_gust
 FROM
          (SELECT * FROM v_covid_variables) covid_var
 JOIN 
          (SELECT * FROM v_economies_and_population) countries
           ON  covid_var.country = countries.country
 LEFT JOIN
          (SELECT * FROM v_life_expectancy) life_expect
           ON  covid_var.country = life_expect.country
 LEFT JOIN
          (SELECT * FROM v_religion) religion
           ON  covid_var.country = religion.country 
     JOIN
         (SELECT * FROM v_weather_calculation vwc) weather
          ON   covid_var.country = weather.country
         AND   covid_var.`date` =  weather.`date`
GROUP BY covid_var.`date`,covid_var.country
ORDER BY covid_var.`date` DESC,covid_var.country ASC; 
 
   
#Other selects:
  
  #select distinct country
  #from covid19_tests ct
  
  #select distinct country
  #from covid19_basic_differences cbd

#select distinct country
#from covid19_tests ct 

#select distinct country
#from countries c
  
  
#missing countries- zemì, které nejsou uvedeny buï žádné tabulce nebo jen v covid19_basic_differences

  #select distinct country
  #from covid19_basic_differences cbd 
  #EXCEPT
  #select distinct country
  #from covid19_tests ct;

  #select *
  #from covid19_tests ct
  #where country in ('Albania')
  
  
  
  
   
#   select *
# from covid19_basic_differences cbd 
# where country in ('Czechia')
  
  
 #select distinct religion 
#from religions r;
  
  #ve finální tabulce je zastoupeno pouze 16 zemí, protože potøebujeme data jak pro poèty nakažených, tak pro poèet testù. V opaèném pøípadì je pozorování zkreslené.
  #select distinct country
  #from t_vojtech_cigler_projekt_sql_final tvcpsf;
  
