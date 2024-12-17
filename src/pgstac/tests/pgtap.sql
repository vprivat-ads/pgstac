\unset ECHO
\set QUIET 1
-- Turn off echo and keep things quiet.

-- Format the output for nice TAP.
\pset format unaligned
\pset tuples_only true
\pset pager off
\timing off

-- Revert all changes on failure.
\set ON_ERROR_STOP true

-- Load the TAP functions.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap;
CREATE EXTENSION IF NOT EXISTS plpgsql_check;
SET SEARCH_PATH TO pgstac, pgtap, public;

-- Lint check of plpsql functions
-- https://github.com/okbob/plpgsql_check?tab=readme-ov-file#checking-all-of-your-code

-- check all plpgsql functions (functions or trigger functions with defined triggers)
SELECT
    (pcf).functionid::regprocedure, (pcf).lineno, (pcf).statement,
    (pcf).sqlstate, (pcf).message, (pcf).detail, (pcf).hint, (pcf).level,
    (pcf)."position", (pcf).query, (pcf).context
FROM
(
    SELECT
        plpgsql_check_function_tb(pg_proc.oid, COALESCE(pg_trigger.tgrelid, 0)) AS pcf
    FROM pg_proc
    LEFT JOIN pg_trigger
        ON (pg_trigger.tgfoid = pg_proc.oid)
    WHERE
        prolang = (SELECT lang.oid FROM pg_language lang WHERE lang.lanname = 'plpgsql') AND
        pronamespace = (SELECT nsp.oid FROM pg_namespace nsp WHERE nsp.nspname = 'pgstac') AND
        -- ignore unused triggers
        (pg_proc.prorettype <> (SELECT typ.oid FROM pg_type typ WHERE typ.typname = 'trigger') OR
         pg_trigger.tgfoid IS NOT NULL)
    OFFSET 0
) ss
ORDER BY (pcf).functionid::regprocedure::text, (pcf).lineno;

-- Plan the tests.
SELECT plan(229);
--SELECT * FROM no_plan();

-- Run the tests.

-- Core
\i tests/pgtap/001_core.sql
\i tests/pgtap/001a_jsonutils.sql
\i tests/pgtap/001b_cursorutils.sql
\i tests/pgtap/001s_stacutils.sql
\i tests/pgtap/002_collections.sql
\i tests/pgtap/002a_queryables.sql
\i tests/pgtap/003_items.sql
\i tests/pgtap/004_search.sql
\i tests/pgtap/004a_collectionsearch.sql
\i tests/pgtap/005_tileutils.sql
\i tests/pgtap/006_tilesearch.sql
\i tests/pgtap/999_version.sql

-- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK;
