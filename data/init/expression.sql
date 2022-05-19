CREATE TABLE expression(
    id INTEGER PRIMARY KEY,
    kanji STRING,
    reading STRING
);

CREATE INDEX idx_kanji ON expression(kanji);
CREATE INDEX idx_reading ON expression(reading);

CREATE TABLE sense(
    id INTEGER PRIMARY KEY,
    id_expression INTEGER,
    pos STRING,
    FOREIGN KEY(id_expression) REFERENCES expression(id)
);

CREATE TABLE gloss(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_sense INTEGER,
    gloss STRING,
    lang STRING,
    FOREIGN KEY(id_sense) REFERENCES sense(id)
);