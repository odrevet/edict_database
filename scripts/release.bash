#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

EXPRESSION_LANGS="eng,fre,ger,rus,hun,dut,spa,swe,slv"
EXPRESSION_PRIMARY="eng"
KANJI_LANGS="en,es,fr,pt"
KANJI_PRIMARY="en"

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
    local type="$1" langs="$2" suffix="$3"

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

capture_csv_reference() {
    local type="$1"
    local ref="data/generated/.csv_ref_${type}"
    rm -rf "$ref"
    mkdir -p "$ref"
    for f in "$CSV_DIR/${type}"/*.csv; do
        [[ -f "$f" ]] || continue
        head -n1 "$f" > "$ref/$(basename "$f")"
    done
}

ensure_csv_files() {
    local type="$1"
    local ref="data/generated/.csv_ref_${type}"
    [[ -d "$ref" ]] || return 0
    for f in "$ref"/*; do
        local name="$(basename "$f")"
        [[ -f "$CSV_DIR/${type}/${name}" ]] || cp "$f" "$CSV_DIR/${type}/${name}"
    done
}

build_postgres() {
    local type="$1" langs="$2" suffix="$3"
    local schema_name="${type}${suffix}"

    bash scripts/run.bash "$type" --clean --csv "$langs"

    if [[ "$suffix" == "_all" ]]; then
        capture_csv_reference "$type"
    else
        ensure_csv_files "$type"
    fi

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

bundle_other() {
    local type="$1"; shift
    local other_langs=("$@")
    local stage="data/generated/stage_${type}_other"

    rm -rf "$stage"
    mkdir -p "$stage/sqlite" "$stage/postgres" "$stage/csv" "$stage/sql"

    for lang in "${other_langs[@]}"; do
        mkdir -p "$stage/sqlite/$lang" "$stage/postgres/$lang" "$stage/sql/$lang"

        mv "$SQLITE_DIR/sqlite_${type}_${lang}.db" "$stage/sqlite/$lang/"
        rm -f "$SQLITE_DIR/sqlite_${type}_${lang}.zip" "$SQLITE_DIR/sqlite_${type}_${lang}.xz"

        mv "$POSTGRES_DIR/postgres_${type}_${lang}.sql.gz" "$stage/postgres/$lang/"
        mv "$POSTGRES_DIR/postgres_${type}_${lang}.dump.gz" "$stage/postgres/$lang/"

        unzip -q "$CSV_DIR/csv_${type}_${lang}.zip" -d "$stage/csv_tmp"
        mv "$stage/csv_tmp/${type}_${lang}" "$stage/csv/$lang"
        rm -rf "$stage/csv_tmp"
        rm -f "$CSV_DIR/csv_${type}_${lang}.zip"

        mv "$SQL_DIR/sql_${type}_${lang}.sql.gz" "$stage/sql/$lang/"
    done

    (cd "$stage/sqlite" && zip -rq "$ROOT_DIR/$SQLITE_DIR/sqlite_${type}_other.zip" .)
    (cd "$stage/postgres" && zip -rq "$ROOT_DIR/$POSTGRES_DIR/postgres_${type}_other.zip" .)
    (cd "$stage/csv" && zip -rq "$ROOT_DIR/$CSV_DIR/csv_${type}_other.zip" .)
    (cd "$stage/sql" && zip -rq "$ROOT_DIR/$SQL_DIR/sql_${type}_other.zip" .)

    rm -rf "$stage"
}

count_zip_csv_rows() {
    local zipfile="$1" inner="$2"
    unzip -p "$zipfile" "$inner" 2>/dev/null | { c=$(wc -l); echo $((c > 0 ? c - 1 : 0)); }
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
        echo "- Entries: $(count_zip_csv_rows "$CSV_DIR/csv_expression_all.zip" "*/entry.csv")"
        echo "- Senses: $(count_zip_csv_rows "$CSV_DIR/csv_expression_all.zip" "*/sense.csv")"
        echo "- Glosses: $(count_zip_csv_rows "$CSV_DIR/csv_expression_all.zip" "*/gloss.csv")"
        echo ""
        echo "## Expression per language (glosses)"
        echo "| Language | Glosses |"
        echo "|---|---|"
        for lang in ${EXPRESSION_LANGS//,/ }; do
            if [[ "$lang" == "$EXPRESSION_PRIMARY" ]]; then
                echo "| $lang | $(count_zip_csv_rows "$CSV_DIR/csv_expression_${lang}.zip" "*/gloss.csv") |"
            else
                echo "| $lang | $(count_zip_csv_rows "$CSV_DIR/csv_expression_other.zip" "${lang}/gloss.csv") |"
            fi
        done
        echo ""
        echo "## Kanji (all languages)"
        echo "- Characters: $(count_zip_csv_rows "$CSV_DIR/csv_kanji_all.zip" "*/character.csv")"
        echo "- Meanings: $(count_zip_csv_rows "$CSV_DIR/csv_kanji_all.zip" "*/meaning.csv")"
        echo ""
        echo "## Kanji per language (meanings)"
        echo "| Language | Meanings |"
        echo "|---|---|"
        for lang in ${KANJI_LANGS//,/ }; do
            if [[ "$lang" == "$KANJI_PRIMARY" ]]; then
                echo "| $lang | $(count_zip_csv_rows "$CSV_DIR/csv_kanji_${lang}.zip" "*/meaning.csv") |"
            else
                echo "| $lang | $(count_zip_csv_rows "$CSV_DIR/csv_kanji_other.zip" "${lang}/meaning.csv") |"
            fi
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
rm -rf data/generated/.csv_ref_expression data/generated/.csv_ref_kanji

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

echo "==> Primary language database (expression: $EXPRESSION_PRIMARY)"
build_sqlite expression "$EXPRESSION_PRIMARY" "_$EXPRESSION_PRIMARY"
build_postgres expression "$EXPRESSION_PRIMARY" "_$EXPRESSION_PRIMARY"

echo "==> Primary language database (kanji: $KANJI_PRIMARY)"
build_sqlite kanji "$KANJI_PRIMARY" "_$KANJI_PRIMARY"
build_postgres kanji "$KANJI_PRIMARY" "_$KANJI_PRIMARY"

echo "==> Other languages (expression)"
EXPRESSION_OTHERS=()
for lang in ${EXPRESSION_LANGS//,/ }; do
    [[ "$lang" == "$EXPRESSION_PRIMARY" ]] && continue
    build_sqlite expression "$lang" "_$lang"
    build_postgres expression "$lang" "_$lang"
    EXPRESSION_OTHERS+=("$lang")
done
bundle_other expression "${EXPRESSION_OTHERS[@]}"

echo "==> Other languages (kanji)"
KANJI_OTHERS=()
for lang in ${KANJI_LANGS//,/ }; do
    [[ "$lang" == "$KANJI_PRIMARY" ]] && continue
    build_sqlite kanji "$lang" "_$lang"
    build_postgres kanji "$lang" "_$lang"
    KANJI_OTHERS+=("$lang")
done
bundle_other kanji "${KANJI_OTHERS[@]}"

echo "==> Release notes"
generate_release_notes

echo "==> Tests"
bash scripts/test_db.bash "$SQLITE_DIR" "$POSTGRES_CONTAINER" "$POSTGRES_DB"

echo "==> Done"