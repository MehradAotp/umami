-- Add user_id field to website_event table
CREATE TABLE umami.website_event_new
(
    website_id UUID,
    session_id UUID,
    visit_id UUID,
    event_id UUID,
    --sessions
    hostname LowCardinality(String),
    browser LowCardinality(String),
    os LowCardinality(String),
    device LowCardinality(String),
    screen LowCardinality(String),
    language LowCardinality(String),
    country LowCardinality(String),
    region LowCardinality(String),
    city String,
    --pageviews
    url_path String,
    url_query String,
    utm_source String,
    utm_medium String,
    utm_campaign String,
    utm_content String,
    utm_term String,
    referrer_path String,
    referrer_query String,
    referrer_domain String,
    page_title String,
    --clickIDs
    gclid String,
    fbclid String,
    msclkid String,
    ttclid String,
    li_fat_id String,
    twclid String,
    --events
    event_type UInt32,
    event_name String,
    tag String,
    distinct_id String,
    user_id String,
    created_at DateTime('UTC'),
    job_id Nullable(UUID)
)
ENGINE = MergeTree
    PARTITION BY toYYYYMM(created_at)
    ORDER BY (toStartOfHour(created_at), website_id, session_id, visit_id, created_at)
    PRIMARY KEY (toStartOfHour(created_at), website_id, session_id, visit_id)
    SETTINGS index_granularity = 8192;

-- Copy data from old table
INSERT INTO umami.website_event_new
SELECT website_id,
       session_id,
       visit_id,
       event_id,
       hostname,
       browser,
       os,
       device,
       screen,
       language,
       country,
       region,
       city,
       url_path,
       url_query,
       utm_source,
       utm_medium,
       utm_campaign,
       utm_content,
       utm_term,
       referrer_path,
       referrer_query,
       referrer_domain,
       page_title,
       gclid,
       fbclid,
       msclkid,
       ttclid,
       li_fat_id,
       twclid,
       event_type,
       event_name,
       tag,
       distinct_id,
       '',  -- user_id (empty string for existing data)
       created_at,
       job_id
FROM umami.website_event;

-- Update website_event_stats_hourly table
CREATE TABLE umami.website_event_stats_hourly_new
(
    website_id UUID,
    session_id UUID,
    visit_id UUID,
    hostname SimpleAggregateFunction(groupArrayArray, Array(String)),
    browser LowCardinality(String),
    os LowCardinality(String),
    device LowCardinality(String),
    screen LowCardinality(String),
    language LowCardinality(String),
    country LowCardinality(String),
    region LowCardinality(String),
    city String,
    entry_url AggregateFunction(argMin, String, DateTime('UTC')),
    exit_url AggregateFunction(argMax, String, DateTime('UTC')),
    url_path SimpleAggregateFunction(groupArrayArray, Array(String)),
    url_query SimpleAggregateFunction(groupArrayArray, Array(String)),
    utm_source SimpleAggregateFunction(groupArrayArray, Array(String)),
    utm_medium SimpleAggregateFunction(groupArrayArray, Array(String)),
    utm_campaign SimpleAggregateFunction(groupArrayArray, Array(String)),
    utm_content SimpleAggregateFunction(groupArrayArray, Array(String)),
    utm_term SimpleAggregateFunction(groupArrayArray, Array(String)),
    referrer_domain SimpleAggregateFunction(groupArrayArray, Array(String)),
    page_title SimpleAggregateFunction(groupArrayArray, Array(String)),
    gclid SimpleAggregateFunction(groupArrayArray, Array(String)),
    fbclid SimpleAggregateFunction(groupArrayArray, Array(String)),
    msclkid SimpleAggregateFunction(groupArrayArray, Array(String)),
    ttclid SimpleAggregateFunction(groupArrayArray, Array(String)),
    li_fat_id SimpleAggregateFunction(groupArrayArray, Array(String)),
    twclid SimpleAggregateFunction(groupArrayArray, Array(String)),
    event_type UInt32,
    event_name SimpleAggregateFunction(groupArrayArray, Array(String)),
    views SimpleAggregateFunction(sum, UInt64),
    min_time SimpleAggregateFunction(min, DateTime('UTC')),
    max_time SimpleAggregateFunction(max, DateTime('UTC')),
    tag SimpleAggregateFunction(groupArrayArray, Array(String)),
    distinct_id LowCardinality(String),
    user_id LowCardinality(String),
    created_at DateTime('UTC')
)
ENGINE = AggregatingMergeTree
    PARTITION BY toYYYYMM(created_at)
    ORDER BY (toStartOfHour(created_at), website_id, session_id, visit_id)
    PRIMARY KEY (toStartOfHour(created_at), website_id, session_id, visit_id)
    SETTINGS index_granularity = 8192;

-- Copy data from old stats table
INSERT INTO umami.website_event_stats_hourly_new
SELECT website_id,
       session_id,
       visit_id,
       hostname,
       browser,
       os,
       device,
       screen,
       language,
       country,
       region,
       city,
       entry_url,
       exit_url,
       url_path,
       url_query,
       utm_source,
       utm_medium,
       utm_campaign,
       utm_content,
       utm_term,
       referrer_domain,
       page_title,
       gclid,
       fbclid,
       msclkid,
       ttclid,
       li_fat_id,
       twclid,
       event_type,
       event_name,
       views,
       min_time,
       max_time,
       tag,
       distinct_id,
       '',  -- user_id (empty string for existing data)
       created_at
FROM umami.website_event_stats_hourly;

-- Add user_id to event_data table
CREATE TABLE umami.event_data_new
(
    website_id UUID,
    session_id UUID,
    event_id UUID,
    url_path String,
    event_name String,
    data_key String,
    string_value Nullable(String),
    number_value Nullable(Decimal64(4)),
    date_value Nullable(DateTime('UTC')),
    data_type UInt32,
    user_id String,
    created_at DateTime('UTC'),
    job_id Nullable(UUID)
)
ENGINE = MergeTree
    ORDER BY (website_id, event_id, data_key, created_at)
    SETTINGS index_granularity = 8192;

-- Copy data from old event_data table
INSERT INTO umami.event_data_new
SELECT website_id,
       session_id,
       event_id,
       url_path,
       event_name,
       data_key,
       string_value,
       number_value,
       date_value,
       data_type,
       '',  -- user_id (empty string for existing data)
       created_at,
       job_id
FROM umami.event_data;

-- Rename tables
RENAME TABLE umami.website_event TO umami.website_event_old;
RENAME TABLE umami.website_event_new TO umami.website_event;

RENAME TABLE umami.website_event_stats_hourly TO umami.website_event_stats_hourly_old;
RENAME TABLE umami.website_event_stats_hourly_new TO umami.website_event_stats_hourly;

RENAME TABLE umami.event_data TO umami.event_data_old;
RENAME TABLE umami.event_data_new TO umami.event_data;

/*
-- Drop old tables after verification
DROP TABLE umami.website_event_old;
DROP TABLE umami.website_event_stats_hourly_old;
DROP TABLE umami.event_data_old;
*/
