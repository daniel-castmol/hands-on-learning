-- ####################################################
-- ## CUMULATIVE TABLE FOR ACTORS
-- ## BUILDS YEAR BY YEAR
-- ####################################################

INSERT INTO actors
WITH yesterday AS (
    SELECT * FROM actors WHERE current_year = 2020
),
    today AS (
        SELECT
            actorid,
            actor,
            year,
            ARRAY_AGG(
                ROW(
                    film,
                    votes,
                    rating,
                    filmid
                    )::film_stats
            ORDER BY year) AS films,
            CASE
                WHEN AVG(rating) > 8 THEN 'star'
                WHEN AVG(rating) <= 8 AND AVG(rating) > 7 THEN 'good'
                WHEN AVG(rating) <= 7 AND AVG(rating) > 6 THEN 'average'
                ELSE 'bad'
            END::quality_class AS quality_class
        FROM actor_films
        WHERE year = 2021
        GROUP BY actorid, actor, year
    )
SELECT
    COALESCE(t.actorid,y.actorid) AS actorid,
    COALESCE(t.actor,y.actor) AS actor,
    CASE
        WHEN y.films IS NULL
            THEN t.films
        WHEN t.year IS NOT NULL
            THEN y.films || t.films
        ELSE y.films
    END AS films,
    COALESCE(t.quality_class,y.quality_class) AS quality_class,
    CASE
        WHEN t.year IS NOT NULL THEN 0
        ELSE y.years_since_last_active + 1
    END AS years_since_last_active,
    t.year IS NOT NULL AS is_active,
    COALESCE(t.year,y.current_year + 1) AS current_year
FROM today AS t
FULL OUTER JOIN yesterday AS y
ON t.actorid = y.actorid;