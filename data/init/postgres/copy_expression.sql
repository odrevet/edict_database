-- Import entity tables first (they're referenced by other tables)
\copy lang FROM 'data/generated/csv/expression/lang.csv' WITH (FORMAT csv, HEADER true);
\copy dial FROM 'data/generated/csv/expression/dial.csv' WITH (FORMAT csv, HEADER true);
\copy misc FROM 'data/generated/csv/expression/misc.csv' WITH (FORMAT csv, HEADER true);
\copy pos FROM 'data/generated/csv/expression/pos.csv' WITH (FORMAT csv, HEADER true);
\copy field FROM 'data/generated/csv/expression/field.csv' WITH (FORMAT csv, HEADER true);
\copy ke_inf FROM 'data/generated/csv/expression/ke_inf.csv' WITH (FORMAT csv, HEADER true);
\copy re_inf FROM 'data/generated/csv/expression/re_inf.csv' WITH (FORMAT csv, HEADER true);

-- Import entries
\copy entry FROM 'data/generated/csv/expression/entry.csv' WITH (FORMAT csv, HEADER true);

-- Import priorities
\copy pri FROM 'data/generated/csv/expression/pri.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- Import kanji and reading elements
\copy k_ele FROM 'data/generated/csv/expression/k_ele.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy r_ele FROM 'data/generated/csv/expression/r_ele.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- Import element relations
\copy k_ele_ke_inf FROM 'data/generated/csv/expression/k_ele_ke_inf.csv' WITH (FORMAT csv, HEADER true);
\copy r_ele_re_inf FROM 'data/generated/csv/expression/r_ele_re_inf.csv' WITH (FORMAT csv, HEADER true);
\copy r_ele_k_ele (id_r_ele, id_k_ele) FROM 'data/generated/csv/expression/r_ele_k_ele.csv' WITH (FORMAT csv, HEADER true);

-- Import senses
\copy sense FROM 'data/generated/csv/expression/sense.csv' WITH (FORMAT csv, HEADER true);

-- Import sense relations
\copy sense_pos FROM 'data/generated/csv/expression/sense_pos.csv' WITH (FORMAT csv, HEADER true);
\copy sense_misc FROM 'data/generated/csv/expression/sense_misc.csv' WITH (FORMAT csv, HEADER true);
\copy sense_dial FROM 'data/generated/csv/expression/sense_dial.csv' WITH (FORMAT csv, HEADER true);
\copy sense_field FROM 'data/generated/csv/expression/sense_field.csv' WITH (FORMAT csv, HEADER true);

-- Import glosses
\copy gloss (id_sense, id_lang, content) FROM 'data/generated/csv/expression/gloss.csv' WITH (FORMAT csv, HEADER true);

-- Import cross-references and antonyms
\copy sense_xref (id_sense, keb, reb, sense_number) FROM 'data/generated/csv/expression/sense_xref.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy sense_ant (id_sense, keb, reb, sense_number) FROM 'data/generated/csv/expression/sense_ant.csv' WITH (FORMAT csv, HEADER true, NULL '');