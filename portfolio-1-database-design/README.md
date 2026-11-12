# Portfolio 1 — Ride-hailing and Logistics Database Design

This folder contains a database design for a ride-hailing and local-delivery service. It is an original design for the portfolio brief, structured similarly to a database-design portfolio with a case study, ER diagram, relational schema, normalisation discussion and PostgreSQL implementation.

## Case study

The service lets a customer request either a passenger ride or a parcel delivery. A trip records the customer, optional assigned driver, pickup and drop-off locations, service type, current status and quoted fare. The service keeps a history of trip-status changes for operational tracking. Payments are recorded separately so payment attempts and their outcomes do not overwrite trip information.

### Users and operations

- **Customers** request rides or deliveries and pay for completed service.
- **Drivers** accept and fulfil trips.
- **Operations staff** review requests, assignments, trip progress and payment outcomes.
- Main operations: register a customer or driver; record pickup/drop-off locations; create and match a trip; update trip status; record a payment attempt; review a trip's status history.

### Scope and assumptions

This design covers one service area and stores address/coordinate snapshots for each trip's pickup and drop-off. A trip has one customer, at most one assigned driver, and exactly one pickup and drop-off location. Drivers can fulfil both service types. A trip can have multiple payment attempts but at most one successful payment. A trip's current status is stored on `trip`; each change should also be appended to `trip_status_history` in the same transaction. Status transition validity (for example, preventing a delivered trip from returning to requested) is enforced by application/transaction logic, not a row-level CHECK. Driver availability, live GPS telemetry, tips, refunds, promotions, dispatch algorithms and multi-stop routes are outside this first design.

## Design files

| File | Contents |
| --- | --- |
| [Design](Mandieng_RideHailing_P1_Design.md) | Case-study rules, entities, attributes, keys, relationships and constraints. |
| [ER diagram](Mandieng_RideHailing_P1_ERDiagram.md) | Entities and cardinalities. |
| [Normalisation](Mandieng_RideHailing_P1_Normalisation.md) | Worked explanation of 1NF, 2NF and 3NF. |
| [Schema](Mandieng_RideHailing_P1_Schema.sql) | PostgreSQL tables, keys, checks and indexes. |
| [Sample data](Mandieng_RideHailing_P1_SampleData.sql) | Fictional customer, driver, locations, trips, status events and payments. |
| [Constraint tests](Mandieng_RideHailing_P1_ConstraintTests.sql) | Invalid statements to run individually to verify key constraints. |
| [Evidence checklist](Mandieng_RideHailing_P1_Evidence.md) | Suggested screenshots and evidence to capture after running the SQL. |

## Suggested run order

1. Create/connect to an empty PostgreSQL database.
2. Run `Mandieng_RideHailing_P1_Schema.sql`.
3. Run `Mandieng_RideHailing_P1_SampleData.sql`.
4. Run each negative test in `Mandieng_RideHailing_P1_ConstraintTests.sql` separately; each is expected to fail.
5. Capture actual database and diagram screenshots and add them under a `screenshots/` subfolder before marking them complete in the evidence checklist.

The sample data is illustrative and fictional. No screenshots or test results are claimed by this design document until they are captured from an actual database run.
