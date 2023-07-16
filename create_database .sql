CREATE SCHEMA persons_db; # Создаём БД

USE persons_db; # Подключаемся к БД

# ###################################

# СОЗДАНИЕ ТАБЛИЦ

# Создаём таблицу имён
CREATE TABLE table_first_names(
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL
);

# Создаём таблицу фамилий
CREATE TABLE table_last_names(
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL
);

# Создаём таблицу персон
CREATE TABLE table_persons(
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    id_first_name INTEGER NOT NULL,
    id_last_name INTEGER NOT NULL,
    date_of_birth DATE NOT NULL,
    is_delete INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (id_last_name)
        REFERENCES table_last_names(id)
            ON UPDATE NO ACTION
            ON DELETE NO ACTION,
    FOREIGN KEY (id_first_name)
        REFERENCES table_first_names(id)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
);
# ### LOG ###
CREATE TABLE table_actions(
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(10)
);

CREATE TABLE table_users(
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50)
);

CREATE TABLE table_tables(
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50)
);

CREATE TABLE table_log(
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    date_time DATETIME NOT NULL DEFAULT NOW(),
    user_id INT NOT NULL,
    table_id INT NOT NULL,
    context TEXT NOT NULL,
    action_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES table_users(id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    FOREIGN KEY (table_id) REFERENCES table_tables(id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    FOREIGN KEY (action_id) REFERENCES table_actions(id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);
# ###################################

# ДОБАВЛЕНИЕ ДАННЫХ

# Добавление имён
INSERT INTO table_first_names (name) VALUES ('Andrey'),
                                            ('Anonim');

# Добавление фамилий
INSERT INTO table_last_names (name) VALUES ('Starinin'),
                                           ('Anonimus');

# Добавление персон
INSERT INTO table_persons (id_first_name, id_last_name, date_of_birth)
VALUES ((SELECT id
         FROM table_first_names
         WHERE name = 'Andrey'),
        (SELECT id
         FROM table_last_names
         WHERE name = 'Starinin'),
        NOW()),
    ((SELECT id
         FROM table_first_names
         WHERE name = 'Anonim'),
        (SELECT id
         FROM table_last_names
         WHERE name = 'Anonimus'),
        NOW());
# ###################################

# СОЗДАНИЕ ПРЕДСТАВЛЕНИЙ

# Представление персон
CREATE VIEW view_persons AS
    SELECT table_persons.id AS 'id',
           table_last_names.name AS 'last_name',
           table_first_names.name AS 'first_name',
           table_persons.date_of_birth AS 'date_of_birth',
           table_persons.is_delete AS 'is_delete'
    FROM table_persons
    JOIN table_first_names
        ON table_persons.id_first_name = table_first_names.id
    JOIN table_last_names
        ON table_persons.id_last_name = table_last_names.id;
# SELECT * FROM view_persons;

CREATE VIEW view_log AS
    SELECT table_log.id AS 'id',
           table_log.date_time AS 'date_time',
           table_users.name AS 'user',
           table_tables.name AS 'table',
           table_log.context AS 'context',
           table_actions.name AS 'action'
    FROM table_log
    JOIN table_users ON table_log.user_id = table_users.id
    JOIN table_tables ON table_log.table_id = table_tables.id
    JOIN table_actions ON table_log.action_id = table_actions.id;
# ###################################

# СОЗДАНИЕ ПРОЦЕДУР

# Создание процедуры по добавлению данных в таблицу персон (с проверкой таблиц имён и фамилий)
CREATE PROCEDURE procedure_insert_into_table_persons (IN first_name TEXT, IN last_name TEXT, IN date DATE)
BEGIN
    DECLARE var_first_name_id INT;
    DECLARE var_last_name_id INT;

    IF NOT EXISTS(SELECT * FROM table_first_names WHERE name = first_name) THEN
        INSERT INTO table_first_names (name) VALUES (first_name);
    END IF;
    SET var_first_name_id = (SELECT id FROM table_first_names WHERE name = first_name);

    IF NOT EXISTS(SELECT * FROM table_last_names WHERE name = last_name) THEN
        INSERT INTO table_last_names (name) VALUES (last_name);
    END IF;
    SET var_last_name_id = (SELECT id FROM table_last_names WHERE name = last_name);

    INSERT INTO table_persons (id_first_name, id_last_name, date_of_birth)
    VALUES (var_first_name_id, var_last_name_id, date);
END;

CALL procedure_insert_into_table_persons('Lubov', 'Karenina', NOW());
# CALL procedure_insert_into_table_persons('Anna', 'Starinina', NOW());

CREATE PROCEDURE procedure_insert_log(IN var_user VARCHAR(50),
    IN var_table VARCHAR(50),
    IN var_context TEXT,
    IN var_action VARCHAR(10))
BEGIN
    DECLARE var_user_id INT;
    DECLARE var_table_id INT;
    DECLARE var_action_id INT;

    IF NOT EXISTS(SELECT * FROM table_users WHERE name = var_user) THEN
        INSERT INTO table_users (name) VALUES (var_user);
    END IF;
    SET var_user_id = (SELECT id FROM table_users WHERE name = var_user);

    IF NOT EXISTS(SELECT * FROM table_tables WHERE name = var_table) THEN
        INSERT INTO table_tables (name) VALUES (var_table);
    END IF;
    SET var_table_id = (SELECT id FROM table_tables WHERE name = var_table);

    IF NOT EXISTS(SELECT * FROM table_actions WHERE name = var_action) THEN
        INSERT INTO table_actions (name) VALUES (var_action);
    END IF;
    SET var_action_id = (SELECT id FROM table_actions WHERE name = var_action);

    INSERT INTO table_log(user_id, table_id, context, action_id)
        VALUES (var_user_id, var_table_id, var_context, var_action_id);
END;

# ###################################

# Создание триггеров
CREATE TRIGGER trigger_table_first_names_insert
    AFTER INSERT ON table_first_names
    FOR EACH ROW
BEGIN
    DECLARE var_user VARCHAR(50);

    SET var_user = (SELECT CURRENT_USER());
    CALL procedure_insert_log(var_user, 'table_first_names', CONCAT_WS(' ', NEW.id, NEW.name), 'INSERT');
END;

CREATE TRIGGER trigger_table_last_names_insert
    AFTER INSERT ON table_last_names
    FOR EACH ROW
BEGIN
    DECLARE var_user VARCHAR(50);

    SET var_user = (SELECT CURRENT_USER());
    CALL procedure_insert_log(var_user, 'table_last_names', CONCAT_WS(' ', NEW.id, NEW.name), 'INSERT');
END;

CREATE TRIGGER trigger_table_persons_insert
    AFTER INSERT ON table_persons
    FOR EACH ROW
BEGIN
    DECLARE var_user VARCHAR(50);

    SET var_user = (SELECT CURRENT_USER());
    CALL procedure_insert_log(var_user, 'table_persons', CONCAT_WS(' ', NEW.id, NEW.id_last_name, NEW.id_first_name, NEW.date_of_birth, NEW.is_delete), 'INSERT');
END;