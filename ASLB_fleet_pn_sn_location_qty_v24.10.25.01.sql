SELECT rotables.ac_registr,
       aircraft.ac_typ,
       rotables.partno,
       rotables.serialno,
       rotables.location,
       CASE 
           WHEN part_ac_position.qty_per_position IS NULL 
                OR part_ac_position.qty_per_position = BINARY_DOUBLE_NAN THEN 'Unknown Position'
           ELSE TO_CHAR(part_ac_position.qty_per_position, 'FM9999990')
       END AS qty_per_position,
	rotables.owner
FROM rotables
INNER JOIN aircraft ON aircraft.ac_registr = rotables.ac_registr
INNER JOIN part ON rotables.partno = part.partno  -- Join with part table for partseqno_i
LEFT JOIN part_ac_position 
    ON rotables.location = part_ac_position.position
    AND aircraft.ac_typ = part_ac_position.ac_typ
    AND part.partseqno_i = part_ac_position.partseqno_i  -- Use part.partseqno_i for the join
WHERE rotables.ac_registr LIKE 'O%'
ORDER BY aircraft.ac_typ,
         rotables.ac_registr;