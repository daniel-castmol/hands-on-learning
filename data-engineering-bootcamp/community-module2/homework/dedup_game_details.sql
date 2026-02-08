-- GAME DETAILS DEDUP QUERY

WITH deduped AS (
    SELECT
        gd.*,
        g.game_date_est,
        -- RANKING THE ROWS BY KEY COLUMNS AND ORDERED BY DATE (A PLAYER CAN BE IN ONE TEAM PER GAME)
        ROW_NUMBER() OVER (PARTITION BY gd.game_id, gd.team_id, gd.player_id ORDER BY g.game_date_est) AS rn
    FROM game_details AS gd
    JOIN games AS g ON gd.game_id = g.game_id
)
-- SELECTING THE FIRST ROW OF EACH GROUP
SELECT * FROM deduped WHERE rn = 1;