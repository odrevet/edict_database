-- Import entity tables first (they're referenced by other tables)
\copy expression.lang FROM 'data/generated/csv/expression/lang.csv' WITH (FORMAT csv, HEADER true);
\copy expression.dial FROM 'data/generated/csv/expression/dial.csv' WITH (FORMAT csv, HEADER true);
\copy expression.misc FROM 'data/generated/csv/expression/misc.csv' WITH (FORMAT csv, HEADER true);
\copy expression.pos FROM 'data/generated/csv/expression/pos.csv' WITH (FORMAT csv, HEADER true);
\copy expression.field FROM 'data/generated/csv/expression/field.csv' WITH (FORMAT csv, HEADER true);
\copy expression.ke_inf FROM 'data/generated/csv/expression/ke_inf.csv' WITH (FORMAT csv, HEADER true);
\copy expression.re_inf FROM 'data/generated/csv/expression/re_inf.csv' WITH (FORMAT csv, HEADER true);

-- Import entries
\copy expression.entry FROM 'data/generated/csv/expression/entry.csv' WITH (FORMAT csv, HEADER true);

-- Import priorities
\copy expression.pri FROM 'data/generated/csv/expression/pri.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- Import kanji and reading elements
\copy expression.k_ele FROM 'data/generated/csv/expression/k_ele.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy expression.r_ele FROM 'data/generated/csv/expression/r_ele.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- Import element relations
\copy expression.k_ele_ke_inf FROM 'data/generated/csv/expression/k_ele_ke_inf.csv' WITH (FORMAT csv, HEADER true);
\copy expression.r_ele_re_inf FROM 'data/generated/csv/expression/r_ele_re_inf.csv' WITH (FORMAT csv, HEADER true);
\copy expression.r_ele_k_ele (id_r_ele, id_k_ele) FROM 'data/generated/csv/expression/r_ele_k_ele.csv' WITH (FORMAT csv, HEADER true);

-- Import senses
\copy expression.sense FROM 'data/generated/csv/expression/sense.csv' WITH (FORMAT csv, HEADER true);

-- Import sense relations
\copy expression.sense_pos FROM 'data/generated/csv/expression/sense_pos.csv' WITH (FORMAT csv, HEADER true);
\copy expression.sense_misc FROM 'data/generated/csv/expression/sense_misc.csv' WITH (FORMAT csv, HEADER true);
\copy expression.sense_dial FROM 'data/generated/csv/expression/sense_dial.csv' WITH (FORMAT csv, HEADER true);
\copy expression.sense_field FROM 'data/generated/csv/expression/sense_field.csv' WITH (FORMAT csv, HEADER true);

-- Import glosses
\copy expression.gloss (id_sense, id_lang, content) FROM 'data/generated/csv/expression/gloss.csv' WITH (FORMAT csv, HEADER true);

-- Import cross-references and antonyms
\copy expression.sense_xref (id_sense, keb, reb, sense_number) FROM 'data/generated/csv/expression/sense_xref.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy expression.sense_ant (id_sense, keb, reb, sense_number) FROM 'data/generated/csv/expression/sense_ant.csv' WITH (FORMAT csv, HEADER true, NULL '');