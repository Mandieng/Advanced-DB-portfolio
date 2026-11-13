-- Negative constraint checks. Run each INSERT separately (outside a transaction
-- block or after ROLLBACK), because a PostgreSQL error aborts its transaction.
-- Each statement is expected to be rejected by the named constraint.

-- Required name cannot be blank.
INSERT INTO public.customer (full_name, email, phone)
VALUES ('   ', 'blank.name@example.test', '+233200000199');

-- Email must be unique (sample data contains this email).
INSERT INTO public.customer (full_name, email, phone)
VALUES ('Duplicate Email', 'ama.mensah@example.test', '+233200000198');

-- Foreign key must reference an existing customer.
INSERT INTO public.trip (
    customer_id, service_type, pickup_location_id, dropoff_location_id,
    fare_amount, currency
) VALUES (999999, 'ride', 1, 2, 10.00, 'GHS');

-- A non-requested operational status requires an assigned driver.
INSERT INTO public.trip (
    customer_id, service_type, pickup_location_id, dropoff_location_id,
    status, fare_amount, currency
) VALUES (1, 'ride', 1, 2, 'matched', 10.00, 'GHS');

-- Latitude and longitude must be supplied together.
INSERT INTO public.location (label, address_text, latitude, longitude)
VALUES ('Invalid coordinates', 'Test address', 5.600000, NULL);

-- A trip may not have two successful payments (sample data has successful payment for trip 1).
INSERT INTO public.payment (trip_id, amount, currency, method, status)
VALUES (1, 1.00, 'GHS', 'cash', 'succeeded');

-- Payment amount must be positive.
INSERT INTO public.payment (trip_id, amount, currency, method, status)
VALUES (1, 0.00, 'GHS', 'card', 'pending');
