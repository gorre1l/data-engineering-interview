Data Model:

--List of individuals who can be assigned tasks.
CREATE OR REPLACE TABLE people (
    person_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL
);
--Main tasks with recurrence rules
CREATE OR REPLACE TABLE tasks (
    task_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    recurrence_type VARCHAR(10) CHECK (recurrence_type IN ('none', 'daily', 'weekly', 'monthly')),
    max_occurrences INT, -- nullable if EndDate is used instead
    end_date DATE -- nullable if MaxOccurrences is used
);
--Which people are assigned to which tasks.
CREATE OR REPLACE TABLE task_assignments (
    task_id INT NOT NULL,
    person_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (task_id, person_id),
    FOREIGN KEY (task_id) REFERENCES tasks(task_id),
    FOREIGN KEY (person_id) REFERENCES people(person_id)
);
--Stores each instance of a task, generated from recurrence logic.
CREATE OR REPLACE TABLE task_occurrences (
    occurrence_id SERIAL PRIMARY KEY,
    task_id INT NOT NULL,
    occurrence_date DATE NOT NULL,
    FOREIGN KEY (task_id) REFERENCES tasks(task_id)
);
--Status for each person on each task occurrence.
CREATE OR REPLACE TABLE task_statuses (
    occurrence_id INT NOT NULL,
    person_id INT NOT NULL,
    status VARCHAR(20) CHECK (status IN ('Not Started', 'In Progress', 'Completed')),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (occurrence_id, person_id),
    FOREIGN KEY (occurrence_id) REFERENCES task_occurrences(occurrence_id),
    FOREIGN KEY (person_id) REFERENCES people(person_id)
);
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Writing queries:

1.Write a query to return all patients who are active.

SELECT *
FROM "Patient"
WHERE "active" = TRUE;

2.Given a patient_id, retrieve all encounters for that patient, including the status and encounter date.

SELECT id AS encounter_id, status, encounter_date
FROM "Encounter"
WHERE "patient_id" = '3a569b9c-2466-441a-973e-42edfce62f0c';

3.Write a query to fetch all observations for a given patient_id, showing the observation type, value, unit, and recorded date.

SELECT type, value, unit, recorded_at
FROM "Observation"
WHERE "patient_id" = '3a569b9c-2466-441a-973e-42edfce62f0c';

4.Retrieve each patient’s most recent encounter (based on encounter_date). Return the patient_id, encounter_date, and status.

SELECT patient_id, encounter_date, status
FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY encounter_date DESC) AS rn
    FROM "Encounter") recent
WHERE rn = 1;

5.Write a query to return a list of patient IDs who have had encounters with more than one distinct practitioner.

SELECT patient_id
FROM "Encounter"
WHERE "practitioner_id" IS NOT NULL
GROUP BY "patient_id"
HAVING COUNT(DISTINCT "practitioner_id") > 1;

6.Write a query to find the three most commonly prescribed medications from the MedicationRequest table, sorted by the number of prescriptions.

SELECT medication_name, COUNT(*) AS prescription_count
FROM "MedicationRequest"
GROUP BY "medication_name"
ORDER BY "prescription_count" DESC
LIMIT 3;

7.Write a query to find all practitioners who do not appear in the MedicationRequest table as a prescribing practitioner.

SELECT p.id, p.name
FROM "Practitioner" p
LEFT JOIN "MedicationRequest" m ON p.id = m.practitioner_id
WHERE m.id IS NULL;

8.Calculate the average number of encounters per patient, rounded to two decimal places.

SELECT ROUND(COUNT(*)::NUMERIC / COUNT(DISTINCT patient_id), 2) AS avg_encounters_per_patient
FROM "Encounter";

9.Write a query to find patients who have a record in the MedicationRequest table but not associated encounters in the Encounter table.

SELECT DISTINCT m.patient_id
FROM "MedicationRequest" m
LEFT JOIN "Encounter" e ON m.patient_id = e.patient_id
WHERE e.id IS NULL;

10.Write a query to count how many patients had their first encounter in each month (YYYY-MM format) and still had at least one encounter in the following six months.

WITH first_encounter AS(
SELECT patient_id, MIN(encounter_date) AS first_date
FROM "Encounter"
GROUP BY patient_id
),
returned_later AS (
SELECT f.patient_id, TO_CHAR(DATE_TRUNC('month', f.first_date), 'YYYY-MM') AS first_month
FROM first_encounter f
JOIN "Encounter" e ON f.patient_id = e.patient_id
WHERE e.encounter_date > f.first_date
AND e.encounter_date <= f.first_date + INTERVAL '6 months')
SELECT first_month, COUNT(DISTINCT patient_id) AS patients_who_came_back
FROM returned_later
GROUP BY first_month
ORDER BY first_month;


