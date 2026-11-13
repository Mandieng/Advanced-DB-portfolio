# Ride-hailing and Logistics Normalisation

Normalisation reduces duplicated facts and avoids update anomalies. This example starts with a denormalised service log and moves to the six relations in the ER diagram. The records are fictional and abbreviated for readability.

## Starting trip log

| trip_id | customer details | driver details | pickup | drop-off | service/status | status events | payment attempts |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 501 | C10, Ama Mensah, ama@example.com | D20, Kofi Boateng, KOF-20 | 12 Main St, 5.6037,-0.1870 | 8 Market Rd, 5.6140,-0.2050 | delivery / picked_up | requested 09:00; matched 09:03; picked_up 09:20 | card 25.00 succeeded |
| 502 | C10, Ama Mensah, ama@example.com | D20, Kofi Boateng, KOF-20 | 12 Main St, 5.6037,-0.1870 | 4 Park Ave, 5.5900,-0.1800 | ride / completed | requested 11:00; matched 11:02; completed 11:24 | mobile_money 18.00 failed; card 18.00 succeeded |

The repeated event and payment lists are multi-valued fields. Customer, driver and location details also repeat each time they are involved in a trip.

## 1NF: Atomic values

Put one value in each cell and represent each status event and payment attempt as its own row. In a flattened log, the key would need to include the trip plus event/attempt identifiers. Joining both lists directly would multiply rows (for example, two status events and two payments could produce four combinations), so status events and payments should be separated rather than kept in a single repeating group.

For the trip facts, use one row per trip:

| trip_id | customer_id | customer_name | customer_email | driver_id | driver_name | license_number | pickup_address | dropoff_address | service_type | current_status | fare |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: |
| 501 | 10 | Ama Mensah | ama@example.com | 20 | Kofi Boateng | KOF-20 | 12 Main St | 8 Market Rd | delivery | picked_up | 25.00 |
| 502 | 10 | Ama Mensah | ama@example.com | 20 | Kofi Boateng | KOF-20 | 12 Main St | 4 Park Ave | ride | completed | 18.00 |

Every value is now atomic, but the same person's and driver's details still recur on different trip rows.

## 2NF: Depend on the whole key

In the original flattened event/attempt log, a natural composite key could be `(trip_id, status_event_id, payment_id)` for a row combining one event and one attempt. Trip facts depend only on `trip_id`, status facts depend on `(trip_id, status_event_id)`, and payment facts depend on `(trip_id, payment_id)`. Those partial dependencies show why the lists should not be combined into one relation.

Split the repeating groups into `trip_status_history` and `payment`, each with its own generated primary key and a `trip_id` foreign key. Keep trip-level facts in `trip`. This removes the partial dependency on the trip portion of the combined key for event and payment data.

## 3NF: Remove transitive dependencies

After separating events and payments, a one-row-per-trip relation still repeats descriptive information. The functional dependencies include:

- `customer_id → full_name, email, phone`
- `driver_id → full_name, email, phone, license_number`
- `location_id → label, address_text, latitude, longitude`
- `trip_id → customer_id, driver_id, service_type, pickup_location_id, dropoff_location_id, requested_at, status, fare_amount, currency, started_at, completed_at`
- `status_event_id → trip_id, status, changed_at, note`
- `payment_id → trip_id, amount, currency, method, status, provider_reference, created_at`

Move customer facts to `customer`, driver facts to `driver`, and endpoint facts to `location`. Keep only their keys in `trip`. Keep each status change and payment attempt in its own relation. Thus non-key attributes in each final relation describe that relation's key, not another non-key attribute. The `email`, `license_number` and optional provider reference unique constraints represent candidate keys in addition to the generated primary keys.

## Final relations

- `customer(customer_id PK, full_name, email UK, phone)`
- `driver(driver_id PK, full_name, email UK, phone, license_number UK)`
- `location(location_id PK, label, address_text, latitude, longitude)`
- `trip(trip_id PK, customer_id FK, driver_id FK, pickup_location_id FK, dropoff_location_id FK, service_type, requested_at, status, fare_amount, currency, started_at, completed_at)`
- `trip_status_history(status_event_id PK, trip_id FK, status, changed_at, note)`
- `payment(payment_id PK, trip_id FK, amount, currency, method, status, provider_reference UK, created_at)`

The final design is intended to be in 3NF under the stated assumptions. Status transitions and synchronizing a trip's current status with its appended history are workflow rules requiring transaction logic; normalisation alone does not enforce them.
