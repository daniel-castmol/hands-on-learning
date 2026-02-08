--- DDL FOR USER_DEVICES_CUMULATED TABLE
--- WENT FOR ONE ROW PER USER PER BROWSER TYPE

CREATE TABLE user_devices_cumulated (
    user_id NUMERIC,
    browser_type VARCHAR(255),
    device_activity_datelist DATE[],
    dim_date DATE,
    PRIMARY KEY (user_id, browser_type, dim_date)
);