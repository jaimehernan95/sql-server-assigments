--Query 1
;WITh CTE ([Login])
AS
(
select DISTINCT [Login] from [dbo].[Security_Logins_Log] where [Logon_Date] <'20170101'
	except
select DISTINCT [Login] from [dbo].[Security_Logins_Log] where  [Logon_Date] >= '20170101' 
)
SELECT SL.Full_Name from [dbo].[Security_Logins] AS SL
WHERE Id IN (select Login from CTE)
ORDER BY SL.Login;

------------------------------------------------------------------------------------------------------------------------------
----QUERY 2
;WITH CTE_JOBS(JOBS,COMPANY)
AS
(select COUNT([Job]) JOBS, COMPANY
FROM
[dbo].[Applicant_Job_Applications] JA
LEFT OUTER JOIN [dbo].[Company_Jobs] CJ
ON JA.Job =CJ.ID
GROUP BY COMPANY
HAVING COUNT(JOB)>=10 
)
SELECT COMPANY_NAME,LanguageID  FROM [dbo].[Company_Descriptions] CD,
CTE_JOBS C
WHERE C.COMPANY =CD.Company 
AND JOBS>=10
AND LanguageID='EN'
---------------------------------------------------------------------------------------------------------------------------------------
------QUERY3
SELECT TOP 1 WITH TIES Security.Full_Name AS "Full Name", 
                       Profile.Current_Salary AS "Current Salary", 
                       Profile.Currency AS "Currency"
FROM Applicant_Profiles AS Profile
     INNER JOIN Security_Logins AS Security ON Profile.Login = Security.Id
ORDER BY DENSE_RANK() OVER(PARTITION BY Profile.Currency
         ORDER BY Profile.Current_Salary DESC);
------------------------------------------------------------------------------------------------------------------------------------------
-----Query4

SELECT Company_Descriptions.Company_Name AS "Company Name", 
       COUNT(Company_Jobs_Descriptions.Job) AS "#JobsPosted"
FROM Company_Jobs
     FULL OUTER JOIN Company_Jobs_Descriptions ON Company_Jobs_Descriptions.Job = Company_Jobs.Id
     FULL OUTER JOIN Company_Descriptions ON Company_Jobs.Company = Company_Descriptions.Company
WHERE Company_Descriptions.LanguageID = 'EN'
GROUP BY Company_Descriptions.Company_Name

-----------------------------------------------------------------------------------------------------------------------------------------
----Query 5
;WITH CTE_QUERY(CompanyName,jobs)
     AS (SELECT Company_Descriptions.Company_Name AS "Company Name", 
                COALESCE(COUNT(Company_Jobs_Descriptions.Job), 0) AS "#Jobs Posted"
         FROM Company_Jobs
              FULL OUTER JOIN Company_Jobs_Descriptions ON Company_Jobs_Descriptions.Job = Company_Jobs.Id
              FULL OUTER JOIN Company_Descriptions ON Company_Jobs.Company = Company_Descriptions.Company
         WHERE Company_Descriptions.LanguageID = 'EN'
         GROUP BY Company_Descriptions.Company_Name)
     SELECT 'Client without Posted Jobs:', 
            SUM(CASE
                    WHEN CTE_QUERY .jobs = 0
                    THEN 1
                END)
     FROM CTE_QUERY
     UNION
     SELECT 'Client with Posted Jobs:', 
            SUM(CASE
                    WHEN CTE_QUERY.JOBS >= 1
                    THEN 1
                END)
     FROM CTE_QUERY;