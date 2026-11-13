# Ride-hailing and Logistics ER Diagram

The diagram shows the core records and their relationships.

```mermaid
erDiagram
    direction LR
    customer ||--o{ trip : requests
    driver o|--o{ trip : fulfils
    location ||--o{ trip : pickup_for
    location ||--o{ trip : dropoff_for
    trip ||--o{ trip_status_history : records
    trip ||--o{ payment : has_attempts

    customer {
        bigint customer_id PK
        varchar full_name
        varchar email UK
        varchar phone
    }
    driver {
        bigint driver_id PK
        varchar full_name
        varchar email UK
        varchar phone
        varchar license_number UK
    }
    location {
        bigint location_id PK
        varchar label
        varchar address_text
        numeric latitude
        numeric longitude
    }
    trip {
        bigint trip_id PK
        bigint customer_id FK
        bigint driver_id FK "Optional until assigned"
        varchar service_type
        bigint pickup_location_id FK
        bigint dropoff_location_id FK
        timestamptz requested_at
        varchar status
        numeric fare_amount
        char currency
        timestamptz started_at "Optional"
        timestamptz completed_at "Optional"
    }
    trip_status_history {
        bigint status_event_id PK
        bigint trip_id FK
        varchar status
        timestamptz changed_at
        varchar note "Optional"
    }
    payment {
        bigint payment_id PK
        bigint trip_id FK
        numeric amount
        char currency
        varchar method
        varchar status
        varchar provider_reference UK "Optional"
        timestamptz created_at
    }
```

## Reading the diagram

- `PK` is a primary key; `FK` is a foreign key; `UK` is unique.
- `||` means exactly one, `o{` means zero or many, and `o|` means zero or one.
- Each trip has one customer, one pickup and one drop-off location. Its driver may be unassigned initially.
- Status history and payment attempts are separate child records, preserving multiple events/attempts for a trip.
- A partial unique database index enforces at most one successful payment per trip. The status-history/current-status synchronization is a transaction-level rule.
