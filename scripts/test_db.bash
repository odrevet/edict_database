#!/usr/bin/env bash
set -uo pipefail

DB_DIR="${1:-data/generated/db}"
POSTGRES_CONTAINER="${2:-postgres-container}"
POSTGRES_DB="${3:-edict}"
ERRORS=0

test_sqlite() {
    local file="$1" table="$2" output

    output=$(sqlite3 "$file" "SELECT COUNT(*) FROM $table;" 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "OK   sqlite  $file"
    else
        echo "FAIL sqlite  $file (SELECT COUNT(*) FROM $table)"
        echo "     $output"
        ERRORS=$((ERRORS + 1))
    fi
}

test_postgres_schema() {
    local schema="$1" table="$2" output

    output=$(docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d "$POSTGRES_DB" \
        -c "SELECT COUNT(*) FROM \"${schema}\".${table};" 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "OK   postgres ${POSTGRES_DB}.${schema}"
    else
        echo "FAIL postgres ${POSTGRES_DB}.${schema} (SELECT COUNT(*) FROM ${schema}.${table})"
        echo "     $output"
        ERRORS=$((ERRORS + 1))
    fi
}

for f in "$DB_DIR"/expression*.db; do
    [[ -f "$f" ]] && test_sqlite "$f" entry
done

for f in "$DB_DIR"/kanji*.db; do
    [[ -f "$f" ]] && test_sqlite "$f" character
done

for schema in $(docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d "$POSTGRES_DB" -tAc \
    "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'expression%';"); do
    test_postgres_schema "$schema" entry
done

for schema in $(docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d "$POSTGRES_DB" -tAc \
    "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'kanji%';"); do
    test_postgres_schema "$schema" character
done

if [[ "$ERRORS" -gt 0 ]]; then
    echo "$ERRORS test(s) failed"
    exit 1
fi
echo "All tests passed"