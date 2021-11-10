# SQL_Project

V tomto projektu se snažím určit faktory, které ovlivňují rychlost šíření koronaviru na úrovni jednotlivých států.

Výsledná data budou panelová, klíče budou stát (country) a den (date). Každý sloupec v tabulce bude představovat jednu proměnnou. Úkolem je získat následující sloupce:

Časové proměnné
- binární proměnná pro víkend / pracovní den (day_of_the_week)
- roční období daného dne (zakódujte prosím jako 0 až 3) (code_of_season)

Proměnné specifické pro daný stát:

- hustota zalidnění - ve státech s vyšší hustotou zalidnění se nákaza může šířit rychleji (population_density)
- HDP na obyvatele - použijeme jako indikátor ekonomické vyspělosti státu (GDPR_per_capita)
- GINI koeficient - má majetková nerovnost vliv na šíření koronaviru? (gini_coeff)
- dětská úmrtnost - použijeme jako indikátor kvality zdravotnictví (mortality)
- medián věku obyvatel v roce 2018 - státy se starším obyvatelstvem mohou být postiženy více (median_age_2018)
- podíly jednotlivých náboženství - použijeme jako proxy proměnnou pro kulturní specifika. Pro každé náboženství v daném 
  státě - procentní podíl jeho příslušníků na celkovém obyvatelstvu
- rozdíl mezi očekávanou dobou dožití v roce 1965 a v roce 2015 - státy, ve kterých proběhl rychlý rozvoj mohou reagovat jinak 
   než země, které jsou vyspělé už delší dobu (life_exp_diff)

Počasí (ovlivňuje chování lidí a také schopnost šíření viru):

- průměrná denní (mezi 6-18 hod.) teplota (daily_avg_temp)
- počet hodin v daném dni, kdy byly srážky nenulové (rain_hours)
- maximální síla větru v nárazech během dne (daily_wind_force)

Data jsou čerpána z tabulek: countries, economies, life_expectancy, religions, covid19_basic_differences, covid19_tests, weather, lookup_table, viz. složka SQL-project/Data/
