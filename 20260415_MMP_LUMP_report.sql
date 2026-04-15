SELECT
    q.mpno_i,
    q.taskcardno,
    q.taskcardno_i,
    q.title,
    q.revision_date,
    q.revision_no,
    q.release_date,
    q.revision_reason,
    q.mrb_revision_number,
    q.mrb_revision_date,
    q.mrb_revision_reason,
    q.itemno_i,
    q.event_key,
    q.effectivityno_i,
    q.higher_effectivityno_i,
    q.effectivity_linkno_i,
    q.effectivity_status,

 CASE
        WHEN e1.effectivityno_i IS NULL THEN 0
        WHEN e2.effectivityno_i IS NULL THEN 1
        WHEN e3.effectivityno_i IS NULL THEN 2
        WHEN e4.effectivityno_i IS NULL THEN 3
        WHEN e5.effectivityno_i IS NULL THEN 4
        WHEN e6.effectivityno_i IS NULL THEN 5
        WHEN e7.effectivityno_i IS NULL THEN 6
        WHEN e8.effectivityno_i IS NULL THEN 7
        WHEN e9.effectivityno_i IS NULL THEN 8
        WHEN e10.effectivityno_i IS NULL THEN 9
        ELSE 10
    END AS EFF_DEPTH,	

    q.effectivity_title,
    q.aircraft_mission_config,
    q.aircraft_operator,
    q.special,
    q.THR_CYC,
    q.THR_HRS,
    q.THR_DAY,
    q.THR_UNIT,
    q.INT_CYC,
    q.INT_HRS,
    q.INT_DAY,
    q.INT_UNIT,

    COALESCE(
        e10.effectivityno_i,
        e9.effectivityno_i,
        e8.effectivityno_i,
        e7.effectivityno_i,
        e6.effectivityno_i,
        e5.effectivityno_i,
        e4.effectivityno_i,
        e3.effectivityno_i,
        e2.effectivityno_i,
        e1.effectivityno_i,
        e0.effectivityno_i
    ) AS ROOT_EFFECTIVITYNO_I

FROM (
    SELECT
        mt.mpno_i,
        mt.taskcardno,
        mt.taskcardno_i,
        mt.title,
        mtv.revision_date,
        mtv.revision_no,
        mtv.release_date,
        mtv.revision_reason,
        mtv.mrb_revision_number,
        mtv.mrb_revision_date,
        mtv.mrb_revision_reason,
        mi.itemno_i,
        eel.event_key,
        eel.effectivityno_i,
        ee.higher_effectivityno_i,
        eel.effectivity_linkno_i,

        CASE
            WHEN ee.status = '0' THEN 'Active'
            WHEN ee.status = '1' THEN 'Inactive'
            ELSE 'Unknown'
        END AS effectivity_status,

        ee.title AS effectivity_title,
        amc.code AS aircraft_mission_config,
        adr.vendor AS aircraft_operator,
        MIN(scl.special) AS special,

        MIN(CASE
            WHEN ti.dimension_type = 'W' AND ti.counter_defno_i = 1
            THEN ti.amount_interval
        END) AS THR_CYC,

        MIN(CASE
            WHEN ti.dimension_type = 'W' AND ti.counter_defno_i = 2
            THEN ti.amount_interval
        END) AS THR_HRS,

        MIN(CASE
            WHEN ti.dimension_type = 'W' AND ti.counter_defno_i = 3
            THEN ti.amount_interval
        END) AS THR_DAY,

        MIN(CASE
            WHEN ti.dimension_type = 'W' AND ti.counter_defno_i = 3
            THEN ti.unit
        END) AS THR_UNIT,

        MIN(CASE
            WHEN ti.dimension_type = 'I' AND ti.counter_defno_i = 1
            THEN ti.amount_interval
        END) AS INT_CYC,

        MIN(CASE
            WHEN ti.dimension_type = 'I' AND ti.counter_defno_i = 2
            THEN ti.amount_interval
        END) AS INT_HRS,

        MIN(CASE
            WHEN ti.dimension_type = 'I' AND ti.counter_defno_i = 3
            THEN ti.amount_interval
        END) AS INT_DAY,

        MIN(CASE
            WHEN ti.dimension_type = 'I' AND ti.counter_defno_i = 3
            THEN ti.unit
        END) AS INT_UNIT

    FROM msc_taskcard mt
    JOIN (
        SELECT
            taskcardno_i,
            MAX(taskcard_verno_i) AS max_taskcard_verno_i
        FROM msc_taskcard_version
        GROUP BY taskcardno_i
    ) latest
        ON mt.taskcardno_i = latest.taskcardno_i
    JOIN msc_taskcard_version mtv
        ON mtv.taskcardno_i = latest.taskcardno_i
       AND mtv.taskcard_verno_i = latest.max_taskcard_verno_i
    JOIN msc_item mi
        ON mtv.taskcard_verno_i = mi.taskcard_verno_i
    LEFT JOIN event_effectivity_link eel
        ON mi.itemno_i = eel.event_key
       AND eel.event_type = 'TI'
    LEFT JOIN event_effectivity ee
        ON eel.effectivityno_i = ee.effectivityno_i
    LEFT JOIN event_effectivity_rules eer
        ON eel.effectivityno_i = eer.effectivityno_i
    LEFT JOIN address adr
        ON eer.aircraft_operator = adr.address_i
    LEFT JOIN ac_mission_configuration amc
        ON eer.aircraft_mission_config = amc.ac_configurationno_i
    LEFT JOIN worktemplate_link wtl
        ON eel.effectivity_linkno_i = wtl.event_key
    LEFT JOIN event_template et
        ON wtl.wtno_i = et.wtno_i
    LEFT JOIN workstep_link wsl
        ON et.event_perfno_i = wsl.event_perfno_i
    LEFT JOIN special_code_link scl
        ON wsl.descno_i = scl.source_pk
    LEFT JOIN treq_time_requirement ttr
        ON eel.effectivity_linkno_i = ttr.event_key
    LEFT JOIN treq_interval_group tig
        ON ttr.timerequirementno_i = tig.timerequirementno_i
    LEFT JOIN treq_dimension_group tdg
        ON tig.interval_groupno_i = tdg.interval_groupno_i
    LEFT JOIN treq_interval ti
        ON tdg.dimension_groupno_i = ti.dimension_groupno_i
    WHERE mt.mpno_i = 206
    GROUP BY
        mt.mpno_i,
        mt.taskcardno,
        mt.taskcardno_i,
        mt.title,
        mtv.revision_date,
        mtv.revision_no,
        mtv.release_date,
        mtv.revision_reason,
        mtv.mrb_revision_number,
        mtv.mrb_revision_date,
        mtv.mrb_revision_reason,
        mi.itemno_i,
        eel.event_key,
        eel.effectivityno_i,
        ee.higher_effectivityno_i,
        eel.effectivity_linkno_i,
        ee.status,
        ee.title,
        amc.code,
        adr.vendor
) q
LEFT JOIN event_effectivity e0
    ON q.effectivityno_i = e0.effectivityno_i
LEFT JOIN event_effectivity e1
    ON e0.higher_effectivityno_i = e1.effectivityno_i
LEFT JOIN event_effectivity e2
    ON e1.higher_effectivityno_i = e2.effectivityno_i
LEFT JOIN event_effectivity e3
    ON e2.higher_effectivityno_i = e3.effectivityno_i
LEFT JOIN event_effectivity e4
    ON e3.higher_effectivityno_i = e4.effectivityno_i
LEFT JOIN event_effectivity e5
    ON e4.higher_effectivityno_i = e5.effectivityno_i
LEFT JOIN event_effectivity e6
    ON e5.higher_effectivityno_i = e6.effectivityno_i
LEFT JOIN event_effectivity e7
    ON e6.higher_effectivityno_i = e7.effectivityno_i
LEFT JOIN event_effectivity e8
    ON e7.higher_effectivityno_i = e8.effectivityno_i
LEFT JOIN event_effectivity e9
    ON e8.higher_effectivityno_i = e9.effectivityno_i
LEFT JOIN event_effectivity e10
    ON e9.higher_effectivityno_i = e10.effectivityno_i

ORDER BY
    q.taskcardno,
    q.itemno_i,
    COALESCE(
        e10.effectivityno_i,
        e9.effectivityno_i,
        e8.effectivityno_i,
        e7.effectivityno_i,
        e6.effectivityno_i,
        e5.effectivityno_i,
        e4.effectivityno_i,
        e3.effectivityno_i,
        e2.effectivityno_i,
        e1.effectivityno_i,
        e0.effectivityno_i
    ),
    CASE
        WHEN e1.effectivityno_i IS NULL THEN 0
        WHEN e2.effectivityno_i IS NULL THEN 1
        WHEN e3.effectivityno_i IS NULL THEN 2
        WHEN e4.effectivityno_i IS NULL THEN 3
        WHEN e5.effectivityno_i IS NULL THEN 4
        WHEN e6.effectivityno_i IS NULL THEN 5
        WHEN e7.effectivityno_i IS NULL THEN 6
        WHEN e8.effectivityno_i IS NULL THEN 7
        WHEN e9.effectivityno_i IS NULL THEN 8
        WHEN e10.effectivityno_i IS NULL THEN 9
        ELSE 10
    END,
    q.aircraft_mission_config;
