# Ride-hailing and Logistics Database Design

## Case study description

This database supports a local ride-hailing and parcel-delivery service. Customers create trip requests for either a passenger ride or a delivery. Each trip captures pickup and drop-off locations, the customer, an optional assigned driver, the fare and the current operational status. As the request progresses, status changes are stored as dated history events so staff can track dispatch, pickup and completion. Payment attempts are stored independently from trips, allowing failed attempts to be retained without changing the trip record.

The design covers customer and driver records, locations, trips, trip-status history and payments. It assumes one customer, up to one assigned driver, one pickup and one drop-off per trip. It does not model live location streaming, route geometry, multi-stop journeys, dispatch algorithms, refunds or driver shifts.

## Entities

| Entity | Information stored |
| --- | --- |
| `customer` | A person or organisation requesting trips. |
| `driver` | A driver who may be assigned to fulfil trips. |
| `location` | A reusable address and coordinate record used as a trip endpoint. |
| `trip` | A ride or delivery request, assignment, endpoints, fare and current status. |
| `trip_status_history` | Timestamped status events for tracking a trip's progress. |
| `payment` | A payment attempt and its amount, method, provider reference and outcome. |

## Attributes, keys and constraints

`PK` means primary key, `FK` foreign key, and `UK` unique key. All primary keys are generated identity values.

| Relation | Attributes and PostgreSQL types | Keys and important constraints |
| --- | --- | --- |
| `customer` | `customer_id BIGINT`, `full_name VARCHAR(120)`, `email VARCHAR(254)`, `phone VARCHAR(30)` | PK `customer_id`; email unique; all fields required. |
| `driver` | `driver_id BIGINT`, `full_name VARCHAR(120)`, `email VARCHAR(254)`, `phone VARCHAR(30)`, `license_number VARCHAR(40)` | PK `driver_id`; email and license number unique; all fields required. |
| `location` | `location_id BIGINT`, `label VARCHAR(120)`, `address_text VARCHAR(300)`, `latitude NUMERIC(9,6)`, `longitude NUMERIC(9,6)` | PK `location_id`; label/address required; coordinates are either both absent or both present and within geographic bounds. |
| `trip` | `trip_id BIGINT`, `customer_id BIGINT`, `driver_id BIGINT NULL`, `service_type VARCHAR(12)`, `pickup_location_id BIGINT`, `dropoff_location_id BIGINT`, `requested_at TIMESTAMPTZ`, `status VARCHAR(20)`, `fare_amount NUMERIC(10,2)`, `currency CHAR(3)`, `started_at TIMESTAMPTZ NULL`, `completed_at TIMESTAMPTZ NULL` | PK `trip_id`; FKs to customer, optional driver and two locations; service/status enumerated by CHECK; fare nonnegative; completion cannot precede start; advanced statuses require a driver; completed/delivered statuses require completion time. |
| `trip_status_history` | `status_event_id BIGINT`, `trip_id BIGINT`, `status VARCHAR(20)`, `changed_at TIMESTAMPTZ`, `note VARCHAR(300) NULL` | PK `status_event_id`; FK `trip_id`; status constrained to supported values. |
| `payment` | `payment_id BIGINT`, `trip_id BIGINT`, `amount NUMERIC(10,2)`, `currency CHAR(3)`, `method VARCHAR(20)`, `status VARCHAR(12)`, `provider_reference VARCHAR(100) NULL`, `created_at TIMESTAMPTZ` | PK `payment_id`; FK `trip_id`; positive amount; method/status constrained; provider reference unique when supplied; partial unique index allows at most one successful payment per trip. |

## Relationships

| Relationship | Cardinality | Meaning |
| --- | --- | --- |
| Customer → Trip | 1 to 0..many | A customer can request many trips; each trip belongs to one customer. |
| Driver → Trip | 1 to 0..many | A driver can fulfil many trips over time; a trip has zero or one assigned driver. |
| Location → Trip (pickup) | 1 to 0..many | Each trip has exactly one pickup location; one location may be reused by many trips. |
| Location → Trip (drop-off) | 1 to 0..many | Each trip has exactly one drop-off location; one location may be reused by many trips. |
| Trip → Trip status history | 1 to 0..many | A trip may have many status events; each event belongs to one trip. |
| Trip → Payment | 1 to 0..many | A trip may have multiple payment attempts; each payment attempt belongs to one trip. |

## Business rules

1. Customer email addresses are unique. Driver email addresses and licence numbers are each unique.
2. A trip must reference an existing customer, pickup location and drop-off location. Its driver is optional until assignment and, if present, must reference an existing driver.
3. `service_type` is either `ride` or `delivery`. Current trip statuses are `requested`, `matched`, `driver_arrived`, `in_progress`, `picked_up`, `completed`, `delivered` and `cancelled`.
4. A trip in a post-request operational state (`matched`, `driver_arrived`, `in_progress`, `picked_up`, `completed` or `delivered`) must have an assigned driver. A cancellation may occur before or after assignment.
5. Fare cannot be negative. A trip's completion time cannot be earlier than its start time. A completed ride or delivered parcel requires a completion time.
6. Every status change should update `trip.status` and append a `trip_status_history` row atomically. The database does not by itself enforce legal status transitions or ensure that the latest history event equals the current status.
7. A trip may have several payment attempts, including failed attempts, but no more than one payment may have `succeeded` status. Payment amount must be positive.
8. Coordinates must be within latitude [-90, 90] and longitude [-180, 180], and both coordinates are either supplied together or omitted together.

## Why the model separates these entities

Customer and driver details are held independently from trips, so a person's contact details are not repeated for each journey. Locations are stored once and referenced in the pickup/drop-off roles. Trip-status history preserves the sequence of operational updates, while payment attempts preserve their own outcomes and provider references. The ER diagram and normalisation note explain these separations in more detail.
