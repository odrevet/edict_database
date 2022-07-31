CREATE TABLE lang(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    iso3 STRING
);

CREATE TABLE entry(
    id INTEGER PRIMARY KEY
);

CREATE TABLE reading(
    id INTEGER PRIMARY KEY,
    id_entry INTEGER,
    id_priority INTEGER,
    reading STRING,
    FOREIGN KEY(id_entry) REFERENCES entry(id),
    FOREIGN KEY(id_priority) REFERENCES priority(id)
);

CREATE INDEX idx_reading ON reading(reading);

CREATE TABLE kanji(
    id INTEGER PRIMARY KEY,
    id_entry INTEGER,
    id_priority INTEGER,
    kanji STRING,
    FOREIGN KEY(id_entry) REFERENCES entry(id),
    FOREIGN KEY(id_priority) REFERENCES priority(id)
);

CREATE INDEX idx_kanji ON kanji(kanji);

CREATE TABLE reading_kanji(
    id_reading INTEGER,
    id_kanji INTEGER,
    FOREIGN KEY(id_reading) REFERENCES reading(id),
    FOREIGN KEY(id_kanji) REFERENCES kanji(id),
    PRIMARY KEY (id_reading, id_kanji)
);

CREATE TABLE priority(
    id INTEGER PRIMARY KEY,
    news INTEGER,
    ichi INTEGER,
    gai INTEGER,
    nf INTEGER
);

CREATE TABLE sense(
    id INTEGER PRIMARY KEY,
    id_entry INTEGER,
    id_lang INTEGER,
    FOREIGN KEY(id_entry) REFERENCES entry(id),
    FOREIGN KEY(id_lang) REFERENCES lang(id)
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

CREATE TABLE misc(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name STRING,
    description STRING
);

CREATE TABLE sense_misc(
    id_sense INTEGER,
    id_misc INTEGER,
    FOREIGN KEY(id_sense) REFERENCES sense(id),
    FOREIGN KEY(id_misc) REFERENCES misc(id),
    PRIMARY KEY (id_sense, id_misc)
);

CREATE TABLE dial(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name STRING,
    description STRING
);

CREATE TABLE sense_dial(
    id_sense INTEGER,
    id_dial INTEGER,
    FOREIGN KEY(id_sense) REFERENCES sense(id),
    FOREIGN KEY(id_dial) REFERENCES dial(id),
    PRIMARY KEY (id_sense, id_dial)
);

CREATE TABLE ke_inf(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name STRING,
    description STRING
);

CREATE TABLE kanji_ke_inf(
    id_kanji INTEGER,
    id_ke_inf INTEGER,
    FOREIGN KEY(id_kanji) REFERENCES kanji(id),
    FOREIGN KEY(id_ke_inf) REFERENCES ke_inf(id),
    PRIMARY KEY (id_kanji, id_ke_inf)
);

CREATE TABLE re_inf(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name STRING,
    description STRING
);

CREATE TABLE reading_re_inf(
    id_reading INTEGER,
    id_re_inf INTEGER,
    FOREIGN KEY(id_reading) REFERENCES reading(id),
    FOREIGN KEY(id_re_inf) REFERENCES re_inf(id),
    PRIMARY KEY (id_reading, id_re_inf)
);
