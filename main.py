import psycopg2
import uuid
from faker import Faker
import random

# Initialize Faker
fake = Faker()

# Database Connection Settings
DB_CONFIG = {
    "dbname": "postgres",
    "user": "user",
    "password": "password",
    "host": "localhost",
    "port": "5432"
}

# Connect to PostgreSQL
conn = psycopg2.connect(**DB_CONFIG)
cursor = conn.cursor()

# Generate Fake Data
NUM_PATIENTS = 10
NUM_PRACTITIONERS = 5
NUM_ENCOUNTERS = 15
NUM_OBSERVATIONS = 20
NUM_MEDICATIONS = 10

# Store generated IDs for referential integrity
patients = []
practitioners = []
encounters = []

# Insert Patients
for _ in range(NUM_PATIENTS):
    patient_id = str(uuid.uuid4())
    patients.append(patient_id)
    cursor.execute("""
        INSERT INTO "Patient" (id, identifier, name, gender, birth_date, address, telecom, active, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW())
    """, (patient_id, fake.unique.uuid4(), fake.name(), random.choice(["Male", "Female", "Other"]),
          fake.date_of_birth(minimum_age=20, maximum_age=80), fake.address(), fake.email(), True))

# Insert Practitioners
for _ in range(NUM_PRACTITIONERS):
    practitioner_id = str(uuid.uuid4())
    practitioners.append(practitioner_id)
    cursor.execute("""
        INSERT INTO "Practitioner" (id, identifier, name, specialty, telecom, active, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, NOW())
    """, (practitioner_id, fake.unique.uuid4(), fake.name(), fake.job(), fake.email(), True))

# Insert Encounters
for _ in range(NUM_ENCOUNTERS):
    encounter_id = str(uuid.uuid4())
    encounters.append(encounter_id)
    cursor.execute("""
        INSERT INTO "Encounter" (id, patient_id, practitioner_id, status, encounter_date, reason, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, NOW())
    """, (encounter_id, random.choice(patients), random.choice(practitioners),
          random.choice(["planned", "in-progress", "finished", "cancelled"]),
          fake.date_time_between(start_date="-30d", end_date="now"), fake.sentence()))

# Insert Observations
for _ in range(NUM_OBSERVATIONS):
    cursor.execute("""
        INSERT INTO "Observation" (id, patient_id, encounter_id, type, value, unit, recorded_at)
        VALUES (%s, %s, %s, %s, %s, %s, NOW())
    """, (str(uuid.uuid4()), random.choice(patients), random.choice(encounters),
          random.choice(["Blood Pressure", "Heart Rate", "Temperature"]),
          str(random.randint(90, 140) if random.choice(["Blood Pressure", "Heart Rate"]) else round(random.uniform(36.0, 39.0), 1)),
          random.choice(["mmHg", "bpm", "°C"])))

# Insert Medication Requests
for _ in range(NUM_MEDICATIONS):
    cursor.execute("""
        INSERT INTO "MedicationRequest" (id, patient_id, practitioner_id, medication_name, dosage, status, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, NOW())
    """, (str(uuid.uuid4()), random.choice(patients), random.choice(practitioners),
          random.choice(["Aspirin", "Metformin", "Lisinopril", "Ibuprofen"]),
          f"{random.randint(5, 500)}mg {random.choice(['once daily', 'twice daily'])}",
          random.choice(["active", "completed", "cancelled"])))

# Commit and close connection
conn.commit()
cursor.close()
conn.close()

print("Test data inserted successfully!")