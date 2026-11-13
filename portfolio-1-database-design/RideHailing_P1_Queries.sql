-- Operational query examples for the demo database.
-- Connect with psql and run examples separately as needed.

-- 1. Requests waiting for assignment.
SELECT trip_id, customer_id, service_type, pickup_location_id,
       dropoff_location_id, requested_at, fare_amount, currency
FROM public.trip
WHERE status = 'requested'
ORDER BY requested_at;

-- 2. Track a trip's status timeline. Replace 1 with a trip_id.
SELECT status, changed_at, note
FROM public.trip_status_history
WHERE trip_id = 1
ORDER BY changed_at, status_event_id;

-- 3. Review payment attempts and outcomes for a trip.
SELECT payment_id, amount, currency, method, status, provider_reference, created_at
FROM public.payment
WHERE trip_id = 1
ORDER BY created_at, payment_id;

-- 4. Completed work and successful collected payments by service type.
SELECT t.service_type, t.currency,
       COUNT(DISTINCT t.trip_id) AS completed_trip_count,
       COALESCE(SUM(p.amount), 0) AS successful_payment_total
FROM public.trip AS t
LEFT JOIN public.payment AS p
  ON p.trip_id = t.trip_id AND p.status = 'succeeded'
WHERE t.status IN ('completed', 'delivered')
GROUP BY t.service_type, t.currency
ORDER BY t.service_type, t.currency;

-- 5. Atomically match the oldest available request to a driver.
-- Run in psql; set the target driver's id first, e.g. \set driver_id 1
-- The row lock coordinates competing dispatchers. The partial unique index
-- is a final guard against assigning a driver who already has active work.
-- The update and history insert commit or roll back together.
-- \set driver_id 1
-- BEGIN;
-- WITH candidate AS (
--     SELECT trip_id
--     FROM public.trip
--     WHERE status = 'requested'
--     ORDER BY requested_at, trip_id
--     FOR UPDATE SKIP LOCKED
--     LIMIT 1
-- ), matched AS (
--     UPDATE public.trip AS t
--     SET driver_id = :driver_id, status = 'matched'
--     FROM candidate AS c
--     WHERE t.trip_id = c.trip_id
--       AND NOT EXISTS (
--           SELECT 1 FROM public.trip AS active
--           WHERE active.driver_id = :driver_id
--             AND active.status IN ('matched', 'driver_arrived', 'in_progress', 'picked_up')
--       )
--     RETURNING t.trip_id, t.status
-- )
-- INSERT INTO public.trip_status_history (trip_id, status, note)
-- SELECT trip_id, status, 'Driver assigned by dispatch'
-- FROM matched
-- RETURNING trip_id, status, changed_at;
-- COMMIT;
