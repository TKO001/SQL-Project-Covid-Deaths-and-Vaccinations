Select *
From PortfolioProjects..[CovidDeaths (1)]
order by 3, 4

Select *
From PortfolioProjects..CovidVaccinations
order by 3, 4

SELECT *
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE continent is not null
order by 3,4

--selecting the columns we will be working with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE continent is not null
order by 1,2

--comparing total cases vs total deaths per country

Select location, date, total_cases,  total_deaths, (total_deaths /total_cases) 
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE location  LIKE '%STATES%'
Order by 1,2

--comparing total cases vs population
Select location, date, total_cases,  total_deaths, population, ((total_cases / population)*100) as infectionrate
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE location  LIKE '%STATES%'
Order by 1,2

--country with highest new cases
Select location, continent, MAX( total_cases) as HighestCasecount, population
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE continent IS NOT NULL
GROUP By population, location, continent
Order by continent ASC, HighestCasecount DESC

--country with highest Death cases
Select location, continent, MAX( total_deaths) as HighestDeathcount, population
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE continent IS NOT NULL AND total_deaths IS NOT NULL
GROUP By location, continent, population
Order by continent ASC, HighestDeathcount DESC;

--death rate
SELECT location, date, population, total_cases, total_deaths,
       CASE 
	   WHEN total_deaths > 0 THEN (total_deaths / total_cases)*100 ELSE NULL 
	   END AS death_rate
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE location LIKE '%STATES%' and total_deaths IS NOT NULL
ORDER BY 1, 2;

--Now onto analyzing death count per continent
SELECT continent, max(total_deaths) as totaldeaths
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE continent IS NOT NULL and total_deaths IS NOT NULL
Group by continent
order by totaldeaths desc

SELECT location, max(total_deaths) as totaldeaths
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE continent IS NOT NULL and total_deaths IS NOT NULL
Group by location
order by totaldeaths desc

--Global NEW numbers
Select  continent, SUM(new_cases) as globalnewcases, SUM(new_deaths) as globalnewdeaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProjects..[CovidDeaths (1)]
where continent is not null 
Group by  continent
ORDER BY 1


--Join Function by Showing Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.total_cases, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProjects..[CovidDeaths (1)] dea
JOIN PortfolioProjects..CovidVaccinations vac
on dea.location = vac.location
	and dea.date = vac.date
where vac.new_vaccinations is not null and dea.continent is not null
order by 2,3

--partitioning by location as data rolls out
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT (INT, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

From PortfolioProjects..[CovidDeaths (1)] dea
Join PortfolioProjects..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null
order by 2,3

--using CTE on partition by query to find % of population that is vaccinated
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT (INT, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
	
	From PortfolioProjects..[CovidDeaths (1)] dea
	Join PortfolioProjects..CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null and vac.new_vaccinations is not null
)
select *
from PopvsVac

--using temp tables to perform Calculation on Partition By
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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT (INT, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
	
	From PortfolioProjects..[CovidDeaths (1)] dea
	Join PortfolioProjects..CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null and vac.new_vaccinations is not null
SELECT *, (RollingPeopleVaccinated/Population)*100 AS percentage
FROM #PercentPopulationVaccinated

--creating views to be used for visualization
create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT (INT, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
	
	From PortfolioProjects..[CovidDeaths (1)] dea
	Join PortfolioProjects..CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
	where dea.continent is not null and vac.new_vaccinations is not null

create view deathcount as
SELECT continent, max(total_deaths) as totaldeaths
FROM PortfolioProjects..[CovidDeaths (1)]
WHERE continent IS NOT NULL and total_deaths IS NOT NULL
Group by continent
--order by totaldeaths desc

drop view deatchcount