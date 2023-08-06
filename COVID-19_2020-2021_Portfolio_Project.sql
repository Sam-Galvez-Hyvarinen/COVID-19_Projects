SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
Order by 3,4


--SELECT *
--FROM PortfolioProject..CovidVaccinations
--Order by 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
Order by 1,2

-- Looking at total cases VS total deaths
-- ie: What is the % of people who died that were diegnosed with Covid-19
--Shows the chances of someone dying of you were to contract covid in a specified country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
Order by 1,2

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' and continent is not null
Order by 1,2

-- Total Cases VS POP
-- Shows % of POP got C19
-- Shows 10% of the pop got covid (2021-04-30)...YIKES
SELECT Location, date, population, total_cases, total_deaths, (total_cases/population)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
Order by 1,2

-- This juat beings us back to the total countries. you can use the "Comment" button
-- to take out lines you dont want to show.

SELECT Location, date, population, total_cases, total_deaths, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
Order by 1,2


--What Countries have the highest infection rates compared to POP
-- Shows Which countries did not/ cound not keep their infection rates under control (sadly)

SELECT Location,  population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY Location,  population
Order by PercentPopulationInfected DESC

--Countries with the highest death count per POP
--NOTE after looking @ totalDeath data. issue with data type.
---need to cast it as an int so it is read as a numeric
----After casting Total deaths as an Int, we now get a more accurate result

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount 
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY Location,  population
Order by TotalDeathCount  DESC

--ISSUE! in "location" column, we have "World" "Africa" etc. This is the 
--grouping of entire continents. We want out data to be by country.
-- And we have NULLs in the continent column. 
-- Adding "WHERE continent is not null" to every script to keep it uniform. 


-- By Continent w/ highest death count per pop
-- below is the correct way to look at data by continent. 
--Will need for visualizations later in Tableau

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount 
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is null
GROUP BY location
Order by TotalDeathCount  DESC

------------------------------------------------

--Cal everything accross the globe
--Not including location or continent. 
--This will show us the DAILY total cases/deaths globally 

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int)) / SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

---VIEW FOR DAILY TOTAL CASES/DEATHS GLOBALLY--------------

CREATE VIEW DailyTotal_cases_deaths_Global AS
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int)) / SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
--ORDER BY 1,2

--------------------------------------------------------------
--Total cases globally

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int)) / SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

---------------------------------------------------------------------------
--Joining CovidDeaths and CovidVaccinations on Location and Data

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date;

-- TOTAL POP VS VAC

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2;

-- adding partition for location
--breaking it up by location and date
--WHY? We want the count to start over when it gets to a diff location.
-- If we dont, the aggregation will mess up our data.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3  ;

--^^ This will add the new_vaccinations. when there is 0 or NULL, it will not add more to 
-- the total, and the total will simply repeat.


--USE CTE
--Everything from the prev query is in here, buit now we can use this for 
--more calculations. 
-- the % will go up b/c the pop stays stagnant

WITH POPvsVAC (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date)
AS RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3 
)

SELECT *, (RollingVaccinations/population) *100 AS VaccPercent
From POPvsVAC;


--------------------------------------------------------

-- Temp Table (Same effect)\
-- Creating a table showing the into listed 

DROP Table if exists #PercentPOPVacc     --Keep this (makes it easy to maintain query)
Create Table #PercentPOPVacc
(
Continent nvarchar(255),
Location nvarchar(255),
Date Datetime,
Population numeric, 
New_vaccinations Numeric,
RollingVaccinations Numeric
)

INSERT INTO #PercentPOPVacc
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date)
AS RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null;
--ORDER BY 2,3 

SELECT *, (RollingVaccinations/population) *100 AS pop_Vacc
From #PercentPOPVacc;


-- Create View + store data for DataViz

CREATE VIEW PercentPOPVacc AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date)
AS RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3 


SELECT *
FROM PercentPOPVacc

-----------------------------------------------------------------
-- Top 10 countries with the highest death tolls. 
--SSMS does not use LIMIT! see bottom to limit the amount
--- of rows in the results

SELECT continent, location, population,
	MAX(cast(total_deaths as int)) AS max_total_deaths,
	MAX(cast(total_cases as int)) AS max_total_cases
FROM CovidDeaths 
WHERE continent is not null
GROUP BY continent, location, population
ORDER BY max_total_deaths DESC
OFFSET 0 rows
fetch next 10 rows only;

----VIEW OF MAX TOTAL DEATHS-------

CREATE VIEW Hightst_deaths_By_location AS
SELECT location, population,
	MAX(cast(total_deaths as int)) AS max_total_deaths,
	MAX(cast(total_cases as int)) AS max_total_cases
FROM CovidDeaths 
WHERE continent is not null
GROUP BY location, population
ORDER BY max_total_deaths DESC
OFFSET 0 rows
fetch next 10 rows only;

--------------------------------------------------------------------



