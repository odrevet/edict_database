SELECT radical.*
FROM radical
JOIN character_radical ON character_radical.id_radical = radical.id
WHERE character_radical.id_character="思";