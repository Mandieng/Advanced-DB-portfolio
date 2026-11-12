# Portfolio 1 Evidence Checklist

This checklist records evidence to capture when the schema is run in PostgreSQL. Screenshots are intentionally not included yet; do not mark a row complete until the corresponding evidence exists in `screenshots/`.

| Evidence to capture | Suggested screenshot/file | Status |
| --- | --- | --- |
| ER diagram rendered from the Mermaid source | `screenshots/Mandieng_RideHailing_P1_ERDiagram.png` | Pending |
| Normalisation explanation | `screenshots/Mandieng_RideHailing_P1_Normalisation.png` | Pending |
| Database connection and database name | `screenshots/Mandieng_RideHailing_P1_DatabaseConnection.png` | Pending |
| Successful creation of all six tables and indexes | `screenshots/Mandieng_RideHailing_P1_TableCreation.png` | Pending |
| Table list and key constraints | `screenshots/Mandieng_RideHailing_P1_TableList.png` | Pending |
| Sample rows and final record counts | `screenshots/Mandieng_RideHailing_P1_SampleData.png` | Pending |
| Expected rejection of invalid customer, FK, driver assignment, coordinates and payment rows | `screenshots/Mandieng_RideHailing_P1_ConstraintTests.png` | Pending |
| Trip status history and payment-attempt query results | `screenshots/Mandieng_RideHailing_P1_TripTracking.png` | Pending |

Capture the actual PostgreSQL client output after running the scripts. The test script's negative statements must be run one at a time; each should fail for its stated constraint, and expected failures should not be described as observed until verified.
