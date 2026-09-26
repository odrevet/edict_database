#!/usr/bin/env bash
set -euo pipefail

EXPRESSION_LANGS="eng,fre,ger,rus,hun,dut,spa,swe,slv"
KANJI_LANGS="en,es,fr,pt"

POSTGRES_CONTAINER="postgres-container"
POSTGRES_DB="edict"
RAW_DB_DIR="data/generated/db"
SQLITE_DIR="data/generated/db/sqlite"
POSTGRES_DIR="data/generated/db/postgres"
SQL_DIR="data/generated/sql"
CSV_DIR="data/generated/csv"
RELEASE_NOTES="data/generated/RELEASE.md"

start_postgres() {
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
        docker run -v "$(pwd):/workspace" \
            --name "$POSTGRES_CONTAINER" \
            -e POSTGRES_HOST_AUTH_METHOD=trust \
            -e POSTGRES_DB="$POSTGRES_DB" \
            -p 5432:5432 \
            -d postgres
        sleep 5
    else
        docker start "$POSTGRES_CONTAINER"
    fi
}

psql_exec() {
    docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d "$POSTGRES_DB" "$@"
}

build_sqlite() {
    local type="$1" langs="$2" suffix="${3:-_all}"

    bash scripts/run.bash "$type" --clean --sql "$langs"
    bash scripts/sqlite.bash "$type" --clean --init --populate --compress "zip" --compress "xz"

    mkdir -p "$SQLITE_DIR"
    mv "$RAW_DB_DIR/${type}.db" "$SQLITE_DIR/sqlite_${type}${suffix}.db"
    [[ -f "$RAW_DB_DIR/${type}.zip" ]] && mv "$RAW_DB_DIR/${type}.zip" "$SQLITE_DIR/sqlite_${type}${suffix}.zip"
    [[ -f "$RAW_DB_DIR/${type}.xz" ]] && mv "$RAW_DB_DIR/${type}.xz" "$SQLITE_DIR/sqlite_${type}${suffix}.xz"

    if [[ -f "$SQL_DIR/${type}.sql" ]]; then
        mv "$SQL_DIR/${type}.sql" "$SQL_DIR/sql_${type}${suffix}.sql"
        gzip -f "$SQL_DIR/sql_${type}${suffix}.sql"
    fi
}

build_postgres() {
    local type="$1" langs="$2" suffix="${3:-_all}"
    local schema_name="${type}${suffix}"

    bash scripts/run.bash "$type" --clean --csv "$langs"

    docker exec -i -w /workspace "$POSTGRES_CONTAINER" \
        bash scripts/postgres.bash "$type" --clean --init --populate

    psql_exec -c "DROP SCHEMA IF EXISTS ${schema_name} CASCADE;"
    psql_exec -c "ALTER SCHEMA ${type} RENAME TO ${schema_name};"

    if [[ -d "$CSV_DIR/${type}" ]]; then
        rm -rf "$CSV_DIR/${type}${suffix}"
        mv "$CSV_DIR/${type}" "$CSV_DIR/${type}${suffix}"
        (cd "$CSV_DIR" && zip -rq "csv_${type}${suffix}.zip" "${type}${suffix}")
        rm -rf "$CSV_DIR/${type}${suffix}"
    fi

    mkdir -p "$POSTGRES_DIR"
    docker exec -i "$POSTGRES_CONTAINER" pg_dump -U postgres -d "$POSTGRES_DB" --schema="$schema_name" -F p \
        > "$POSTGRES_DIR/postgres_${schema_name}.sql"
    gzip -f "$POSTGRES_DIR/postgres_${schema_name}.sql"

    docker exec -i "$POSTGRES_CONTAINER" pg_dump -U postgres -d "$POSTGRES_DB" --schema="$schema_name" -F c \
        > "$POSTGRES_DIR/postgres_${schema_name}.dump"
    gzip -f "$POSTGRES_DIR/postgres_${schema_name}.dump"
}

count_zip_csv_rows() {
    local zipfile="$1" entry="$2"
    unzip -p "$zipfile" "*/${entry}" 2>/dev/null | { c=$(wc -l); echo $((c > 0 ? c - 1 : 0)); }
}

generate_release_notes() {
    local jmdict_date jmdict_line kanjidic_version kanjidic_date

    jmdict_line=$(grep -m1 "JMdict created" data/JMdict || true)
    jmdict_date=$(echo "$jmdict_line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "unknown")

    kanjidic_version=$(grep -m1 -oE '<database_version>.*</database_version>' data/kanjidic2.xml | sed -E 's/<[^>]+>//g' || echo "unknown")
    kanjidic_date=$(grep -m1 -oE '<date_of_creation>.*</date_of_creation>' data/kanjidic2.xml | sed -E 's/<[^>]+>//g' || echo "unknown")

    {
        echo "# Release notes"
        echo ""
        echo "Generated: $(date -u +%Y-%m-%d)"
        echo ""
        echo "## Sources"
        echo "- JMdict created: $jmdict_date"
        echo "- KANJIDIC2 version: $kanjidic_version, created: $kanjidic_date"
        echo ""
        echo "## Expression (all languages)"
        echo "- Entries: $(count_zip_csv_rows "$CSV_DIR/csv_expression_all.zip" entry.csv)"
        echo "- Senses: $(count_zip_csv_rows "$CSV_DIR/csv_expression_all.zip" sense.csv)"
        echo "- Glosses: $(count_zip_csv_rows "$CSV_DIR/csv_expression_all.zip" gloss.csv)"
        echo ""
        echo "## Expression per language (glosses)"
        echo "| Language | Glosses |"
        echo "|---|---|"
        for lang in ${EXPRESSION_LANGS//,/ }; do
            echo "| $lang | $(count_zip_csv_rows "$CSV_DIR/csv_expression_${lang}.zip" gloss.csv) |"
        done
        echo ""
        echo "## Kanji (all languages)"
        echo "- Characters: $(count_zip_csv_rows "$CSV_DIR/csv_kanji_all.zip" character.csv)"
        echo "- Meanings: $(count_zip_csv_rows "$CSV_DIR/csv_kanji_all.zip" meaning.csv)"
        echo ""
        echo "## Kanji per language (meanings)"
        echo "| Language | Meanings |"
        echo "|---|---|"
        for lang in ${KANJI_LANGS//,/ }; do
            echo "| $lang | $(count_zip_csv_rows "$CSV_DIR/csv_kanji_${lang}.zip" meaning.csv) |"
        done
    } > "$RELEASE_NOTES"
}

clean_dir_keep_readme() {
    local dir="$1"
    [[ -d "$dir" ]] || { mkdir -p "$dir"; return; }
    find "$dir" -mindepth 1 -not -name "README.md" -exec rm -rf {} +
}

echo "==> Clean previous outputs"
clean_dir_keep_readme "$SQLITE_DIR"
clean_dir_keep_readme "$POSTGRES_DIR"
clean_dir_keep_readme "$CSV_DIR"
clean_dir_keep_readme "$SQL_DIR"
rm -f "$RELEASE_NOTES"

echo "==> Download sources"
rm -f data/JMdict data/JMdict.gz data/kanjidic2.xml data/kanjidic2.xml.gz
bash scripts/run.bash expression --download
bash scripts/run.bash kanji --download

echo "==> Start PostgreSQL"
start_postgres

echo "==> Global database (expression: all langs)"
build_sqlite expression "$EXPRESSION_LANGS" "_all"
build_postgres expression "$EXPRESSION_LANGS" "_all"

echo "==> Global database (kanji: all langs)"
build_sqlite kanji "$KANJI_LANGS" "_all"
build_postgres kanji "$KANJI_LANGS" "_all"

echo "==> Per language databases (expression)"
for lang in ${EXPRESSION_LANGS//,/ }; do
    build_sqlite expression "$lang" "_$lang"
    build_postgres expression "$lang" "_$lang"
done

echo "==> Per language databases (kanji)"
for lang in ${KANJI_LANGS//,/ }; do
    build_sqlite kanji "$lang" "_$lang"
    build_postgres kanji "$lang" "_$lang"
done

echo "==> Release notes"
generate_release_notes

echo "==> Tests"
bash scripts/test_db.bash "$SQLITE_DIR" "$POSTGRES_CONTAINER" "$POSTGRES_DB"

echo "==> Done"