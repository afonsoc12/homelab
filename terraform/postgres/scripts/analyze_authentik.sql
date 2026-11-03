\set ON_ERROR_STOP on

-- Refuse to run against any other database, including the administration DB.
DO $guard$
BEGIN
  IF current_database() <> 'authentik' THEN
    RAISE EXCEPTION 'Expected the authentik database; refusing statistics refresh';
  END IF;
END
$guard$;

SET lock_timeout = '3s';
SET statement_timeout = '120s';

ANALYZE;
