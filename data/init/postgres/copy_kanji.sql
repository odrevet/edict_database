-- Import lang table first (referenced by other tables)
\copy kanji.lang FROM 'data/generated/csv/kanji/lang.csv' WITH (FORMAT csv, HEADER true);

-- Import character-radical relations
\copy kanji.character_radical FROM 'data/generated/csv/kanji/character_radical.csv' WITH (FORMAT csv, HEADER true);

-- Import on_yomi readings
\copy kanji.on_yomi FROM 'data/generated/csv/kanji/on_yomi.csv' WITH (FORMAT csv, HEADER true);

-- Import kun_yomi readings
\copy kanji.kun_yomi FROM 'data/generated/csv/kanji/kun_yomi.csv' WITH (FORMAT csv, HEADER true);

-- Import meanings
\copy kanji.meaning FROM 'data/generated/csv/kanji/meaning.csv' WITH (FORMAT csv, HEADER true);