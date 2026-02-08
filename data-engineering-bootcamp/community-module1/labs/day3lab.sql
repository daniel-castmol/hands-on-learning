--####################################
-- LAB 3: GRAPH MODELLING
--###################################

CREATE TYPE vertex_type AS ENUM ('player', 'team', 'game');

CREATE TYPE edge_type AS ENUM ('plays_in', 'plays_against','shares_team','plays_on');

CREATE TABLE vertices (
    identifier TEXT,
    type vertex_type,
    properties JSON,
    PRIMARY KEY (identifier, type)
);

CREATE TABLE edges (
    subject_identifier TEXT,
    subject_type vertex_type,
    object_identifier TEXT,
    object_type vertex_type,
    edge_type edge_type,
    properties JSON,
    PRIMARY KEY (subject_identifier, subject_type, object_identifier, object_type, edge_type)
);

INSERT INTO vertices
SELECT
    game_id AS identifier,
    'game'::vertex_type AS type,
    json_build_object(
        'pts_home', pts_home,
        'pts_away', pts_away,
        'winning_team', CASE WHEN home_team_wins = 1 THEN home_team_id ELSE visitor_team_id END
    ) AS properties
FROM games;

INSERT INTO vertices
WITH players_agg AS (
    SELECT
        player_id AS identifier,
        MAX(player_name) AS player_name,
        COUNT(1) AS number_of_games,
        SUM(pts) AS total_points,
        ARRAY_AGG(DISTINCT team_id) AS teams_played
    FROM game_details
    GROUP BY player_id
)
SELECT
    identifier,
    'player'::vertex_type AS type,
    json_build_object(
        'player_name', player_name,
        'number_of_games', number_of_games,
        'total_points', total_points,
        'teams_played', teams_played
    ) AS properties
FROM players_agg;

INSERT INTO vertices
SELECT
    identifier, type, properties
FROM (
SELECT
    team_id AS identifier,
    'team'::vertex_type AS type,
    json_build_object(
        'abbreviation', abbreviation,
        'nickname', nickname,
        'city', city,
        'arena', arena,
        'year_founded',yearfounded
    ) AS properties,
    ROW_NUMBER() OVER (PARTITION BY team_id ORDER BY yearfounded DESC) AS rn
FROM teams
) AS subquery
WHERE rn = 1;

INSERT INTO edges
WITH deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY player_id,game_id) AS rn
    FROM game_details
)
SELECT
    player_id AS subjet_identifier,
    'player'::vertex_type AS subject_type,
    game_id AS object_identifier,
    'game'::vertex_type AS object_type,
    'plays_in'::edge_type AS edge_type,
    json_build_object(
            'start_position', start_position,
            'pts', pts,
            'team_id', team_id,
            'team_abbreviation', team_abbreviation
    ) AS properties
FROM deduped
WHERE rn = 1;