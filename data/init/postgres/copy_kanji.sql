-- Import lang table first (referenced by other tables)
\copy lang FROM 'data/generated/csv/kanji/lang.csv' WITH (FORMAT csv, HEADER true);

-- Import character-radical relations
\copy character_radical FROM 'data/generated/csv/kanji/character_radical.csv' WITH (FORMAT csv, HEADER true);

-- Import on_yomi readings
\copy on_yomi FROM 'data/generated/csv/kanji/on_yomi.csv' WITH (FORMAT csv, HEADER true);

-- Import kun_yomi readings
\copy kun_yomi FROM 'data/generated/csv/kanji/kun_yomi.csv' WITH (FORMAT csv, HEADER true);

-- Import meanings
\copy meaning FROM 'data/generated/csv/kanji/meaning.csv' WITH (FORMAT csv, HEADER true);