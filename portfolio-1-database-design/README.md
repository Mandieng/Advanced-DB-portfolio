# Portfolio 1 — Ride-hailing and Logistics Database Design

**Course:** MIT 8103 Advanced Database Systems  
**Portfolio:** Database design and modelling  
**Database:** PostgreSQL 16  
**Status:** Runnable, Portable local demo with evidence screenshots.

## 1. Case study

On portfolio 1, we designs relational database for a local ride-hailing and parcel-delivery service. A customer submits a request for a passenger ride or a delivery. The service records its pickup and drop-off locations, assigns a driver, tracks operational status and records payment attempts. Operations staff need to find unassigned requests, inspect a trip's event history and review payment outcomes.

### Users and main operations

- **Customers** request a ride or delivery and pay for service.
- **Drivers** are assigned to and fulfil trips.
- **Operations staff** review requests, assign drivers, update trip progress and investigate payment outcomes.
- Core operations: register a customer or driver; save locations; request a trip; match it to a driver; record progress; capture payment attempts; view trip and delivery status history.

### Scope and assumptions

The model represents one local service area. A trip has one customer, exactly one pickup and one drop-off location, and at most one assigned driver. A driver may have many historical trips but only one active trip at a time. A trip can have multiple payment attempts, including failed attempts, but at most one successful payment. Each trip's current status is kept in `trip`; status events are retained in `trip_status_history`.

This first version does not model live GPS telemetry, routes or multi-stop trips, driver shifts, dispatch optimisation, tips, refunds, promotions, authentication or external payment processing. The data is fictional. Status transition validity and synchronization of current status with history are transactional workflow responsibilities, explicitly noted rather than overstated as database-enforced constraints.

## 2. Design artifacts

| Artifact | Description |
| --- | --- |
| [Design](RideHailing_P1_Design.md) | Case study, entities, attributes, keys, relationships and business rules. |
| [ER diagram](RideHailing_P1_ERDiagram.md) | Mermaid ER diagram with relationship cardinalities. |
| [Normalisation](RideHailing_P1_Normalisation.md) | Worked 1NF, 2NF and 3NF explanation. |
| [Schema](RideHailing_P1_Schema.sql) | PostgreSQL relations, constraints and indexes. |
| [Sample data](RideHailing_P1_SampleData.sql) | Fictional customer, driver, location, trip, status and payment records. |
| [Queries](RideHailing_P1_Queries.sql) | Operational reads and an atomic example of matching a request. |
| [Constraint tests](RideHailing_P1_ConstraintTests.sql) | Negative checks to execute individually against a populated demo database. |
| [Evidence checklist](RideHailing_P1_Evidence.md) | Evidence to capture after the local run; pending items are not claimed as completed. |

## 3. Run with Docker Compose

Requires Docker Engine/Desktop with the `docker compose` plugin. The Compose project builds a PostgreSQL 16 image, initializes an empty named volume with the schema and sample rows, and exposes PostgreSQL on the host loopback interface only.

```bash
cd portfolio-1-database-design
cp .env.example .env
docker compose up --build -d
```

Check readiness and initialization logs:

```bash
docker compose ps
docker compose logs db
```

Connect with `psql` inside the container:

```bash
docker compose exec db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

Or connect from a host PostgreSQL client using host `localhost`, port from `DB_PORT` (default `5432`), and the credentials in your local `.env` file.

The image runs schema then sample data via PostgreSQL's standard first-initialization mechanism. Initialization scripts run **only when the database volume is empty**. Editing SQL and rebuilding the image does not rerun them against an existing volume. To recreate this disposable demo database and lose its contents:

```bash
docker compose down -v
docker compose up --build -d
```

## 4. Run without Docker

On PostgreSQL 16, connect to an empty database and execute in order:

```bash
psql -v ON_ERROR_STOP=1 -d ride_hailing -f RideHailing_P1_Schema.sql
psql -v ON_ERROR_STOP=1 -d ride_hailing -f RideHailing_P1_SampleData.sql
psql -v ON_ERROR_STOP=1 -d ride_hailing -f RideHailing_P1_Queries.sql
```

Run negative statements from the constraint-test file one at a time; expected errors abort the current transaction when issued inside a transaction block.

## 5. Design highlights

- Generated surrogate primary keys identify records; unique candidate keys protect customer/driver emails, driver licence numbers and supplied payment references.
- Foreign keys protect customer, driver, endpoint, trip-history and payment relationships.
- `CHECK` constraints validate enumerated values, nonblank required text, currency format, nonnegative fares, positive payments, coordinate ranges, and timestamp consistency.
- A partial unique index prevents one driver from being assigned multiple active trips concurrently; another prevents multiple successful payments for the same trip.
- Separate status-history and payment relations preserve event/attempt history without repeating it in a trip row.
- See the [normalisation explanation](RideHailing_P1_Normalisation.md) for functional dependencies and decomposition.

## 6. Evidence and honest reporting

This work was done in collaboration with the Copilot AI Tool
