-- ####################################################
-- ## DDL FOR FACT TABLE FOR GAME DETAILS
-- ####################################################
-- ## IS VERY IMPORTANT FOR MODELING THAT YOU CREATE TABLES THAT ARE EASY AND FUN TO QUERY

CREATE TABLE fct_game_details (
    dim_game_date DATE,
    dim_season INT,
    dim_team_id INT,
    dim_player_id INT,
    dim_player_name VARCHAR(255),
    dim_start_position VARCHAR(255),
    dim_playing_at_home BOOLEAN,
    dim_did_not_play BOOLEAN,
    dim_did_not_dress BOOLEAN,
    dim_did_not_with_team BOOLEAN,
    m_minutes REAL,
    m_fgm INT,
    m_fga INT,
    m_fg3m INT,
    m_fg3a INT,
    m_ftm INT,
    m_fta INT,
    m_oreb INT,
    m_dreb INT,
    m_reb INT,
    m_ast INT,
    m_stl INT,
    m_blk INT,
    m_turnovers INT,
    m_pf INT,
    m_pts INT,
    m_plus_minus INT,
    PRIMARY KEY (dim_game_date, dim_team_id, dim_player_id)
);

DROP TABLE IF EXISTS fct_game_details;

INSERT INTO fct_game_details
WITH deduped AS (
    SELECT
        gd.*,
        g.game_date_est,
        g.season,
        g.home_team_id,
        ROW_NUMBER() OVER (PARTITION BY gd.game_id, gd.team_id, gd.player_id ORDER BY g.game_date_est) AS rn
    FROM game_details AS gd
    JOIN games AS g ON gd.game_id = g.game_id
)
SELECT
    game_date_est AS dim_game_date,
    season AS dim_season,
    team_id AS dim_team_id,
    player_id AS dim_player_id,
    player_name AS dim_player_name,
    start_position AS dim_start_position,
    CAST((team_id = home_team_id) AS BOOLEAN) AS dim_playing_at_home,
    COALESCE(POSITION('DNP' IN comment),0) > 0 AS dim_did_not_play,
    COALESCE(POSITION('DND' IN comment),0) > 0 AS dim_did_not_dress,
    COALESCE(POSITION('NWD' IN comment),0) > 0 AS dim_did_not_with_team,
    CAST(SPLIT_PART(min, ':', 1) AS REAL) +
    CAST(SPLIT_PART(min, ':', 2) AS REAL)/60 AS m_minutes,
    fgm AS m_fgm,
    fga AS m_fga,
    fg3m AS m_fg3m,
    fg3a AS m_fg3a,
    ftm AS m_ftm,
    fta AS m_fta,
    oreb AS m_oreb,
    dreb AS m_dreb,
    reb AS m_reb,
    ast AS m_ast,
    stl AS m_stl,
    blk AS m_blk,
    "TO" AS m_turnovers,
    pf AS m_pf,
    pts AS m_pts,
    plus_minus AS m_plus_minus
FROM deduped WHERE rn = 1;