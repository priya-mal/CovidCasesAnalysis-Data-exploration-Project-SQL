/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
Link to Dataset: https://ourworldindata.org/covid-deaths
Divided the above dataset into two files as Covid Deaths and Covid Vaccinations
*/

select  top 5 * from SQLDataExplorationProject.[dbo].[CovidDeaths];
select  top 5 * from SQLDataExplorationProject.[dbo].[CovidVaccinations];


----selecting the data we are using for Analysis
select Location, date, total_cases, new_cases, total_deaths, population 
from
SQLDataExplorationProject.[dbo].[CovidDeaths]
order by 1,2;


----Total cases vs Total Deaths
---Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage
from SQLDataExplorationProject.[dbo].[CovidDeaths]
where (total_deaths/total_cases)*100 IS NOT NULL
order by 4
--Observations : Albania recorded Highest death percentage i.e 8.3% in 2020 


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  
(total_cases/population)*100 as PercentPopulationInfected
From SQLDataExplorationProject.[dbo].[CovidDeaths]
--Where location like '%states%'
order by 5 desc



-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, 
Max((total_cases/population))*100 as PercentPopulationInfected
From SQLDataExplorationProject.[dbo].[CovidDeaths]
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--Observations : 68.47 % of Faeroe Islands population were infected with covid which is highest as on date :  25 Feb 2022


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From SQLDataExplorationProject.[dbo].[CovidDeaths]
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc
--Observations : United States recorded total death count of 948215 as on month : Feb 2022 

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From SQLDataExplorationProject.[dbo].[CovidDeaths]
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc
--Observations : North America continent has highest death count i.e. 948215


----GLOBAL NUMBERS----
select SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_cases)*100 as DeathPercentage
FROM SQLDataExplorationProject.[dbo].[CovidDeaths]
where continent is not null
order by 1,2 

/*Query Results: 
Total_cases - 432847624
Total_deaths - 5917680
DeathPercentage - 1.3671*/






-----------JOINING CovidDeaths & CovidVaccination tables-------------
select top 5 * from SQLDataExplorationProject.[dbo].[CovidDeaths]
select top 5 * from SQLDataExplorationProject.[dbo].[CovidVaccinations]

select * from SQLDataExplorationProject.[dbo].[CovidDeaths] d
join SQLDataExplorationProject.[dbo].[CovidVaccinations] v
on d.location = v.location
and d.date =v.date


------Total Population vs Vaccinations

select d.continent, d.location, d.date, d.population, v.new_vaccinations,
--SUM(CONVERT(int,v.new_vaccinations))  -- this gave an error as 'Arithmetic overflow error converting expression to data type int., hence used BIG INT as below'
SUM(CAST(v.new_vaccinations AS BIGINT))
OVER (Partition by d.location order by d.location, d.Date) 
as RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
from SQLDataExplorationProject.[dbo].[CovidDeaths] d
join SQLDataExplorationProject.[dbo].[CovidVaccinations] v
on d.location = v.location
and d.date = v.date
where d.continent IS NOT NULL
order by 2, 3 



---------Using CTE-------
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS BIGINT)) 
OVER (Partition by d.location order by d.location, d.Date) 
as RollingPeopleVaccinated
from SQLDataExplorationProject.[dbo].[CovidDeaths] d
join SQLDataExplorationProject.[dbo].[CovidVaccinations] v
on d.location = v.location
and d.date = v.date
where d.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
from PopvsVac


-----USING TEMP Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS BIGINT)) 
OVER (Partition by d.location order by d.location, d.Date) 
as RollingPeopleVaccinated
from SQLDataExplorationProject.[dbo].[CovidDeaths] d
join SQLDataExplorationProject.[dbo].[CovidVaccinations] v
on d.location = v.location
and d.date = v.date
where New_vaccinations IS NOT NULL
Select *, (RollingPeopleVaccinated/Population)*100 as Percentage_RollingPpl_Vacc
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations (i used this view to visualize the observations in Tableau)

DROP VIEW IF EXISTS PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS BIGINT)) 
OVER (Partition by d.location order by d.location, d.Date) 
as RollingPeopleVaccinated
from SQLDataExplorationProject.[dbo].[CovidDeaths] d
join SQLDataExplorationProject.[dbo].[CovidVaccinations] v
on d.location = v.location
and d.date = v.date
where d.continent is not null 
