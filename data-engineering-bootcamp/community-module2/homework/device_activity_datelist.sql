-- DATELIST INT GENERATION QUERY

WITH user_device_activity AS (
    SELECT * FROM user_devices_cumulated WHERE dim_date = DATE('2023-01-31')
),
    date_series AS (
        SELECT * FROM generate_series(DATE('2023-01-01'), DATE('2023-01-31'), INTERVAL '1 day') AS series_date
    ),
    placeholder AS (
        SELECT
            CASE
                WHEN device_activity_datelist @> ARRAY[DATE(series_date)]
                    THEN CAST(POW(2, (dim_date -DATE(series_date))) AS BIGINT)
                ELSE 0
            END AS placeholder_int,
            *
        FROM user_device_activity
        CROSS JOIN date_series
    )
SELECT
    user_id,
    browser_type,
    CAST(SUM(placeholder_int)::BIGINT AS BIT(32)) AS datelist_int
FROM placeholder
GROUP BY user_id, browser_type;