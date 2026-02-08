-- CUMULATIVE QUERY FOR BUILDING THE TABLE YESTERDAY - TODAY PATTERN
INSERT INTO host_cumulated
WITH yesterday AS (
    SELECT
        *
    FROM host_cumulated
    WHERE dim_date = DATE('2023-01-01')
),
    today AS (
        SELECT
            host,
            DATE(event_time) AS event_date
        FROM events
        WHERE DATE(event_time) = DATE('2023-01-02')
        GROUP BY host, DATE(event_time)
    )
SELECT
    COALESCE(t.host,y.host) AS host,
    CASE
        WHEN t.host IS NULL THEN y.host_activity_datelist
        WHEN y.host IS NULL THEN ARRAY[t.event_date]
        ELSE ARRAY[t.event_date] || y.host_activity_datelist
    END AS host_activity_datelist,
    COALESCE(t.event_date, y.dim_date + INTERVAL '1' DAY) AS dim_date
FROM today AS t
FULL OUTER JOIN yesterday AS y
ON t.host = y.host;