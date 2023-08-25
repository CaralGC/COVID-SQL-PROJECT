
Select *
From PortfolioProject..CovidDeaths
Where 
     continent  is not null --this line is to clean out the continents in the location, it should be paste in every query to avoid issues, or cleaning data previously
     AND continent <> '' -- and this line too
Order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--Order by 3,4

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where 
     continent  is not null
	 AND continent <> ''
Order by 1

-- Looking at Total Cases vs Total Deaths and Death Percentage in Canada and Mexico
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    (CASE WHEN TRY_CONVERT(float, total_cases) > 0 THEN TRY_CONVERT(float, total_deaths) * 100.0 / TRY_CONVERT(float, total_cases) ELSE 0 END) AS DeathPercentage
From 
    PortfolioProject..CovidDeaths
Where 
    location = 'Canada' OR location = 'Mexico'
Order by 1


-- Percentage of population that got COVID 
-- Total Cases vs Population 
SELECT
    location,
    date,
	population,
    total_cases,
    CASE 
	   WHEN TRY_CONVERT(float, total_cases) > 0 
	   THEN TRY_CONVERT(float, total_cases) * 100.0 / TRY_CONVERT(float, population) 
	   ELSE 0 END 
	   AS PercentPopulationInfected
From 
    PortfolioProject..CovidDeaths
Where 
    location = 'Canada' OR location = 'Mexico'
Order by 1



-- Countries with Highest Infection Rate compared to Population
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
    PortfolioProject..CovidDeaths
Where 
    continent  is not null
	AND continent <> ''
GROUP BY
    location, population
ORDER BY
    PercentPopulationInfected DESC


-- Countries with the Highest Death Count per Population
SELECT
    location,
	MAX(
	    CASE 
	    WHEN TRY_CONVERT(float, total_deaths) > 0 
	    THEN CAST(total_deaths AS int)
	    ELSE 0 
		END) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
Where 
    continent  is not null
	AND continent <> ''
GROUP BY
    location
ORDER BY
    TotalDeathCount DESC



-- Continents with highest death count
SELECT
    location,
    MAX(
        CASE 
        WHEN TRY_CONVERT(float, total_deaths) > 0 
        THEN CAST(total_deaths AS int)
        ELSE 0 
        END) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NULL OR continent = ''
GROUP BY
    location
ORDER BY
    TotalDeathCount DESC



	--Global numbers
SELECT
    date,
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
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
    AND continent <> ''
GROUP BY
    date
ORDER BY 
    Total_Cases


	-- Total world numbers
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
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
    AND continent <> ''
ORDER BY 
    Total_Cases 



	--CovidVaccination and CovidDeaths tables joined
	--Total Population vs Total Vaccinations

	-- We can do it by two ways: using CTE and using temporary tables.
	-- 1 Use of CTE (Common Table Expression)
	-- CTE is a temporary result set that you can reference within the context of a single SQL statement. It's a way to create a named temporary result set that you can 
	-- use to simplify complex queries, break down a query into smaller, more manageable parts, and improve the readability of your SQL code.
	-- CTEs can make complex queries more readable and maintainable by breaking down the logic into smaller pieces. They are often used for recursive queries, 
	-- data transformation, and in situations where you need to reference the same intermediate result multiple times in the same query.
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
		SELECT 
			dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			vac.new_vaccinations,
			SUM(CONVERT(int,vac.new_vaccinations)) 
			OVER (PARTITION BY 
							dea.location
				  ORDER BY
						  dea.location,
						  dea.date) AS RollingPeopleVaccinated
		FROM
			PortfolioProject..CovidDeaths AS dea
		Join PortfolioProject..CovidVaccinations AS vac
			ON dea.date = vac.date
			AND dea.location = vac.location
		WHERE 
			dea.continent IS NOT NULL
			AND dea.continent <> ''
		)

SELECT *, 
	 CASE
            WHEN TRY_CONVERT(float, RollingPeopleVaccinated) > 0 AND TRY_CONVERT(float, Population) > 0
            THEN TRY_CONVERT(float, RollingPeopleVaccinated) * 100.0 / TRY_CONVERT(float, Population)
            ELSE 0
     END
FROM
    PopvsVac


	-- 2 Use of Temporary Table 
	-- A temporary table is a database object that stores a subset of data from a larger table for the duration of a session or a transaction. Temporary tables are useful 
	-- for holding temporary data that you need to manipulate or reference within a specific scope, without affecting the original data in the main tables.
	-- Temporary tables can be particularly useful in scenarios where you need to perform multiple complex operations on a set of data or when you need to break down a 
	-- larger task into smaller steps.
--IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    --DROP TABLE #PercentPopulationVaccinated

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated 
    (
    Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_Vaccinations numeric,
	RollingPeopleVaccinated numeric
	)

INSERT INTO #PercentPopulationVaccinated (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
SELECT 
			dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			vac.new_vaccinations,
			SUM(TRY_CONVERT(int,vac.new_vaccinations)) 
			OVER (PARTITION BY 
							dea.location
				  ORDER BY
						  dea.location,
						  dea.date) AS RollingPeopleVaccinated
		FROM
			PortfolioProject..CovidDeaths AS dea
		Join PortfolioProject..CovidVaccinations AS vac
			ON dea.date = vac.date
			AND dea.location = vac.location
		WHERE 
			dea.continent IS NOT NULL
			AND dea.continent <> ''

SELECT *, 
	 CASE
            WHEN TRY_CONVERT(float, RollingPeopleVaccinated) > 0 AND TRY_CONVERT(float, Population) > 0
            THEN TRY_CONVERT(float, RollingPeopleVaccinated) * 100.0 / TRY_CONVERT(float, Population)
            ELSE 0
     END
FROM
    #PercentPopulationVaccinated



-- View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
			dea.continent, 
			dea.location, 
			dea.date, 
			dea.population, 
			vac.new_vaccinations,
			SUM(TRY_CONVERT(int,vac.new_vaccinations)) 
			OVER (PARTITION BY 
							dea.location
				  ORDER BY
						  dea.location,
						  dea.date) AS RollingPeopleVaccinated
		FROM
			PortfolioProject..CovidDeaths AS dea
		Join PortfolioProject..CovidVaccinations AS vac
			ON dea.date = vac.date
			AND dea.location = vac.location
		WHERE 
			dea.continent IS NOT NULL
			AND dea.continent <> ''

SELECT *
FROM PercentPopulationVaccinated