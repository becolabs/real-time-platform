#!/bin/bash
set -e

clickhouse-client -n --password "$CLICKHOUSE_PASSWORD" <<-EOSQL
    CREATE TABLE IF NOT EXISTS real_time_analytics.clickstream_aggregates
    (
        \`window_start\` DateTime,
        \`window_end\` DateTime,
        \`page_url\` String,
        \`click_count\` UInt64
    )
    ENGINE = MergeTree()
    ORDER BY (window_start, page_url)
    PARTITION BY toYYYYMM(window_start);
EOSQL