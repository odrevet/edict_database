SELECT
  entry.id AS entry_id,
  sense.id AS sense_id,
  (
    SELECT
      GROUP_CONCAT(IFNULL(keb || ':', '') || reb)
    FROM
      r_ele r_ele_sub
      LEFT JOIN r_ele_k_ele ON r_ele_k_ele.id_r_ele = r_ele_sub.id
      LEFT JOIN k_ele k_ele_sub ON r_ele_k_ele.id_k_ele = k_ele_sub.id
    WHERE
      r_ele_sub.id_entry = entry.id
  ) keb_reb_group,
  GROUP_CONCAT(DISTINCT gloss.content) gloss_group,
  GROUP_CONCAT(DISTINCT pos.name) pos_group,
  GROUP_CONCAT(DISTINCT dial.name) dial_group,
  GROUP_CONCAT(DISTINCT misc.name) misc_group,
  GROUP_CONCAT(DISTINCT field.name) field_group
FROM
  entry
  JOIN sense ON sense.id_entry = entry.id
  JOIN gloss ON gloss.id_sense = sense.id
  LEFT JOIN sense_pos ON sense.id = sense_pos.id_sense
  LEFT JOIN pos ON sense_pos.id_pos = pos.id
  LEFT JOIN sense_dial ON sense.id = sense_dial.id_sense
  LEFT JOIN dial ON sense_dial.id_dial = dial.id
  LEFT JOIN sense_misc ON sense.id = sense_misc.id_sense
  LEFT JOIN misc ON sense_misc.id_misc = misc.id
  LEFT JOIN sense_field ON sense.id = sense_field.id_sense
  LEFT JOIN field ON sense_field.id_field = field.id
WHERE
  entry.id IN (
    SELECT
      sense.id_entry
    FROM
      sense
      JOIN gloss ON gloss.id_sense = sense.id
    WHERE
      gloss.content = 'test'
  )
GROUP BY
  sense.id;