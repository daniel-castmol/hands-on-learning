-- ####################################################
-- ## INCREMENTAL QUERY FOR ACTORS HISTORY SCD
-- ####################################################
-- ## COMBINES THE PREVIOUS YEAR'S SCD DATA WITH NEW INCOMING DATA FROM THE ACTORS TABLE
-- ####################################################

INSERT INTO actors_history_scd
WITH last_year_scd AS (
    SELECT
        actorid,
        actor,
        quality_class,
        is_active,
        indicator,
        start_date,
        end_date
    FROM actors_history_scd
    WHERE current_year = 2020
    AND end_date = 2020
),
    historical_scd AS (
        SELECT
            actorid,
            actor,
            quality_class,
            is_active,
            indicator,
            start_date,
            end_date
        FROM actors_history_scd
        WHERE current_year = 2020
        AND end_date < 2020
    ),
    this_year AS (
        SELECT
            *
        FROM actors
        WHERE current_year = 2021
    ),
    unchanged_records AS (
        SELECT
            ty.actorid,
            ty.actor,
            ty.quality_class,
            ty.is_active,
            ly.indicator,
            ly.start_date,
            ty.current_year AS end_date
        FROM this_year AS ty
        JOIN last_year_scd AS ly
        ON ty.actorid = ly.actorid
        WHERE ty.quality_class = ly.quality_class
        AND ty.is_active = ly.is_active
    ),
    changed_records AS (
        SELECT
            ty.actorid,
            ty.actor,
            UNNEST(
                    ARRAY[
                        ROW(
                            ly.quality_class,
                            ly.is_active,
                            ly.indicator,
                            ly.start_date,
                            ty.current_year - 1
                            )::actors_scd_type,
                        ROW(
                            ty.quality_class,
                            ty.is_active,
                            ly.indicator + 1,
                            ty.current_year,
                            ty.current_year
                            )::actors_scd_type
                        ]) AS records
        FROM this_year AS ty
        INNER JOIN last_year_scd AS ly
        ON ty.actorid = ly.actorid
        WHERE (ty.quality_class IS DISTINCT FROM ly.quality_class OR ty.is_active IS DISTINCT FROM ly.is_active)
    ),
    unnested_changed_records AS (
        SELECT
            actorid,
            actor,
            (records::actors_scd_type).quality_class,
            (records::actors_scd_type).is_active,
            (records::actors_scd_type).indicator,
            (records::actors_scd_type).start_date,
            (records::actors_scd_type).end_date
        FROM changed_records
    ),
    new_records AS (
        SELECT
            ty.actorid,
            ty.actor,
            ty.quality_class,
            ty.is_active,
            0 AS indicator,
            ty.current_year AS start_date,
            ty.current_year AS end_date
        FROM this_year AS ty
        LEFT JOIN last_year_scd AS ly
        ON ty.actorid = ly.actorid
        WHERE ly.actorid IS NULL
    )
SELECT *, 2021 AS current_year FROM (
        SELECT * FROM historical_scd

            UNION ALL

        SELECT * FROM unchanged_records

            UNION ALL

        SELECT * FROM unnested_changed_records

            UNION ALL

        SELECT * FROM new_records
                                    ) AS a;