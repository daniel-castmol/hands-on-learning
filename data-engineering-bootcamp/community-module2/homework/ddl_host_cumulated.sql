-- DDL FOR HOST_CUMULATED TABLE
CREATE TABLE host_cumulated (
    host TEXT,
    host_activity_datelist DATE[],
    dim_date DATE,
    PRIMARY KEY (host, dim_date)
);