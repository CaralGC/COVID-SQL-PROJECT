-- Queries for Tableau visualizations

--1 Total world numbers
SELECT
    SUM(CASE WHEN TRY_CAST(new_cases AS int) IS NOT NULL THEN TRY_CAST(new_cases AS int) ELSE 0 END) AS Total_Cases,
    SUM(CASE WHEN TRY_CAST(new_deaths AS int) IS NOT NULL THEN TRY_CAST(new_deaths AS int) ELSE 0 END) AS Total_Deaths,
    CASE 
        WHEN SUM(CASE WHEN TRY_CAST(new_deaths AS int) IS NOT NULL THEN TRY_CAST(new_deaths AS int) ELSE 0 END) > 0
            AND SUM(CASE WHEN TRY_CAST(new_cases AS int) IS NOT NULL THEN TRY_CAST(new_cases AS int) ELSE 0 END) > 0
        THEN SUM(CASE WHEN TRY_CAST(new_deaths AS int) IS NOT NULL THEN TRY_CAST(new_deaths AS int) ELSE 0 END) * 100.0 /
             SUM(CASE WHEN TRY_CAST(new_cases AS int) IS NOT NULL THEN TRY_CAST(new_cases AS int) ELSE 0 END)
        ELSE 0 
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths_actual
WHERE 
    continent IS NOT NULL
    AND continent <> ''
ORDER BY 
    1,2


-- 2 Continents with highest death count
SELECT
    location,
    MAX(
        CASE 
        WHEN TRY_CONVERT(float, total_deaths) > 0 
        THEN CAST(total_deaths AS int)
        ELSE 0 
        END) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths_actual
WHERE 
    continent IS NULL OR continent = ''
	AND location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY
    location
ORDER BY
    TotalDeathCount DESC



-- 3 Countries with Highest Infection Rate compared to Population
SELECT
    location,
    population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX(
        CASE
            WHEN TRY_CONVERT(float, total_cases) > 0 AND TRY_CONVERT(float, population) > 0
            THEN TRY_CONVERT(float, total_cases) * 100.0 / TRY_CONVERT(float, population)
            ELSE 0
        END
    ) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths_actual
Where 
    continent  is not null
	AND continent <> ''
GROUP BY
    location, population
ORDER BY
    PercentPopulationInfected DESC


-- 4 Countries with Highest Infection Rate compared to Population
SELECT
    location,
    population,
	date,
    MAX(total_cases) AS HighestInfectionCount,
    MAX(
        CASE
            WHEN TRY_CONVERT(float, total_cases) > 0 AND TRY_CONVERT(float, population) > 0
            THEN TRY_CONVERT(float, total_cases) * 100.0 / TRY_CONVERT(float, population)
            ELSE 0
        END
    ) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths_actual
WHERE
    Location = 'World'
GROUP BY
    location, population, date
ORDER BY
    PercentPopulationInfected DESC


-- 5 Total population vaccinated and total deaths in the world
WITH PopvsVac (Continent, Location, Date, Population, People_Vaccinated, Total_Deaths) AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.people_vaccinated,
		dea.total_deaths
		--dea.new_deaths,
  --      SUM(CONVERT(bigint, dea.new_deaths)) 
  --          OVER (PARTITION BY dea.location
  --                ORDER BY dea.location, dea.date) AS CountingDeaths
    FROM
        PortfolioProject..CovidDeaths_actual AS dea
    JOIN PortfolioProject..CovidVaccination_actual AS vac
        ON dea.date = vac.date
        AND dea.location = vac.location
    --WHERE 
    --    dea.continent IS NOT NULL
    --    AND dea.continent <> ''
)

SELECT *,
     CASE
        WHEN TRY_CONVERT(float, People_Vaccinated) > 0 AND TRY_CONVERT(float, Population) > 0
        THEN TRY_CONVERT(float, People_Vaccinated) * 100.0 / TRY_CONVERT(float, Population)
        ELSE 0
     END AS PeopleVaccinatedPercent,
     CASE
        WHEN TRY_CONVERT(float, Total_Deaths) > 0 AND TRY_CONVERT(float, Population) > 0
        THEN TRY_CONVERT(float, Total_Deaths) * 100.0 / TRY_CONVERT(float, Population)
        ELSE 0
     END AS DeathPercent
FROM
    PopvsVac
WHERE
    Location = 'World'
ORDER BY 
    Date



-- 5.1 new deaths in the world
SELECT 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
	vac.people_vaccinated,
	dea.new_deaths
FROM
    PortfolioProject..CovidDeaths_actual AS dea
    JOIN PortfolioProject..CovidVaccination_actual AS vac
        ON dea.date = vac.date
        AND dea.location = vac.location
WHERE
    dea.location = 'World'
ORDER BY 
    Date
