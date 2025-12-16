SELECT
    entry.id AS entry_id,
    sense.id AS sense_id,
    STRING_AGG(DISTINCT COALESCE(k_ele.keb || ':', '') || r_ele.reb, ',') keb_reb_group,
    STRING_AGG(DISTINCT gloss.content, ',') AS gloss_group,
    STRING_AGG(DISTINCT pos.name, ',') AS pos_group,
    STRING_AGG(DISTINCT dial.name, ',') AS dial_group,
    STRING_AGG(DISTINCT misc.name, ',') AS misc_group,
    STRING_AGG(DISTINCT field.name, ',') AS field_group,
    STRING_AGG(DISTINCT
        CASE
            WHEN sense_xref.reb IS NOT NULL
            THEN COALESCE(sense_xref.keb, '') || ':' || sense_xref.reb
            WHEN sense_xref.keb IS NOT NULL
            THEN sense_xref.keb
        END, ','
    ) FILTER (WHERE sense_xref.reb IS NOT NULL OR sense_xref.keb IS NOT NULL) AS xref_group,
    STRING_AGG(DISTINCT
        CASE
            WHEN sense_ant.reb IS NOT NULL
            THEN COALESCE(sense_ant.keb, '') || ':' || sense_ant.reb
            WHEN sense_ant.keb IS NOT NULL
            THEN sense_ant.keb
        END, ','
    ) FILTER (WHERE sense_ant.reb IS NOT NULL OR sense_ant.keb IS NOT NULL) AS ant_group
FROM entry
    JOIN r_ele ON entry.id = r_ele.id_entry
    JOIN sense ON sense.id_entry = entry.id
    JOIN gloss ON gloss.id_sense = sense.id
    LEFT JOIN k_ele ON entry.id = k_ele.id_entry
    LEFT JOIN sense_pos ON sense.id = sense_pos.id_sense
    LEFT JOIN pos ON sense_pos.id_pos = pos.id
    LEFT JOIN sense_dial ON sense.id = sense_dial.id_sense
    LEFT JOIN dial ON sense_dial.id_dial = dial.id
    LEFT JOIN sense_misc ON sense.id = sense_misc.id_sense
    LEFT JOIN misc ON sense_misc.id_misc = misc.id
    LEFT JOIN sense_field ON sense.id = sense_field.id_sense
    LEFT JOIN field ON sense_field.id_field = field.id
    LEFT JOIN sense_xref ON sense.id = sense_xref.id_sense
    LEFT JOIN sense_ant ON sense.id = sense_ant.id_sense
WHERE r_ele.reb = 'あがる'
GROUP BY entry.id, sense.id;