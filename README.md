# PGStac
PGDatabase Schema and Functions for Storing and Accessing STAC collections and items in PostgreSQL

Stac Client that uses PGStac available in [Stac FastAPI](https://github.com/stac-utils/stac-fastapi)

PGStac requires Postgresql>=12, PostGIS>=3, and PG_Partman. Best performance will be had using PostgreSQL>=13 and PostGIS>=3.1.


## PyPGStac
PGStac includes a Python utility for bulk data loading and managing migrations.

PyPGStac is available on PyPI
```
pip install pypgstac
```
Or can be built locally using Poetry
```
cd pypgstac
poetry build pypgstac
pip install dist/pypgstac-[version]-py3-none-any.whl
```
PyPGStac will get the database connection settings from the standard PG environment variables. It can also take a DSN database url "postgresql://..." via the --dsn flag.
 - PGHOST
 - PGPORT
 - PGUSER
 - PGDATABASE
 - PGPASSWORD

## Making Changes to SQL
All changes to SQL should only be made in the sql directory. SQL Files will be run in alphabetical order.

## Adding Tests
PGStac uses PGTap to test SQL. Tests can be found in tests/pgtap.sql and are run using `scripts/test`


## Migrations
PyPGStac has a utility to help apply migrations to an existing PGStac instance to bring it up to date.

Migrations are stored in pypgstac/pypgstac/migrations and are distributed with the PyPGStac package. There are two types of migrations.
 - Base migrations install PGStac into a database with no current PGStac installation. These migrations follow the file pattern "pgstac.[version].sql"
 - Incremental migrations are used to move PGStac from one version to the next. These migrations follow the file pattern "pgstac.[version].[fromversion].sql"

These migrations can be created when releasing a new version of PGStac using"
```
scripts/stageversion [version or increment type]
```
Examples:
```
scripts/stageversion 0.2.8
scripts/stageversion patch # if current version is 0.2.7 will bump to 0.2.8
scripts/stageversion minor # if current version is 0.2.7 will bump to 0.3.0
scripts/stageversion major # if current version is 0.2.7 will bump to 1.0.0
```
This will create a base migration for the new version and will create incremental migrations between any existing base migrations. The incremental migrations that are automatically generated by this script will have the extension ".staged" on the file. You must manually review (and make any modifications necessary) this file and remove the ".staged" extension to enable the migration.

### Running Migrations
PyPGStac has a utility for checking the version of an existing PGStac database and applying the appropriate migrations in the correct order. It can also be used to setup a database from scratch.

To create an initial PGStac database or bring an existing one up to date:
```
pypgstac migrate
```

## Bulk Data Loading
A python utility is included which allows to load data from any source openable by smart-open using python in a memory efficient streaming manner using PostgreSQL copy. There are options for collections and items and can be used either as a command line or a library.

To load an ndjson of items directly using copy (will fail on any duplicate ids but is the fastest option to load new data you know will not conflict)
```
pypgstac load items
```

To load skipping any records that conflict with existing data
```
pypgstac load items --method insert_ignore
```

To upsert any records, adding anything new and replacing anything with the same id
```
pypgstac load items --method upsert
```

## Development

PGStac uses a dockerized development environment. You can set this up using:

```bash
scripts/setup
```

To bring up the development database:
```
scripts/server
```

To run tests, use:
```bash
scripts/test
```

To rebuild docker images:
```bash
scripts/update
```

To drop into a console, use
```bash
scripts/console
```

To drop into a psql console on the database container, use:
```bash
scripts/console --db
```

To run migrations on the development database, use
```bash
scripts/migrate
```

To stage code and configurations and create template migrations for a version release, use
```bash
scripts/stageversion
```

## Release Process
1) Make sure all your code is added and committed
2) Create a PR against the main branch
3) Once the PR has been merged, start the release process.
4) Use `scripts/stagerelease` as documented in migrations section above making sure to rename any files ending in ".staged" in the migrations section
5) Add details for release to the CHANGELOG
6) Add/Commit any changes
7) Run tests `scripts/test`
8) Create a git tag `git tag v0.2.8` using new version number
9) Push the git tag `git push origin v0.2.8`
10) The CI process will push pypgstac to PyPi, create a docker image on ghcr.io, and create a release on github.
