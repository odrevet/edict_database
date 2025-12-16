SELECT character.*,
       GROUP_CONCAT(DISTINCT character_radical.id_radical) AS radicals,
       GROUP_CONCAT(DISTINCT on_yomi.reading) AS on_reading,
       GROUP_CONCAT(DISTINCT kun_yomi.reading) AS kun_reading,
       GROUP_CONCAT(DISTINCT meaning.content) AS meanings
  FROM character
       LEFT JOIN
       character_radical ON character.id = character_radical.id_character
       LEFT JOIN
       on_yomi ON character.id = on_yomi.id_character
       LEFT JOIN
       kun_yomi ON kun_yomi.id_character = character.id
       LEFT JOIN
       meaning ON meaning.id_character = character.id
 WHERE character.id = "多";