1. Retrieve all active patients

select * from "Patient" where active is true;

2. Find encounters for a specific patient

select patient_id, status, encounter_date from "Encounter" where patient_id = '30937a9a-6118-4d12-88f1-c3f303eefc2b';
              patient_id              |  status  |       encounter_date       
--------------------------------------+----------+----------------------------
 30937a9a-6118-4d12-88f1-c3f303eefc2b | finished | 2025-04-23 20:01:04.954538
 30937a9a-6118-4d12-88f1-c3f303eefc2b | finished | 2025-04-23 02:26:18.305813
 
3. List all observations recorded for a patient

select type, value, unit, recorded_at from "Observation" where patient_id = '30937a9a-6118-4d12-88f1-c3f303eefc2b';
      type      | value | unit |        recorded_at        
----------------+-------+------+---------------------------
 Heart Rate     | 115   | °C   | 2025-05-12 20:41:08.15066
 Blood Pressure | 138   | °C   | 2025-05-12 20:41:08.15066
 
 4. Find the most recent encounter for each patient
 
with pt_wd as 
 (select
    p.id,
    e.status,
    e.encounter_date,
    row_number() over (partition by p.id order by e.encounter_date desc) as rn 
 from "Patient" p
 join "Encounter" e
    on p.id = e.patient_id
)
select id,status, encounter_date from pt_wd where rn = 1;
                  id                  |   status    |       encounter_date       
--------------------------------------+-------------+----------------------------
 1154ceda-f928-43f4-875f-7da61d092b80 | in-progress | 2025-05-08 04:13:34.346411
 26f9f735-47f3-4cff-9e54-69b3b0a1354e | in-progress | 2025-05-08 20:27:43.439173
 30937a9a-6118-4d12-88f1-c3f303eefc2b | finished    | 2025-04-23 20:01:04.954538
 3c6f12c9-3ab4-41e9-b9e4-6bbc8d90bfd6 | planned     | 2025-04-23 14:00:47.960403
 624bdb89-804b-423d-91fa-b3efa99bd7bc | cancelled   | 2025-05-06 03:09:46.985108
 69a13cde-0f15-41bf-9ff6-49f5eece36fb | planned     | 2025-05-02 02:52:17.420711
 91584118-72b7-4abc-82e5-2a123784333c | in-progress | 2025-05-05 11:58:32.192739
 99ecd95f-b7ac-4989-b917-502929f351c8 | cancelled   | 2025-04-15 20:27:29.532886
 
 5. Find patients who have had encounters with more than one practitioner
 
 with pt_has_encounters as (
    select distinct p.id
     from "Patient" p
     join "Encounter" e
        on p.id = e.patient_id
 )
 select
    pe.id,
    count(*)
 from pt_has_encounters pe
 join "MedicationRequest" mr
    on pe.id = mr.patient_id
 join "Practitioner" pt
    on mr.practitioner_id = pt.id
 group by 1
 having count(*) > 1;
                   id                  | count 
--------------------------------------+-------
 69a13cde-0f15-41bf-9ff6-49f5eece36fb |     2
 624bdb89-804b-423d-91fa-b3efa99bd7bc |     2
 91584118-72b7-4abc-82e5-2a123784333c |     2
 
 6. Find the top 3 most prescribed medications
 select medication_name, count(*) from "MedicationRequest" group by 1 order by 2 desc limit 3;
 medication_name | count 
-----------------+-------
 Lisinopril      |     3
 Metformin       |     3
 Aspirin         |     2
 
7. Get practitioners who have never prescribed any medication
select * from "Practitioner" where id not in (select practitioner_id from "MedicationRequest");
 id | identifier | name | specialty | telecom | active | created_at 
----+------------+------+-----------+---------+--------+------------
(0 rows)

8. Find the average number of encounters per patient
 with pt_encounters as (
    select p.id, count(*) as p_encounter_count
     from "Patient" p
     join "Encounter" e
        on p.id = e.patient_id
    group by 1
 )
 select round(avg(p_encounter_count),2) from pt_encounters;
 
  round 
-------
  1.88
  
9. Identify patients who have never had an encounter but have a medication request
with p_not_in_encounter as (
select
    p.id
from "Patient" p
where p.id not in (select patient_id from "Encounter")
)
select id
from p_not_in_encounter
where id in (select patient_id from "MedicationRequest");
                  id                  
--------------------------------------
 9a15d169-a3b5-4de5-a8af-e7c606b3c3fc
 
 10. Determine patient retention by cohort
with patient_1st_encounters as (
  select
    patient_id,
    min(encounter_date) as first_encounter_date
  from "Encounter"
  group by
    patient_id
), 
patient_encounter_within_6_months as (
  select
    pea.patient_id,
    pea.first_encounter_date,
    (
      select
        count(*)
      from
        "Encounter" e
      where
        e.patient_id = pea.patient_id
        and e.encounter_date >= pea.first_encounter_date
        and e.encounter_date < pea.first_encounter_date + INTERVAL '6 months'
    ) as has_encounter_within_6_months
  from
    patient_1st_encounters pea
)
select
  to_char(first_encounter_date, 'YYYY-MM') as month,
  count(distinct patient_id) as patient_count
from
  patient_encounter_within_6_months
where
  has_encounter_within_6_months > 0
group by
  1
order by
  1;    
  
  month  | patient_count 
---------+---------------
 2025-04 |             7
 2025-05 |             1
