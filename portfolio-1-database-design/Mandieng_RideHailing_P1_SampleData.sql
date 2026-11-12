-- Fictional sample records for the ride-hailing/logistics schema.
-- Run after Mandieng_RideHailing_P1_Schema.sql.
BEGIN;

INSERT INTO public.customer (full_name, email, phone) VALUES
    ('Ama Mensah', 'ama.mensah@example.test', '+233200000101'),
    ('Kojo Asare', 'kojo.asare@example.test', '+233200000102');

INSERT INTO public.driver (full_name, email, phone, license_number) VALUES
    ('Kofi Boateng', 'kofi.boateng@example.test', '+233240000201', 'GH-LIC-2001'),
    ('Esi Owusu', 'esi.owusu@example.test', '+233240000202', 'GH-LIC-2002');

INSERT INTO public.location (label, address_text, latitude, longitude) VALUES
    ('Osu pickup', '12 Oxford Street, Osu', 5.556000, -0.182000),
    ('Market delivery', '8 Market Road, Accra', 5.614000, -0.205000),
    ('Airport pickup', 'Kotoka International Airport, Accra', 5.605000, -0.167000),
    ('Labone drop-off', '4 Park Avenue, Labone', 5.570000, -0.167000);

INSERT INTO public.trip (
    customer_id, driver_id, service_type, pickup_location_id,
    dropoff_location_id, requested_at, status, fare_amount, currency,
    started_at, completed_at
) VALUES
    (
        (SELECT customer_id FROM public.customer WHERE email = 'ama.mensah@example.test'),
        (SELECT driver_id FROM public.driver WHERE license_number = 'GH-LIC-2001'),
        'delivery',
        (SELECT location_id FROM public.location WHERE label = 'Osu pickup'),
        (SELECT location_id FROM public.location WHERE label = 'Market delivery'),
        '2026-10-10 09:00:00+00', 'delivered', 25.00, 'GHS',
        '2026-10-10 09:20:00+00', '2026-10-10 09:42:00+00'
    ),
    (
        (SELECT customer_id FROM public.customer WHERE email = 'kojo.asare@example.test'),
        (SELECT driver_id FROM public.driver WHERE license_number = 'GH-LIC-2002'),
        'ride',
        (SELECT location_id FROM public.location WHERE label = 'Airport pickup'),
        (SELECT location_id FROM public.location WHERE label = 'Labone drop-off'),
        '2026-10-10 11:00:00+00', 'completed', 18.00, 'GHS',
        '2026-10-10 11:05:00+00', '2026-10-10 11:35:00+00'
    );

INSERT INTO public.trip_status_history (trip_id, status, changed_at, note)
SELECT t.trip_id, events.status, events.changed_at, events.note
FROM (VALUES
    ('ama.mensah@example.test', 'requested', '2026-10-10 09:00:00+00'::timestamptz, 'Delivery requested'),
    ('ama.mensah@example.test', 'matched', '2026-10-10 09:03:00+00'::timestamptz, 'Driver assigned'),
    ('ama.mensah@example.test', 'picked_up', '2026-10-10 09:20:00+00'::timestamptz, 'Parcel collected'),
    ('ama.mensah@example.test', 'delivered', '2026-10-10 09:42:00+00'::timestamptz, 'Parcel handed to recipient'),
    ('kojo.asare@example.test', 'requested', '2026-10-10 11:00:00+00'::timestamptz, 'Ride requested'),
    ('kojo.asare@example.test', 'matched', '2026-10-10 11:02:00+00'::timestamptz, 'Driver assigned'),
    ('kojo.asare@example.test', 'in_progress', '2026-10-10 11:05:00+00'::timestamptz, 'Passenger pickup'),
    ('kojo.asare@example.test', 'completed', '2026-10-10 11:35:00+00'::timestamptz, 'Ride completed')
) AS events(customer_email, status, changed_at, note)
JOIN public.customer c ON c.email = events.customer_email
JOIN public.trip t ON t.customer_id = c.customer_id;

INSERT INTO public.payment (
    trip_id, amount, currency, method, status, provider_reference, created_at
)
SELECT t.trip_id, p.amount, 'GHS', p.method, p.status, p.provider_reference, p.created_at
FROM (VALUES
    ('ama.mensah@example.test', 25.00::numeric, 'mobile_money', 'succeeded', 'PAY-DEMO-501', '2026-10-10 09:45:00+00'::timestamptz),
    ('kojo.asare@example.test', 18.00::numeric, 'card', 'failed', 'PAY-DEMO-502-A', '2026-10-10 11:36:00+00'::timestamptz),
    ('kojo.asare@example.test', 18.00::numeric, 'wallet', 'succeeded', 'PAY-DEMO-502-B', '2026-10-10 11:38:00+00'::timestamptz)
) AS p(customer_email, amount, method, status, provider_reference, created_at)
JOIN public.customer c ON c.email = p.customer_email
JOIN public.trip t ON t.customer_id = c.customer_id;

COMMIT;

-- Optional record-count check after the commit.
SELECT 'customer' AS table_name, COUNT(*) AS row_count FROM public.customer
UNION ALL SELECT 'driver', COUNT(*) FROM public.driver
UNION ALL SELECT 'location', COUNT(*) FROM public.location
UNION ALL SELECT 'trip', COUNT(*) FROM public.trip
UNION ALL SELECT 'trip_status_history', COUNT(*) FROM public.trip_status_history
UNION ALL SELECT 'payment', COUNT(*) FROM public.payment;
