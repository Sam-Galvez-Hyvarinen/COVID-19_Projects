# Covid Case Study: Capstone Project 

### [Tableau](https://public.tableau.com/app/profile/samantha.galvez/viz/Covid-19DashboardUpdated1/Dashboard1?publish=yes)

## Description: 

This project is for the Google Analytics Capstone Project. I wanted to showcase what I’ve learned throughout the program by using real-world data that everyone could relate to and gain insights from. 
For this project, I decided to go with data collected over 16 months during the pandemic, from 2020 to the spring of 2021. This data is collected from hundreds of countries around the world. It also dives into covid infection rates, vaccination totals per country, and covid death percentages (based on the country's population). As well as projections for future infection rates for some of these countries. This dataset is for a fictional travel company whose goal is to provide safe travel for those who are immunocompromised or Covid conscious. 


## Task:

This data is collected from 221 countries. The objective is to clean and organize the dataset to showcase the most dangerous countries to travel to for people who are covid conscious or are immunocompromised based on infection and death rates. Essentially, we are going for a “Where not to go” approach. The travel agency wants to know the countries that are the most dangerous to travel to based on covid infections and covid deaths in relation to the country's population. By illustrating these metrics, the team will be able to comprise a list of the safest locations for immunocompromised people to travel to, and create travel packages centered around those countries' cultures and experiences. 

## Environments Used:

- SQL (SSMS) 
- Excel
- Tableau

## Data Cleaning and Manipulation

The Dataset was downloaded into a CSV and manipulated in Excel before uploading into SQL (SSMS) where it was further cleaned and analyzed using the following scripts. I dissected the dataset into two separate Excels for Covid Deaths and Vaccinations. I found this to be the easiest way to manipulate the data while in SQL (SSMS).

Pulling the Covid Deaths Table. 
```
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
Order by 3,4
```

During cleaning, I found that ('World', 'European Union', and 'International') were in the "location" column. the below query made sure these were taken out of our results. 

```
SELECT continent, SUM(cast(new_deaths as int)) as TotalDeathCt
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
AND continent not in ('World', 'European Union', 'International')
GROUP BY continent
ORDER BY TotalDeathCt DESC
```

## Analysis

Looking at total cases VS total deaths, as in 
"what is the % of people who died that were diagnosed with Covid-19"? 

```
SELECT Location, date, total_cases, total_deaths,
(total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
Order by 1,2
```

Total Covid cases, deaths, and death percentages Globally

```
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	SUM(cast(new_deaths as int)) / SUM(new_cases) * 100
	AS DeathPercent
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2
```
Joining the CovidDeaths Table and the CovidVaccinations on location and date

```
SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date;
```

This shows us the total population per country VS the new vaccination rate

```
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2;
```

Adding partition for location. this breaks up our code by location and date
WHY WOULD WE NEED THIS? We want the count to start over when it gets to a diff location. If we don't, the aggregation will mess up our data. (Trust me)
This will add the new_vaccination. when there is 0 or NULL value, it will not add more to the total. The total will simply repeat. 

```
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date)
AS RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
```

Here we extracted the highest infection count and ordered the query by the percent of the population that was infected.

```
SELECT Location, Population, MAX(total_cases) as HighestInfectionCt,
	MAX((total_cases/population)) * 100 as PercentPOPInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPOPInfected desc
```
This shows us the highest infection count and ordered the query by the percent of the population that was infected but at a daily rate. 

```
SELECT location, Population, date, 
	MAX(total_cases) as HighestInfectionCt,
	MAX((total_cases / population)) * 100 as PercentPOPInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPOPInfected DESC
```
Our Top 10 Worst countries to travel to for the immunocompromised. This is by max deaths. It also shows the total cases per country and their population. 

```
SELECT location, population,
	MAX(cast(total_deaths as int)) AS max_total_deaths,
	MAX(cast(total_cases as int)) AS max_total_cases
FROM CovidDeaths 
WHERE continent is not null
GROUP BY location, population
ORDER BY max_total_deaths DESC
OFFSET 0 rows
fetch next 10 rows only;
```

## Visualizations and Dashboards: 

I used Tableau for my visualizations. 


![image](https://github.com/Sam-Galvez-Hyvarinen/COVID-19_Projects/assets/129132100/10843ef7-fe9b-4870-bb9a-4b2242503494)


![image](https://github.com/Sam-Galvez-Hyvarinen/COVID-19_Projects/assets/129132100/829340c2-458a-4b82-830a-b11259087327)

The percent of the population infected, with future forecasting
![image](https://github.com/Sam-Galvez-Hyvarinen/COVID-19_Projects/assets/129132100/c818ebb3-a6b1-48ab-95a1-9526e45f32da)

![image](https://github.com/Sam-Galvez-Hyvarinen/COVID-19_Projects/assets/129132100/1053cceb-9bc1-4821-9d22-037651f5deb6)

To view the interactive Dashboard in its entirety, please see Tableau link at the top.

## Conclusion and Reccomendations 

Regarding future business opportunities, the client can use the data presented to offer travel packages to countries with lower covid infection rates. Taking into account that the countries in the “Top 10 Countries to Avoid for Travel” are actually some of the most popular travel destinations. 
#### Possible effects: 
Increasing the tourist traffic to countries with lower covid infections has the possibility to increase tourist traffic to countries with lower travel numbers, benefitting the country's economy. This may also be used to promote a positive advertisement campaign by increasing relations between the countries and the travel company.

#### Travel Peak Times: 
As this company is driven to provide travel to those who are immunocompromised and/or covid conscious, it may be wise to also take into account WHEN the consumers should travel. By providing travel during off seasons, the dangers of infection will decrease. An accumulation of aviation data and data from competing travel agencies pinpointing when these off-seasons occur would be beneficial. 

## Data Sources
The data I used was taken from the [Our World In Data](https://ourworldindata.org/covid-deaths) website. 
 
