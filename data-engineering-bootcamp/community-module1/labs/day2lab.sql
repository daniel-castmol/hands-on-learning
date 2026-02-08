-- #################################################
-- ## LAB 2: BUILDING SLOWLY CHANGING DIMENSIONS
-- ## PLAYERS SCD FROM PLAYERS
-- #################################################

-- ## PLAYERS SCD DDL

CREATE TABLE players_scd (
    player_name TEXT,
    scoring_class scoring_class,
    is_active BOOLEAN,
    start_season INTEGER,
    end_season INTEGER,
    current_season INTEGER,
    PRIMARY KEY(player_name, start_season, end_season)
);
-- drop table players_scd;

CREATE TYPE scd_type AS (
                    scoring_class scoring_class,
                    is_active boolean,
                    start_season INTEGER,
                    end_season INTEGER
                        );


-- ## COMPARING ATTRIBUTES BETWEEN SEASONS
-- ## AND BUILDING SCD TABLE

INSERT INTO players_scd
WITH previous AS (
SELECT
    player_name,
    scoring_class,
    is_active,
    current_season,
    LAG(scoring_class, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_scoring_class,
    LAG(is_active, 1) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_is_active
FROM players
WHERE current_season <= 2021
),
with_indicator AS (
SELECT
    *,
    SUM(CASE
        WHEN scoring_class <> previous_scoring_class THEN 1
        WHEN is_active <> previous_is_active THEN 1
        ELSE 0
    END) OVER (PARTITION BY player_name ORDER BY current_season) AS change_strike
FROM previous
)
SELECT
    player_name,
    scoring_class,
    is_active,
    MIN(current_season) AS start_season,
    MAX(current_season) AS end_season,
    2021 AS current_season
FROM with_indicator
GROUP BY player_name, scoring_class, is_active, change_strike;

-- ## INCREMENTAL QUERY
    -- FOR THE RECORDS THAT DON'T CHANGE WE WILL INCREASE 1 AND FOR THE RECORDS THAT DO CHANGE WE WILL ADD NEW RECORDS
    -- ASSUMPTIONS:
        -- SCORING CLASS AND IS ACTIVE ARE NEVER NULL... IF THEY ARE NULL IT WILL BREAK THE QUERY
    -- WE DEPEND ON HISTORICAL DATA TO BACKFILL

-- LAST SEASON DATA

INSERT INTO players_scd
WITH last_season_scd AS (
    SELECT
        player_name,
        scoring_class,
        is_active,
        start_season,
        end_season
    FROM players_scd
    WHERE current_season = 2021
    AND end_season = 2021
), -- HISTORICAL DATA
    historical_scd AS (
    SELECT
        player_name,
        scoring_class,
        is_active,
        start_season,
        end_season
    FROM players_scd
    WHERE current_season = 2021
    AND end_season < 2021
    ),
    this_season AS (
        SELECT * FROM players
        WHERE current_season = 2022
    ),
    unchanged_records AS (
    SELECT
        ts.player_name,
        ts.scoring_class,
        ts.is_active,
        ls.start_season,
        ts.current_season AS end_season
    FROM this_season AS ts
    JOIN last_season_scd AS ls
        ON ts.player_name = ls.player_name
    WHERE ts.scoring_class = ls.scoring_class
       OR ts.is_active = ls.is_active
    ),
    changed_records AS (
    SELECT
        ts.player_name,
        UNNEST(ARRAY[
                    ROW(
                        ls.scoring_class,
                        ls.is_active,
                        ls.start_season,
                        ls.end_season

                        )::scd_type,
                    ROW(
                        ts.scoring_class,
                        ts.is_active,
                        ts.current_season,
                        ts.current_season
                        )::scd_type
                ]) as records
    FROM this_season AS ts
    LEFT JOIN last_season_scd AS ls
        ON ts.player_name = ls.player_name
    WHERE (ts.scoring_class <> ls.scoring_class
       OR ts.is_active <> ls.is_active)
    ),
     unnested_changed_records AS (
     SELECT player_name,
            (records::scd_type).scoring_class,
            (records::scd_type).is_active,
            (records::scd_type).start_season,
            (records::scd_type).end_season
     FROM changed_records
    ),
    new_records AS (
    SELECT
       ts.player_name,
       ts.scoring_class,
       ts.is_active,
       ts.current_season AS start_season,
       ts.current_season AS end_season
    FROM this_season ts
    LEFT JOIN last_season_scd ls
        ON ts.player_name = ls.player_name
    WHERE ls.player_name IS NULL
    )
SELECT *, 2022 AS current_season FROM (
                  SELECT *
                  FROM historical_scd

                  UNION ALL

                  SELECT *
                  FROM unchanged_records

                  UNION ALL

                  SELECT *
                  FROM unnested_changed_records

                  UNION ALL

                  SELECT *
                  FROM new_records
              ) a;