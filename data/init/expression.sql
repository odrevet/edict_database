CREATE TABLE lang(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    iso3 STRING
);

CREATE TABLE expression(
    id INTEGER PRIMARY KEY,
    kanji STRING,
    reading STRING,
    priority_news INTEGER,
    priority_ichi INTEGER,
    priority_gai INTEGER,
    priority_nf INTEGER
);

CREATE INDEX idx_kanji ON expression(kanji);
CREATE INDEX idx_reading ON expression(reading);

CREATE TABLE sense(
    id INTEGER PRIMARY KEY,
    id_expression INTEGER,
    id_lang INTEGER,
    FOREIGN KEY(id_expression) REFERENCES expression(id),
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

CREATE TABLE re_inf(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name STRING,
    description STRING
);