USE census ;

SELECT * FROM dataset1 ;

SELECT * FROM dataset2 ;

-- Count no of rows in both tables

SELECT COUNT(*) FROM dataset1 ;
SELECT COUNT(*) FROM dataset2 ;

-- Extract all information for states 'Jharkhand' and 'Bihar'

SELECT dataset1.District,
	   dataset1.State,
       Growth,
       Sex_Ratio,
       Literacy,
       Area_km2,
       Population
FROM 
dataset1
INNER JOIN
dataset2
ON dataset1.District = dataset2.District 
WHERE dataset1.State IN ('Jharkhand','Bihar') ;  

-- What is the total population of India in billiions (rounded to 2 decimal places)? 

SELECT CONCAT(
			 ROUND(SUM(Population)/1000000000,2),
             ' billion'
             ) Total_Population
FROM dataset2 ;             

-- What was the average growth rate for India?

SELECT CONCAT( 
             ROUND(AVG(Growth)*100),
             '%'
             ) Average_Growth
FROM dataset1 ;

-- Determine average sex_ratio and litercy rate for India.

SELECT CONCAT( 
             ROUND(AVG(Literacy),2),
             '%'
             ) Literacy_Rate ,
             ROUND(AVG(Sex_Ratio)) Average_Sex_Ratio
FROM dataset1 ;

-- What was the growth for every state (output the result in descending order)?

SELECT State,
       CONCAT( 
             ROUND(AVG(Growth)*100,2),
             ' %'
             ) Average_Growth
FROM dataset1 
GROUP BY State
ORDER BY AVG(Growth) DESC ;

-- What was the literacy rate for every state (output the result in descending order)?

SELECT State,
CONCAT(
	   ROUND(AVG(Literacy)) , ' %'
	  ) Literacy_Rate 
FROM dataset1 
GROUP BY State
ORDER BY Literacy_Rate DESC ;

-- What were the states having literacy rate > 90%?

SELECT State,
CONCAT(
	   ROUND(AVG(Literacy)) , ' %'
	  ) Literacy_Rate 
FROM dataset1 
GROUP BY State
HAVING AVG(Literacy) > 90
ORDER BY Literacy_Rate DESC ;

-- What was the sex ratio for every state (output the result in descending order)?

SELECT State,
      ROUND(AVG(Sex_Ratio)) Average_Sex_Ratio
FROM dataset1 
GROUP BY State
ORDER BY Average_Sex_Ratio DESC;

-- What are the three states having highest growth %?

SELECT State,
       CONCAT( 
             ROUND(AVG(Growth)*100,2),
             ' %'
             ) Average_Growth
FROM dataset1 
GROUP BY State
ORDER BY AVG(Growth) DESC
LIMIT 3;

-- What are the three states showing lowest sex_ratio?

SELECT State,
       ROUND(AVG(Sex_Ratio)) Average_Sex_Ratio
FROM dataset1 
GROUP BY State
ORDER BY Average_Sex_Ratio
LIMIT 3;

-- What were the bottom 3 and top 3 states in accordance with literacy rate?

WITH CTE AS
(
SELECT DISTINCT State ,
       AVG(Literacy) OVER (PARTITION BY State) Average_Literacy
FROM dataset1
)
(SELECT State ,
        CONCAT
        (
        ROUND(Average_Literacy), ' %'
        ) Literacy_Rate
FROM CTE 
ORDER BY Literacy_Rate DESC
LIMIT 3)
UNION
(SELECT State ,
		CONCAT
        (
        ROUND(Average_Literacy),' %'
        ) Literacy_Rate
FROM CTE 
ORDER BY Literacy_Rate
LIMIT 3) ;

-- Output all states with 3 'A' in their names

SELECT DISTINCT State
FROM
dataset1
WHERE state LIKE '%a%a%a%' ;

-- Find total no of males and females present in each state

SELECT State ,
       SUM(Males) Total_Males,
       SUM(Females) Total_Females
FROM
(SELECT District,
       State,
       ROUND(Population/(Sex_Ratio_+1)) Males ,
       ROUND(Population - (Population/(Sex_Ratio_+1))) Females
FROM 
(SELECT dataset1.District,
	    dataset1.State,
	    Sex_Ratio/1000 Sex_Ratio_,
        Population
FROM 
dataset1
INNER JOIN
dataset2
ON dataset1.District = dataset2.District) Temp
) Temp2 
GROUP BY State;        
       
-- Find total literates and illiterates in each state

SELECT State ,
       SUM(Literates) Total_Literates,
       SUM(Illiterates) Total_Illiterates
FROM
(SELECT District,
        State,
        ROUND(Population*Literacy_Ratio) Literates ,
        ROUND(Population - (Population*Literacy_Ratio)) Illiterates
FROM 
(SELECT dataset1.District,
	   dataset1.State,
       Literacy/100 Literacy_Ratio,
       Population
FROM 
dataset1
INNER JOIN
dataset2
ON dataset1.District = dataset2.District) Temp
) Temp2 
GROUP BY State; 

-- What was the population in previous census?

SELECT CONCAT(
             ROUND(
                   SUM(Total_Previous_Census_Population)/1000000000,2
                   ) , ' Billion'
             ) Previous_Census_Population,
       CONCAT(
			 ROUND(
				  SUM(Total_Current_Census_Population)/1000000000,2
                  ) , ' Billion'
             ) Current_Census_Population
FROM
(SELECT State ,
       SUM(Previous_Census_Population) Total_Previous_Census_Population,
       SUM(Current_Census_Population) Total_Current_Census_Population
FROM
(SELECT District,
        State,
        ROUND(Population/(1+Growth)) Previous_Census_Population,
        ROUND(Population) Current_Census_Population
FROM 
(SELECT dataset1.District,
	   dataset1.State,
       Growth,
       Population
FROM 
dataset1
INNER JOIN
dataset2
ON dataset1.District = dataset2.District) Temp
) Temp2 
GROUP BY State) Temp3; 

-- What is the area per person in this census VS previous census ?

SELECT ROUND(
			SUM(State_area)/SUM(Total_Previous_Census_Population),4
            ) Area_VS_Previous_Census_Population,
       ROUND(
            SUM(State_area)/SUM(Total_Current_Census_Population),4
            ) Area_VS_Current_Census_Population
FROM
(SELECT State ,
       SUM(Previous_Census_Population) Total_Previous_Census_Population,
       SUM(Current_Census_Population) Total_Current_Census_Population,
       SUM(Area_km2) State_area
FROM
(SELECT District,
        State,
        Population/(1+Growth) Previous_Census_Population,
        Population Current_Census_Population,
        Area_km2
FROM 
(SELECT dataset1.District,
	   dataset1.State,
       Area_km2,
       Growth,
       Population
FROM 
dataset1
INNER JOIN
dataset2
ON dataset1.District = dataset2.District) Temp
) Temp2 
GROUP BY State) Temp3 ;

-- Find the bottom 3 districts from each state having lowest literacy ratio?

SELECT State,
       District,
       Literacy
FROM
(
SELECT State,
       District,
       Literacy,
       DENSE_RANK() OVER (PARTITION BY State ORDER BY Literacy) Ranking
FROM dataset1  
) Temp    
WHERE Ranking IN (1,2,3) ;
