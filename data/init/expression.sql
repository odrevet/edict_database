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
    lang STRING,
    FOREIGN KEY(id_expression) REFERENCES expression(id)
);

CREATE TABLE gloss(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_sense INTEGER,
    gloss STRING,
    FOREIGN KEY(id_sense) REFERENCES sense(id)
);

CREATE TABLE pos(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name STRING,
    description STRING
);

CREATE TABLE sense_pos(
    id_sense INTEGER,
    id_pos INTEGER,
    FOREIGN KEY(id_sense) REFERENCES sense(id),
    FOREIGN KEY(id_pos) REFERENCES pos(id),
    PRIMARY KEY (id_sense, id_pos)
);