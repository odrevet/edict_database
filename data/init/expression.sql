CREATE TABLE lang(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    iso3 STRING
);

CREATE TABLE entry(
    id INTEGER PRIMARY KEY
);

CREATE TABLE r_ele(
    id INTEGER PRIMARY KEY,
    id_entry INTEGER,
    id_pri INTEGER,
    reb STRING,
    FOREIGN KEY(id_entry) REFERENCES entry(id),
    FOREIGN KEY(id_pri) REFERENCES pri(id)
);

CREATE INDEX idx_reb ON r_ele(reb);

CREATE TABLE k_ele(
    id INTEGER PRIMARY KEY,
    id_entry INTEGER,
    id_r_ele INTEGER,
    id_pri INTEGER,
    keb STRING,
    FOREIGN KEY(id_entry) REFERENCES entry(id),
    FOREIGN KEY(id_r_ele) REFERENCES r_ele(id),
    FOREIGN KEY(id_pri) REFERENCES pri(id)
);

CREATE INDEX idx_keb ON k_ele(keb);

CREATE TABLE pri(
    id INTEGER PRIMARY KEY,
    id_entry INTEGER,
    news INTEGER,
    ichi INTEGER,
    spec INTEGER,
    gai INTEGER,
    nf INTEGER,
    FOREIGN KEY(id_entry) REFERENCES entry(id)
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

CREATE INDEX idx_gloss ON gloss(gloss);

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

CREATE TABLE k_ele_ke_inf(
    id_k_ele INTEGER,
    id_ke_inf INTEGER,
    FOREIGN KEY(id_k_ele) REFERENCES k_ele(id),
    FOREIGN KEY(id_ke_inf) REFERENCES ke_inf(id),
    PRIMARY KEY (id_k_ele, id_ke_inf)
);

CREATE TABLE re_inf(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name STRING,
    description STRING
);

CREATE TABLE r_ele_re_inf(
    id_r_ele INTEGER,
    id_re_inf INTEGER,
    FOREIGN KEY(id_r_ele) REFERENCES r_ele(id),
    FOREIGN KEY(id_re_inf) REFERENCES re_inf(id),
    PRIMARY KEY (id_r_ele, id_re_inf)
);
