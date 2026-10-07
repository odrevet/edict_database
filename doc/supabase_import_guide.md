# Import data into Supabase Postgres with psql (Linux)

Values in `<ANGLE_BRACKETS>` are placeholders: replace them with your own.

## Get the connection info from Supabase

1. Open the project dashboard.
2. Click **Connect** at the top, then the **Direct** tab (Connection string).
3. Pick **Session pooler**
4. The URI looks like:

```
postgresql://postgres.<PROJECT_REF>:<PASSWORD>@aws-0-<REGION>.pooler.supabase.com:5432/postgres
```

Split into parts:

| Part | Value |
|------|-------|
| Host | `aws-0-<REGION>.pooler.supabase.com` |
| Port | `5432` |
| Database | `postgres` |
| User | `postgres.<PROJECT_REF>` |
| Password | `<PASSWORD>` (Settings > Database > Reset database password) |

## Install the PostgreSQL client

```bash
sudo apt install postgresql-client

psql --version
pg_restore --version
```

## Configure the connection

Two files in your home directory: `~/.pgpass` stores the password, `~/.pg_service.conf` stores the connection parameters under a name. Together they make a plain `psql` work from any terminal, with no `export` and no password on the command line.

### `~/.pgpass` (password)

Format, one line per connection:

```
hostname:port:database:username:password
```

```bash
cat > ~/.pgpass <<'EOF'
aws-0-<REGION>.pooler.supabase.com:5432:postgres:postgres.<PROJECT_REF>:<PASSWORD>
EOF
chmod 600 ~/.pgpass     # required, otherwise ignored
```

psql uses the first line matching the host, port, database and user of the connection. `*` is a wildcard, and a literal `:` or `\` in a field must be escaped with a backslash. One line per instance if you have several.

### `~/.pg_service.conf` (host, port, user, database)

```bash
cat > ~/.pg_service.conf <<'EOF'
[edict]
host=aws-0-<REGION>.pooler.supabase.com
port=5432
dbname=postgres
user=postgres.<PROJECT_REF>
EOF
```

Do not put the password here, `~/.pgpass` supplies it.

Use the service by name:

```bash
psql service=edict -c "\conninfo"
```

Or make it the default for every terminal, so that a plain `psql` targets Supabase:

```bash
echo 'export PGSERVICE=edict' >> ~/.bashrc    # or ~/.zshrc
source ~/.bashrc
```

Several databases: add one section per instance (`[local]`, `[other-project]`, ...) and choose with `psql service=<name>`.

Without the service file, the same connection with flags:

```bash
psql -h aws-0-<REGION>.pooler.supabase.com -p 5432 -U postgres.<PROJECT_REF> -d postgres
```

## Create the tables

```bash
psql service=edict -v ON_ERROR_STOP=1 -f data/init/postgres/expression.sql
psql service=edict -v ON_ERROR_STOP=1 -f data/init/postgres/kanji.sql
```

Alternative: paste the SQL in the dashboard SQL Editor.

## Extract the generated CSV archives

The generated CSV files are shipped zipped. Extract the archive as the `expression` folder, because the import script reads `data/generated/csv/expression/*.csv`.

Two archives exist (use only one):
- `csv_expression_all.zip`: all languages
- `csv_expression_eng.zip`: English only

Run these commands from the project root. The archives are in `data/generated/csv/`.

```bash
# all languages
unzip -j data/generated/csv/csv_expression_all.zip -d data/generated/csv/expression
# or English only
unzip -j data/generated/csv/csv_expression_eng.zip -d data/generated/csv/expression

ls data/generated/csv/expression   # should list entry.csv, gloss.csv, k_ele.csv, ...
```

`-j` ignores the folders stored inside the zip, so all `.csv` files end up directly in `expression/` whatever the archive layout. Removing the folder first avoids mixing files from the two archives.

## Import CSV files

```bash
psql service=edict -v ON_ERROR_STOP=1 -f data/init/postgres/copy_expression.sql
psql service=edict -v ON_ERROR_STOP=1 -f data/init/postgres/copy_kanji.sql
```

## Reset the tables (start over)

If an import fails halfway, or you want to reload everything, empty the tables first. Otherwise you get `duplicate key value violates unique constraint` errors.

Check which database you are connected to before any destructive command:

```bash
psql service=edict -c "\conninfo"
```

Empty every table of the `expression` schema
```bash
psql service=edict -c "DO \$\$ DECLARE r record; BEGIN FOR r IN SELECT tablename FROM pg_tables WHERE schemaname='expression' LOOP EXECUTE format('TRUNCATE TABLE expression.%I RESTART IDENTITY CASCADE', r.tablename); END LOOP; END \$\$;"
```

## Activate RLS, enable read only

```sql
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN ('expression', 'kanji')
  LOOP
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', r.schemaname, r.tablename);
    EXECUTE format('DROP POLICY IF EXISTS "public read" ON %I.%I', r.schemaname, r.tablename);
    EXECUTE format('CREATE POLICY "public read" ON %I.%I FOR SELECT TO anon, authenticated USING (true)', r.schemaname, r.tablename);
  END LOOP;
END $$;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA expression FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA kanji FROM anon, authenticated;
```

## Expose the data through the REST API

- Tables in `public` are exposed automatically. Other schemas must be added in Settings > API > **Exposed schemas**.
- Grant access to the API roles:

```sql
GRANT USAGE ON SCHEMA expression TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA expression TO anon, authenticated;
```

- Row Level Security: enable it on each table and add policies, otherwise the `anon` key sees nothing (RLS on, no policy) or everything (RLS off).
- Endpoint: `https://<PROJECT_REF>.supabase.co/rest/v1/<table>`
- Headers: `apikey: <ANON_KEY>` (and `Accept-Profile: expression` to target a non-public schema).