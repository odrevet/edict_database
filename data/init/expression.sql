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

CREATE TABLE r_ele_k_ele(
    id_r_ele INTEGER,
    id_k_ele INTEGER,
    FOREIGN KEY(id_r_ele) REFERENCES r_ele(id),
    FOREIGN KEY(id_k_ele) REFERENCES k_ele(id),
    PRIMARY KEY (id_r_ele, id_k_ele)
);

CREATE TABLE k_ele(
    id INTEGER PRIMARY KEY,
    id_entry INTEGER,
    id_pri INTEGER,
    keb STRING,
    FOREIGN KEY(id_entry) REFERENCES entry(id),
    FOREIGN KEY(id_pri) REFERENCES pri(id)
);

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
    FOREIGN KEY(id_entry) REFERENCES entry(id)
);

CREATE TABLE gloss(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_sense INTEGER,
    id_lang INTEGER,
    content STRING,
    FOREIGN KEY(id_sense) REFERENCES sense(id),
    FOREIGN KEY(id_lang) REFERENCES lang(id)
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

CREATE TABLE sense_xref (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_sense INTEGER,
    keb STRING,
    reb STRING,
    sense_number INTEGER,
    FOREIGN KEY(id_sense) REFERENCES sense(id)
);

CREATE TABLE sense_ant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    id_sense INTEGER,
    keb STRING,
    reb STRING,
    sense_number INTEGER,
    FOREIGN KEY(id_sense) REFERENCES sense(id)
);

CREATE TABLE field(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name STRING,
    description STRING
);

CREATE TABLE sense_field(
    id_sense INTEGER,
    id_field INTEGER,
    FOREIGN KEY(id_sense) REFERENCES sense(id),
    FOREIGN KEY(id_field) REFERENCES field(id),
    PRIMARY KEY (id_sense, id_field)
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

-- INDEXES
-- Japanese reading lookup
CREATE INDEX idx_r_ele_reb_entry ON r_ele(reb, id_entry);

-- Kanji lookup
CREATE INDEX idx_k_ele_keb_entry ON k_ele(keb, id_entry);

-- Foreign key indexes for join optimization
CREATE INDEX idx_r_ele_id_entry ON r_ele(id_entry);
CREATE INDEX idx_k_ele_id_entry ON k_ele(id_entry);
CREATE INDEX idx_sense_id_entry ON sense(id_entry);
CREATE INDEX idx_gloss_id_sense ON gloss(id_sense);

-- JUNCTION TABLE INDEXES
CREATE INDEX idx_sense_pos_sense ON sense_pos(id_sense);
CREATE INDEX idx_sense_misc_sense ON sense_misc(id_sense);
CREATE INDEX idx_sense_dial_sense ON sense_dial(id_sense);
CREATE INDEX idx_sense_field_sense ON sense_field(id_sense);
CREATE INDEX idx_sense_xref_sense ON sense_xref(id_sense);
CREATE INDEX idx_sense_ant_sense ON sense_ant(id_sense);

-- NON-JAPANESE (ENGLISH OR OTHER SUPPORTED LANGUAGES) SEARCH INDEX
CREATE INDEX idx_gloss_content_sense ON gloss(content, id_sense);

-- COVERING INDEXES
-- eliminate table lookups
CREATE INDEX idx_r_ele_entry_reb ON r_ele(id_entry, reb);
CREATE INDEX idx_k_ele_entry_keb ON k_ele(id_entry, keb);
CREATE INDEX idx_gloss_sense_content_lang ON gloss(id_sense, content, id_lang);

-- REVERSE JUNCTION LOOKUPS
-- when search "which senses have this POS?"
-- CREATE INDEX idx_sense_pos_pos ON sense_pos(id_pos);
-- CREATE INDEX idx_sense_misc_misc ON sense_misc(id_misc);
-- CREATE INDEX idx_sense_dial_dial ON sense_dial(id_dial);
-- CREATE INDEX idx_sense_field_field ON sense_field(id_field);