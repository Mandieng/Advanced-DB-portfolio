# PostgreSQL 16 demo image; schema/data are initialized on an empty data volume.
FROM postgres:16-alpine

COPY Mandieng_RideHailing_P1_Schema.sql /docker-entrypoint-initdb.d/01-schema.sql
COPY Mandieng_RideHailing_P1_SampleData.sql /docker-entrypoint-initdb.d/02-sample-data.sql
