Place versioned SQL migration files here.

Naming convention: 00X.sql or 0XX.sql where X is the target schema version number.

Example:
- 002.sql  -- alters/tables to migrate from v1 to v2
- 003.sql  -- migrate from v2 to v3

DatabaseHelper._migrate() will attempt to load each file from (oldVersion+1) up to newVersion and execute statements in groups.

