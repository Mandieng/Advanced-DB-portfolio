# Ride-hailing and Logistics Relational Design

## Case study

This database supports a local ride-hailing and parcel-delivery service. A customer requests a passenger ride or delivery. The system records endpoints, assigns an available driver, updates the current trip state and keeps a timestamped history of status changes. Payment attempts are tracked independently so a failed attempt can be retained before another succeeds.

## Scope and assumptions

A trip has one customer, one pickup and one drop-off location, and zero or one assigned driver. Drivers can serve either rides or deliveries and may have only one active trip at a time. There may be multiple payment attempts, but at most one successful payment per trip. Status history is append-oriented, and updates to current status plus history should be performed together in a transaction. The database schema does not enforce the full status transition graph; application/transaction logic must do that. GPS streaming, multi-stop routing, shifts, refunds and real payment processing are outside scope.

## Relations, keys and constraints

`PK` = primary key, `FK` = foreign key, `UK` = unique candidate key.

| Relation | Attributes | Keys and constraints |
| --- | --- | --- |
| `customer` | `customer_id BIGINT`, `full_name VARCHAR(120)`, `email VARCHAR(254)`, `phone VARCHAR(30)` | PK `customer_id`; email UK; required nonblank values. |
| `driver` | `driver_id BIGINT`, `full_name VARCHAR(120)`, `email VARCHAR(254)`, `phone VARCHAR(30)`, `license_number VARCHAR(40)` | PK `driver_id`; email and licence number UK; required nonblank values. |
| `location` | `location_id BIGINT`, `label VARCHAR(120)`, `address_text VARCHAR(300)`, `latitude NUMERIC(9,6) NULL`, `longitude NUMERIC(9,6) NULL` | PK `location_id`; coordinates jointly null/non-null and within valid ranges. |
| `trip` | `trip_id BIGINT`, `customer_id BIGINT`, `driver_id BIGINT NULL`, `service_type VARCHAR(12)`, `pickup_location_id BIGINT`, `dropoff_location_id BIGINT`, `requested_at TIMESTAMPTZ`, `status VARCHAR(20)`, `fare_amount NUMERIC(10,2)`, `currency CHAR(3)`, `started_at TIMESTAMPTZ NULL`, `completed_at TIMESTAMPTZ NULL` | PK `trip_id`; customer, driver and two location FKs; enumerated service/status; nonnegative fare; uppercase 3-letter currency; active status requires driver; ride/delivery states are compatible; completion timestamp follows start and is required for completed/delivered. Partial unique index allows one active trip per driver. |
| `trip_status_history` | `status_event_id BIGINT`, `trip_id BIGINT`, `status VARCHAR(20)`, `changed_at TIMESTAMPTZ`, `note VARCHAR(300) NULL` | PK `status_event_id`; trip FK; enumerated status. |
| `payment` | `payment_id BIGINT`, `trip_id BIGINT`, `amount NUMERIC(10,2)`, `currency CHAR(3)`, `method VARCHAR(20)`, `status VARCHAR(12)`, `provider_reference VARCHAR(100) NULL`, `created_at TIMESTAMPTZ` | PK `payment_id`; trip FK; positive amount; enumerated method/status; optional unique provider reference; partial unique index allows one successful payment per trip. |

## Relationships and cardinalities

- One customer may request zero or many trips; each trip has exactly one customer.
- A driver may fulfil zero or many trips over time; each trip has zero or one driver. A partial unique index limits a driver to one active assignment.
- Each trip has exactly one pickup and one drop-off location; a location may appear in many trips in either role.
- A trip may have zero or many status-history events and zero or many payment attempts; each child row belongs to one trip.

## Business rules

1. Customer email, driver email and driver licence number are unique.
2. Foreign keys require every trip customer/location, any assigned driver, and every event/payment parent to exist.
3. Service is `ride` or `delivery`. Supported statuses are `requested`, `matched`, `driver_arrived`, `in_progress`, `picked_up`, `completed`, `delivered` and `cancelled`; `picked_up`/`delivered` are delivery states, while `in_progress`/`completed` are ride states.
4. A non-requested, non-cancelled operational trip must have a driver. A driver cannot have multiple active trips concurrently.
5. Fare cannot be negative. Coordinates are optional as a pair and range-checked. Timestamps cannot complete before a recorded start.
6. Completed trips require completion time. A production workflow should also validate allowed status transitions and require a successful payment amount/currency policy before closing a trip; cross-table business rules need transactional logic or other database mechanisms.
7. Status updates and corresponding history inserts must succeed or fail together. The schema provides both relations but does not automatically maintain their consistency.
8. Failed/pending payment attempts remain in the record. At most one payment per trip may be `succeeded`.

See the [ER diagram](RideHailing_P1_ERDiagram.md), [normalisation explanation](RideHailing_P1_Normalisation.md), and executable [schema](RideHailing_P1_Schema.sql) for the full model.
