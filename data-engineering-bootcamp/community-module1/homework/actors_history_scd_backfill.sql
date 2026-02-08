-- ####################################################
-- ## BACKFILL QUERY FOR ACTORS HISTORY SCD
-- ## TRACKS QUALITY CLASS AND IS ACTIVE STATUS FOR EACH ACTOR
-- ####################################################

INSERT INTO actors_history_scd
WITH previous AS (
SELECT
    actorid,
    actor,
    current_year,
    quality_class,
    is_active,
    CASE
        WHEN LAG(quality_class) OVER (PARTITION BY actorid ORDER BY current_year) IS DISTINCT FROM quality_class THEN 1
        WHEN LAG(is_active) OVER (PARTITION BY actorid ORDER BY current_year) IS DISTINCT FROM is_active THEN 1
        ELSE 0
    END AS did_change
FROM actors
WHERE current_year <= 2020
),
with_indicator AS (
    SELECT
        actorid,
        actor,
        current_year,
        quality_class,
        is_active,
        SUM(CASE WHEN did_change = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY actorid ORDER BY current_year) AS indicator
    FROM previous
),
    aggregated AS (
        SELECT
            actorid,
            actor,
            quality_class,
            is_active,
            indicator,
            MIN(current_year) AS start_date,
            MAX(current_year) AS end_date,
            2020 AS current_year
        FROM with_indicator
        GROUP BY actorid,actor,quality_class,is_active,indicator
    )
SELECT * FROM aggregated;