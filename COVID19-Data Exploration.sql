SELECT *
FROM PortfolioProject.CODeaths
order by 3,4;

SELECT *
FROM PortfolioProject.COVaccinations
order by 3,4;

-- Select data  we are going to use
Select Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.CODeaths
order by 1,2;

-- Total Deaths vs total Cases
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.CODeaths
Where location like '%Romania%'
order by 1,2;

-- Total Cases vs Population
Select Location, date, total_cases, Population, (total_cases/Population)*100 AS CasesPercentage
FROM PortfolioProject.CODeaths
Where Location LIKE '%Romania%'
order by 1,2;

-- Highest Infection rate vs Population
Select Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS 
PercentPopulationInfected
FROM PortfolioProject.CODeaths
Group by Location, Population
order by PercentPopulationInfected desc;

-- Countries with HighestDeath Count per Population
Select Location, MAX(CAST(NULLIF(Total_deaths, '') AS UNSIGNED)) AS TotalDeathCount
FROM PortfolioProject.CODeaths
Where Continent IS NOT NULL AND Continent <> ''
Group by Location
order by TotalDeathCount desc;

-- Breaking by Continent
-- Continents  with the highest death count per population
Select Continent, MAX(CAST(NULLIF(Total_deaths, '') AS UNSIGNED)) AS TotalDeathCount
FROM PortfolioProject.CODeaths
Where Continent IS NOT NULL AND Continent <> ''
Group by Continent
order by TotalDeathCount desc;

-- GLOBAL NUMBERS
SELECT 
    date, 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(NULLIF(new_deaths, '') AS UNSIGNED)) AS total_deaths, 
    (SUM(CAST(NULLIF(new_deaths, '') AS UNSIGNED)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM PortfolioProject.CODeaths
WHERE Continent IS NOT NULL AND Continent <> ''
GROUP BY date
ORDER BY 1,2;

-- Total Population vs Vaccinations
    SELECT 
        CASE 
            WHEN dea.Location IN ('Africa', 'Asia', 'Europe', 'North America', 'South America', 'Oceania', 'World') 
            THEN NULL 
            ELSE dea.Continent 
        END AS Continent,
        dea.Location, 
        dea.Date, 
        dea.Population, 
        NULLIF(vac.new_vaccinations, 0) AS new_vaccinations,
        NULLIF(SUM(CAST(vac.new_vaccinations AS UNSIGNED)) 
               OVER (PARTITION BY dea.Location ORDER BY dea.Date), 0) 
               AS RollingPeopleVaccinated
    FROM PortfolioProject.CODeaths dea
    JOIN PortfolioProject.COVaccinations vac
        ON dea.Location = vac.Location
        AND dea.Date = vac.Date
ORDER BY Location, Date;


-- USE CTE
WITH POPvsVAC 
AS (
    SELECT 
        CASE 
            WHEN dea.Location IN ('Africa', 'Asia', 'Europe', 'North America', 'South America', 'Oceania', 'World') 
            THEN NULL 
            ELSE dea.Continent 
        END AS Continent,
        dea.Location, 
        dea.Date, 
        dea.Population, 
        NULLIF(vac.new_vaccinations, 0) AS new_vaccinations,
        NULLIF(SUM(CAST(vac.new_vaccinations AS UNSIGNED)) 
               OVER (PARTITION BY dea.Location ORDER BY dea.Date), 0) 
               AS RollingPeopleVaccinated
    FROM PortfolioProject.CODeaths dea
    JOIN PortfolioProject.COVaccinations vac
        ON dea.Location = vac.Location
        AND dea.Date = vac.Date
) 
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM POPvsVAC
ORDER BY Location, Date;

-- Create a Temporary Table
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
( 
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population BIGINT,
    New_vaccinations BIGINT,
    RollingPeopleVaccinated BIGINT
);
-- Insert Data
INSERT INTO PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT 
    CASE 
        WHEN dea.Location IN ('Africa', 'Asia', 'Europe', 'North America', 'South America', 'Oceania', 'World', 'International') 
        THEN NULL 
        ELSE dea.Continent 
    END AS Continent,
    dea.Location, 
    dea.date,
    case when dea.Population = ''
    	then NULL
    	else dea.Population
    end as Population,
    NULLIF(vac.new_vaccinations, 0) AS new_vaccinations,
    COALESCE(SUM(vac.new_vaccinations) 
       OVER (PARTITION BY dea.Location ORDER BY dea.date), 0) 
       AS RollingPeopleVaccinated
FROM PortfolioProject.CODeaths dea
LEFT JOIN PortfolioProject.COVaccinations vac
    ON dea.Location = vac.Location
    AND dea.date = vac.date
ORDER BY 1,2;


-- Select Data with Population Percentage
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;

-- Creating View to store the data for later visual
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    CASE 
        WHEN dea.Location IN ('Africa', 'Asia', 'Europe', 'North America', 'South America', 'Oceania', 'World', 'International') 
        THEN NULL 
        ELSE dea.Continent 
    END AS Continent,
    dea.Location, 
    dea.date,
    dea.Population,
    COALESCE(vac.new_vaccinations, 0) AS new_vaccinations,
    COALESCE(
    SUM(COALESCE(vac.new_vaccinations, 0))
       OVER (PARTITION BY dea.Location ORDER BY dea.date), 0) 
       AS RollingPeopleVaccinated
FROM PortfolioProject.CODeaths dea
JOIN PortfolioProject.COVaccinations vac
    ON dea.Location = vac.Location
    AND dea.date = vac.date
WHERE dea.Continent IS NOT NULL AND dea.Continent <> '';

SELECT *
FROM PercentPopulationVaccinated;



