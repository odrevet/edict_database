SELECT id
FROM character
WHERE id IN(SELECT id_character FROM character_radical WHERE id_radical = "二" INTERSECT
            SELECT id_character FROM character_radical WHERE id_radical = "女"
);