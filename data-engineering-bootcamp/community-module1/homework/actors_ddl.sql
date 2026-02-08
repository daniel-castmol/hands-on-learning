-- ####################################################
-- ## TYPE FOR FILM STATS
-- ####################################################

CREATE TYPE film_stats AS (
    film TEXT,
    votes INT,
    rating REAL,
    filmid TEXT
);

-- ####################################################
-- ## TYPE FOR QUALITY CLASS
-- ####################################################

CREATE TYPE quality_class AS ENUM ('star','good','average','bad');

-- #################################################### 
-- ## DDL FOR ACTORS TABLE; Cumulative table for actors
-- ####################################################

CREATE TABLE actors (
    actorid TEXT,
    actor TEXT,
    films film_stats[],
    quality_class quality_class,
    years_since_last_active INT,
    is_active BOOLEAN,
    current_year INT,
    PRIMARY KEY (actorid, current_year)
);
