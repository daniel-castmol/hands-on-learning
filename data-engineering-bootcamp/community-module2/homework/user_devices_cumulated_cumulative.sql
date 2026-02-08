-- CUMULATIVE QUERY FOR BUILDING THE TABLE YESTERDAY - TODAY PATTERN

INSERT INTO user_devices_cumulated
WITH yesterday AS (
    SELECT
        *
    FROM user_devices_cumulated
    WHERE dim_date = DATE('2023-01-30')
),
    today AS (
    SELECT
        e.user_id,
        COALESCE(d.browser_type, 'unknown_browser') AS browser_type,
        CAST(e.event_time AS DATE) AS event_date
    FROM events AS e
    LEFT JOIN devices AS d
        ON e.device_id = d.device_id
    WHERE user_id IS NOT NULL AND CAST(e.event_time AS DATE) = DATE('2023-01-31')
    GROUP BY e.user_id, COALESCE(d.browser_type, 'unknown_browser'), CAST(e.event_time AS DATE)
)
SELECT
    COALESCE(t.user_id,y.user_id) AS user_id,
    COALESCE(t.browser_type,y.browser_type) AS browser_type,
    CASE
        WHEN t.user_id IS NULL THEN y.device_activity_datelist
        WHEN y.user_id IS NULL THEN ARRAY[t.event_date]
        ELSE ARRAY[t.event_date] || y.device_activity_datelist
    END AS device_activity_datelist,
    COALESCE(t.event_date, y.dim_date + INTERVAL '1' DAY) AS dim_date
FROM today AS t
FULL OUTER JOIN yesterday AS y
ON t.user_id = y.user_id
AND t.browser_type = y.browser_type;