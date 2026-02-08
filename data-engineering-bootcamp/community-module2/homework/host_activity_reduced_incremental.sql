-- REDUCED QUERY FOR BUILDING THE TABLE YESTERDAY - TODAY PATTERN
INSERT INTO host_activity_reduced
WITH daily_aggregates AS (
    SELECT
        host,
        DATE(event_time) AS event_date,
        COUNT(1) AS num_host_hits,
        COUNT(DISTINCT user_id) AS num_unique_visitors
    FROM events
    WHERE DATE(event_time) = DATE('2023-01-03')
    GROUP BY host, DATE(event_time)
),
    yesterday_array AS (
        SELECT * FROM host_activity_reduced
        WHERE DATE(month_start) = DATE_TRUNC('month', DATE('2023-01-01'))
    )
SELECT
    COALESCE(da.host,ya.host) AS host,
    COALESCE(ya.month_start, DATE_TRUNC('month',da.event_date)) AS month_start,
    CASE
        WHEN ya.hit_array IS NOT NULL
            THEN ya.hit_array || ARRAY[COALESCE(da.num_host_hits,0)]
        WHEN ya.hit_array IS NULL
            THEN ARRAY_FILL(0, ARRAY[COALESCE((event_date - DATE(DATE_TRUNC('month', event_date))),0)]) || ARRAY[COALESCE(da.num_host_hits,0)]
    END AS hit_array,
    CASE
        WHEN ya.unique_visitors IS NOT NULL
            THEN ya.unique_visitors || ARRAY[COALESCE(da.num_unique_visitors,0)]
        WHEN ya.unique_visitors IS NULL
            THEN ARRAY_FILL(0, ARRAY[COALESCE((event_date - DATE(DATE_TRUNC('month', event_date))),0)]) || ARRAY[COALESCE(da.num_unique_visitors,0)]
    END AS unique_visitors
FROM daily_aggregates AS da
FULL OUTER JOIN yesterday_array AS ya
ON da.host = ya.host
ON CONFLICT (host, month_start)
DO UPDATE SET hit_array = EXCLUDED.hit_array, unique_visitors = EXCLUDED.unique_visitors;