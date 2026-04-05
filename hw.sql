CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE TABLE specializations (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE doctors (
    id SERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    specialization_id INT REFERENCES specializations(id)
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
);

CREATE TABLE appointments (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    doctor_id INT REFERENCES doctors(id),
    appointment_date TIMESTAMP NOT NULL
);

CREATE TABLE medical_records (
     id SERIAL PRIMARY KEY,
     appointment_id INT REFERENCES appointments(id),
     diagnosis TEXT NOT NULL,
     description TEXT NOT NULL,
     created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE prescriptions (
   id SERIAL PRIMARY KEY,
   record_id INT REFERENCES medical_records(id),
   medication TEXT NOT NULL,
   dosage TEXT NOT NULL
);


-- внешние ключи
CREATE INDEX idx_appointments_user ON appointments(user_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_records_appointment ON medical_records(appointment_id);
CREATE INDEX idx_prescriptions_record ON prescriptions(record_id);

-- полнотекстовый поиск
CREATE INDEX idx_records_fts ON medical_records
    USING GIN (
               to_tsvector('russian', diagnosis || ' ' || description)
        );

-- триграммы (частичный поиск)
CREATE INDEX idx_records_trgm ON medical_records
    USING GIN (description gin_trgm_ops);


INSERT INTO specializations (name) VALUES
   ('Терапевт'),
   ('Кардиолог'),
   ('Невролог');

INSERT INTO doctors (full_name, specialization_id) VALUES
   ('Иванов Иван Иванович', 1),
   ('Петров Петр Петрович', 2);

INSERT INTO users (full_name, email) VALUES
     ('Сидоров Алексей', 'alex@example.com'),
     ('Кузнецова Мария', 'maria@example.com');

INSERT INTO appointments (user_id, doctor_id, appointment_date) VALUES
    (1, 1, NOW()),
    (2, 2, NOW());

INSERT INTO medical_records (appointment_id, diagnosis, description) VALUES
    (1, 'ОРВИ', 'Пациент жалуется на высокую температуру и кашель'),
    (2, 'Гипертония', 'Повышенное артериальное давление и головная боль');

INSERT INTO prescriptions (record_id, medication, dosage) VALUES
      (1, 'Парацетамол', '500 мг'),
      (2, 'Лозартан', '50 мг');



SELECT *,
       ts_rank(
               to_tsvector('russian', diagnosis || ' ' || description),
               plainto_tsquery('russian', 'кашель температура')
       ) AS rank
FROM medical_records
WHERE to_tsvector('russian', diagnosis || ' ' || description)
          @@ plainto_tsquery('russian', 'кашель температура')
ORDER BY rank DESC;


SELECT *
FROM medical_records
WHERE similarity(description, 'темпер') > 0.3
ORDER BY similarity(description, 'темпер') DESC;



SELECT *,
       ts_rank(
               to_tsvector('russian', diagnosis || ' ' || description),
               plainto_tsquery('russian', 'давление')
       ) AS rank
FROM medical_records
WHERE
    to_tsvector('russian', diagnosis || ' ' || description)
        @@ plainto_tsquery('russian', 'давление')
   OR description % 'давл'
ORDER BY rank DESC;



EXPLAIN ANALYZE
SELECT *
FROM medical_records
WHERE to_tsvector('russian', diagnosis || ' ' || description)
          @@ plainto_tsquery('russian', 'кашель');