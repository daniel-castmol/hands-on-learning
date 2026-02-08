-- ####################################################
-- ## DDL FOR ACTORS HISTORY SCD TABLE
-- ####################################################
CREATE TABLE actors_history_scd (
    actorid TEXT,
    actor TEXT,
    quality_class quality_class,
    is_active BOOLEAN,
    indicator INT,
    start_date INT,
    end_date INT,
    current_year INT,
    PRIMARY KEY (actorid, start_date, current_year)
);


-- ####################################################
-- ## TYPE FOR ACTORS SCD
-- ####################################################

CREATE TYPE actors_scd_type AS (
                    quality_class quality_class,
                    is_active boolean,
                    indicator INTEGER,
                    start_date INTEGER,
                    end_date INTEGER
                        );