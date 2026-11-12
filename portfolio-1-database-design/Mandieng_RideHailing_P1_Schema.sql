-- Ride-hailing and logistics service schema (PostgreSQL).
-- Run once in an empty database. Current trip status and its history must be
-- changed together by the application in one transaction.
BEGIN;

CREATE TABLE public.customer (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL CHECK (btrim(full_name) <> ''),
    email VARCHAR(254) NOT NULL UNIQUE CHECK (btrim(email) <> ''),
    phone VARCHAR(30) NOT NULL CHECK (btrim(phone) <> '')
);

CREATE TABLE public.driver (
    driver_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL CHECK (btrim(full_name) <> ''),
    email VARCHAR(254) NOT NULL UNIQUE CHECK (btrim(email) <> ''),
    phone VARCHAR(30) NOT NULL CHECK (btrim(phone) <> ''),
    license_number VARCHAR(40) NOT NULL UNIQUE CHECK (btrim(license_number) <> '')
);

CREATE TABLE public.location (
    location_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    label VARCHAR(120) NOT NULL CHECK (btrim(label) <> ''),
    address_text VARCHAR(300) NOT NULL CHECK (btrim(address_text) <> ''),
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    CONSTRAINT location_coordinates_together
        CHECK ((latitude IS NULL) = (longitude IS NULL)),
    CONSTRAINT location_latitude_range
        CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT location_longitude_range
        CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
);

CREATE TABLE public.trip (
    trip_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES public.customer(customer_id),
    driver_id BIGINT REFERENCES public.driver(driver_id),
    service_type VARCHAR(12) NOT NULL
        CHECK (service_type IN ('ride', 'delivery')),
    pickup_location_id BIGINT NOT NULL REFERENCES public.location(location_id),
    dropoff_location_id BIGINT NOT NULL REFERENCES public.location(location_id),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'requested'
        CHECK (status IN (
            'requested', 'matched', 'driver_arrived', 'in_progress',
            'picked_up', 'completed', 'delivered', 'cancelled'
        )),
    fare_amount NUMERIC(10,2) NOT NULL CHECK (fare_amount >= 0),
    currency CHAR(3) NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    CONSTRAINT trip_driver_required_after_request
        CHECK (status IN ('requested', 'cancelled') OR driver_id IS NOT NULL),
    CONSTRAINT trip_completion_time_required
        CHECK (status NOT IN ('completed', 'delivered') OR completed_at IS NOT NULL),
    CONSTRAINT trip_completion_not_before_start
        CHECK (completed_at IS NULL OR (started_at IS NOT NULL AND completed_at >= started_at))
);

CREATE TABLE public.trip_status_history (
    status_event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trip_id BIGINT NOT NULL REFERENCES public.trip(trip_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL
        CHECK (status IN (
            'requested', 'matched', 'driver_arrived', 'in_progress',
            'picked_up', 'completed', 'delivered', 'cancelled'
        )),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note VARCHAR(300)
);

CREATE TABLE public.payment (
    payment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trip_id BIGINT NOT NULL REFERENCES public.trip(trip_id),
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
    method VARCHAR(20) NOT NULL
        CHECK (method IN ('card', 'cash', 'mobile_money', 'wallet')),
    status VARCHAR(12) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'succeeded', 'failed')),
    provider_reference VARCHAR(100) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT payment_provider_reference_not_blank
        CHECK (provider_reference IS NULL OR btrim(provider_reference) <> '')
);

-- Keep lookup joins efficient and enforce one successful payment per trip.
CREATE INDEX trip_customer_requested_idx
    ON public.trip (customer_id, requested_at DESC);
CREATE INDEX trip_driver_status_idx
    ON public.trip (driver_id, status);
CREATE INDEX trip_status_history_trip_time_idx
    ON public.trip_status_history (trip_id, changed_at);
CREATE UNIQUE INDEX payment_one_success_per_trip
    ON public.payment (trip_id)
    WHERE status = 'succeeded';

COMMIT;
