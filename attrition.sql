select * from general_data;
 with attritionrate as (
 select Department, sum(case when Attrition='Yes' then 1 else 0 end ) as attritioncount,
 count(*) as totalemployees
 from general_data
 group by Department 
 )
 select Department , attritioncount,totalemployees,
 round(cast(attritioncount as float )/totalemployees*100,2) as attritionrate from attritionrate ;
 
 Create View tenureattrition as
 select 
 case 
 when YearsAtCompany<=5 then '0-5'
when YearsAtCompany<=10 then '5-10'
when YearsAtCompany<=15 then '10-15'
when YearsAtCompany<=20 then '15-20'
when YearsAtCompany<=25 then '20-25'
when YearsAtCompany<=30 then '25-30'
when YearsAtCompany<= 35 then '30-35'
else '35-40'
end as servicetenure, count(*) as totalemployee ,
  sum(case when attrition='yes' then 1 else 0 end ) as attritioncount,
  ROUND(CAST(SUM(CASE WHEN attrition='yes' THEN 1 ELSE 0 END) AS FLOAT)/COUNT(*)*100,2) AS attritionrate
  from general_data 
  group by servicetenure
  select * from tenureattrition ;
 

  create view salary_band_attrition as 
  select Department,
  case 
  when MonthlyIncome<=15000 then 'very low'
   when MonthlyIncome<=35000 then 'low(15k-35k)'
    when MonthlyIncome<=60000 then 'Mid (35k-60k)'
     when MonthlyIncome<=95000 then 'high(60k-100k)'
     else 'very high (>100k)' end as salary_band,
     count(*) as total_employees, sum(case when Attrition='Yes' then 1 else 0 end) as total_attrited,
     round(avg(case when attrition='Yes' then 1 else 0 end )*100,2) as attrition_rate 
     from general_data
     group by department, 
     case
	when MonthlyIncome<=15000 then 'very low'
    when MonthlyIncome<=35000 then 'low(15k-35k)'
    when MonthlyIncome<=60000 then 'Mid (35k-60k)'
     when MonthlyIncome<=95000 then 'high(60k-100k)'
     else 'very high (>100k)' 
     end;
     select * from salary_band_attrition;
   
WITH travel_salary AS (
  SELECT
    BusinessTravel,
    CASE
      WHEN MonthlyIncome <= 15000 THEN 'Very Low (< 15k)'
      WHEN MonthlyIncome <= 35000 THEN 'Low (15k-35k)'
      WHEN MonthlyIncome <= 60000 THEN 'Mid (35k-60k)'
      WHEN MonthlyIncome <= 95000 THEN 'High (60k-100k)'
      ELSE 'Very High (> 100k)'
    END                                                         AS salary_band,
    CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0 END            AS attrited
  FROM general_data
)
SELECT
  BusinessTravel,
  salary_band,
  COUNT(*)                                                      AS total_employees,
  SUM(attrited)                                                 AS total_attrited,
  ROUND(AVG(attrited) * 100, 2)                                AS attrition_rate,
  CASE
    WHEN AVG(attrited) * 100 > 40
     AND BusinessTravel = 'Travel_Frequently'                  THEN 'HIGH RISK'
    WHEN AVG(attrited) * 100 > 40                              THEN 'ALERT'
    ELSE 'OK'
  END                                                          AS risk_flag
FROM travel_salary
GROUP BY
  BusinessTravel,
  salary_band
ORDER BY
  attrition_rate DESC; 

CREATE VIEW travel_salary_attrition AS
SELECT
  ts.BusinessTravel,
  ts.salary_band,
  COUNT(*) AS total_employees,
  SUM(ts.attrited) AS total_attrited,
  ROUND(AVG(ts.attrited) * 100, 2) AS attrition_rate,
  c.avg_rate AS company_avg,
  CASE
    WHEN ROUND(AVG(ts.attrited) * 100, 2) > c.avg_rate 
         AND ts.BusinessTravel = 'Travel_Frequently' THEN 'HIGH RISK'
    WHEN ROUND(AVG(ts.attrited) * 100, 2) > c.avg_rate THEN 'ABOVE AVG'
    ELSE 'OK'
  END AS risk_flag
FROM (
  SELECT
    BusinessTravel,
    CASE
      WHEN MonthlyIncome <= 15000 THEN 'Very Low (< 15k)'
      WHEN MonthlyIncome <= 35000 THEN 'Low (15k-35k)'
      WHEN MonthlyIncome <= 60000 THEN 'Mid (35k-60k)'
      WHEN MonthlyIncome <= 95000 THEN 'High (60k-100k)'
      ELSE 'Very High (> 100k)'
    END AS salary_band,
    CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0 END AS attrited
  FROM general_data
) ts
CROSS JOIN (
  SELECT ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS avg_rate
  FROM general_data
) c
GROUP BY ts.BusinessTravel, ts.salary_band, c.avg_rate;

 
 
CREATE VIEW attrition_cost_per_dept AS
SELECT
  Department,
  COUNT(*)  AS total_employees,
  SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)AS total_attrited,
  ROUND(
    AVG(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS attrition_rate,
  ROUND(AVG(MonthlyIncome), 2) AS avg_monthly_income,
  ROUND(
    SUM(CASE WHEN Attrition = 'Yes' THEN MonthlyIncome ELSE 0 END) * 6
  , 2) AS total_attrition_cost
FROM general_data
GROUP BY Department
ORDER BY total_attrition_cost DESC;
select * from attrition_cost_per_dept;

CREATE VIEW employee_data.promotion_attrition AS
SELECT 
    CASE 
        WHEN YearsSinceLastPromotion = 0 THEN 'just promoted'
        WHEN YearsSinceLastPromotion <= 3 THEN '1-3 yrs'
        WHEN YearsSinceLastPromotion <= 6 THEN '3-6 yrs'
        WHEN YearsSinceLastPromotion <= 9 THEN '6-9 yrs'
        WHEN YearsSinceLastPromotion <= 12 THEN '9-12 yrs'
        ELSE '12+' 
    END AS promotion_band,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS total_attrited,
    ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS attrition_rate
FROM general_data
GROUP BY
    CASE 
        WHEN YearsSinceLastPromotion = 0 THEN 'just promoted'
        WHEN YearsSinceLastPromotion <= 3 THEN '1-3 yrs'
        WHEN YearsSinceLastPromotion <= 6 THEN '3-6 yrs'
        WHEN YearsSinceLastPromotion <= 9 THEN '6-9 yrs'
        WHEN YearsSinceLastPromotion <= 12 THEN '9-12 yrs'
        ELSE '12+' 
    END;
    
DROP TABLE employee_data.attendance;
CREATE TABLE employee_data.attendance (
    EmployeeID INT,
    date DATE,
    in_time DATETIME,
    out_time DATETIME,
    hours_worked DECIMAL(5,2)
);
LOAD DATA INFILE 'c:/ProgramData/MySQL/MySQL Server 8.0/Uploads/attendance.csv'
INTO TABLE employee_data.attendance 
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@EmployeeID, @date, @in_time, @out_time, @hours_worked)
SET 
EmployeeID = @EmployeeID,
date = STR_TO_DATE(@date, '%d-%m-%Y'),
in_time = STR_TO_DATE(@in_time, '%d-%m-%Y %H:%i'),
out_time = STR_TO_DATE(@out_time, '%d-%m-%Y %H:%i'),
hours_worked = @hours_worked;
SELECT COUNT(*) FROM employee_data.attendance;

CREATE VIEW attendance_attrition AS
SELECT
  a.EmployeeID,
  ROUND(AVG(a.hours_worked), 2) AS avg_hours_worked,
  CASE
    WHEN AVG(a.hours_worked) > 9  THEN 'Overworked'
    WHEN AVG(a.hours_worked) > 8  THEN 'Normal'
    ELSE 'Underworked'
  END  AS workload_category,
  g.Department,
  g.Attrition
FROM attendance a
JOIN general_data g ON a.EmployeeID = g.EmployeeID
GROUP BY
  a.EmployeeID,
  g.Department,
  g.Attrition
  
  
CREATE VIEW attendance_attrition_summary AS
SELECT
    g.Department,
    workload_category,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN g.Attrition = 'Yes' THEN 1 ELSE 0 END) AS total_attrited,
    ROUND(AVG(CASE WHEN g.Attrition = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS attrition_rate
FROM (
    SELECT
        a.EmployeeID,
        CASE
            WHEN AVG(a.hours_worked) > 9 THEN 'Overworked'
            WHEN AVG(a.hours_worked) > 8 THEN 'Normal'
            ELSE 'Underworked'
        END AS workload_category
    FROM attendance a
    GROUP BY a.EmployeeID
) emp
JOIN general_data g ON emp.EmployeeID = g.EmployeeID
GROUP BY g.Department, workload_category
ORDER BY attrition_rate DESC;

select count(*) from general_data;

  
  