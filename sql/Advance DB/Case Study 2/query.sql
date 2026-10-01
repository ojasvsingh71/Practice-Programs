CREATE TABLE students (
    student_id NUMBER PRIMARY KEY,
    student_name VARCHAR2(50),
    course VARCHAR2(50)
);



CREATE TABLE subjects (
    subject_id NUMBER PRIMARY KEY,
    subject_name VARCHAR2(50)
);



CREATE TABLE marks (
    student_id NUMBER,
    subject_id NUMBER,
    marks NUMBER,

    PRIMARY KEY (student_id, subject_id),

    FOREIGN KEY (student_id)
    REFERENCES students(student_id),

    FOREIGN KEY (subject_id)
    REFERENCES subjects(subject_id)
);




INSERT INTO students VALUES
(1, 'Rahul Sharma', 'BCA');

INSERT INTO students VALUES
(2, 'Priya Singh', 'BCA');

INSERT INTO students VALUES
(3, 'Aman Verma', 'BCA');

COMMIT;






INSERT INTO subjects VALUES
(101, 'DBMS');

INSERT INTO subjects VALUES
(102, 'Python');

INSERT INTO subjects VALUES
(103, 'Mathematics');

INSERT INTO subjects VALUES
(104, 'Computer Networks');

COMMIT;







INSERT INTO marks VALUES (1, 101, 85);
INSERT INTO marks VALUES (1, 102, 90);
INSERT INTO marks VALUES (1, 103, 78);
INSERT INTO marks VALUES (1, 104, 88);



INSERT INTO marks VALUES (2, 101, 72);
INSERT INTO marks VALUES (2, 102, 80);
INSERT INTO marks VALUES (2, 103, 68);
INSERT INTO marks VALUES (2, 104, 75);



INSERT INTO marks VALUES (3, 101, 45);
INSERT INTO marks VALUES (3, 102, 55);
INSERT INTO marks VALUES (3, 103, 35);
INSERT INTO marks VALUES (3, 104, 60);

COMMIT;






CREATE OR REPLACE PROCEDURE calculate_result (
    p_student_id NUMBER
)
IS
    v_total NUMBER;
    v_percentage NUMBER;
BEGIN

    SELECT SUM(marks)
    INTO v_total
    FROM marks
    WHERE student_id = p_student_id;

    v_percentage := v_total / 4;

    DBMS_OUTPUT.PUT_LINE('Student ID: ' || p_student_id);
    DBMS_OUTPUT.PUT_LINE('Total Marks: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('Percentage: ' || v_percentage || '%');

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Student not found');

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);

END;


CREATE OR REPLACE FUNCTION get_percentage (
    p_student_id NUMBER
)
RETURN NUMBER
IS
    v_total NUMBER;
    v_percentage NUMBER;
BEGIN

    SELECT SUM(marks)
    INTO v_total
    FROM marks
    WHERE student_id = p_student_id;

    v_percentage := v_total / 4;

    RETURN v_percentage;

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        RETURN 0;

END;


CREATE OR REPLACE FUNCTION get_grade (
    p_student_id NUMBER
)
RETURN VARCHAR2
IS
    v_percentage NUMBER;
BEGIN

    v_percentage := get_percentage(p_student_id);

    IF v_percentage >= 90 THEN
        RETURN 'A+';

    ELSIF v_percentage >= 80 THEN
        RETURN 'A';

    ELSIF v_percentage >= 70 THEN
        RETURN 'B';

    ELSIF v_percentage >= 60 THEN
        RETURN 'C';

    ELSIF v_percentage >= 50 THEN
        RETURN 'D';

    ELSE
        RETURN 'F';

    END IF;

END;





CREATE OR REPLACE PROCEDURE display_result (
    p_student_id NUMBER
)
IS
    v_name VARCHAR2(50);
    v_total NUMBER;
    v_percentage NUMBER;
    v_grade VARCHAR2(5);
BEGIN

    SELECT student_name
    INTO v_name
    FROM students
    WHERE student_id = p_student_id;

    SELECT SUM(marks)
    INTO v_total
    FROM marks
    WHERE student_id = p_student_id;

    v_percentage := get_percentage(p_student_id);

    v_grade := get_grade(p_student_id);

    DBMS_OUTPUT.PUT_LINE('       STUDENT RESULT');

    DBMS_OUTPUT.PUT_LINE('Student ID  : ' || p_student_id);
    DBMS_OUTPUT.PUT_LINE('Name        : ' || v_name);
    DBMS_OUTPUT.PUT_LINE('Total Marks : ' || v_total);
    DBMS_OUTPUT.PUT_LINE('Percentage  : ' || v_percentage || '%');
    DBMS_OUTPUT.PUT_LINE('Grade       : ' || v_grade);

    IF v_percentage >= 40 THEN
        DBMS_OUTPUT.PUT_LINE('Result      : PASS');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Result      : FAIL');
    END IF;


EXCEPTION

    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Student not found');

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);

END;




CREATE OR REPLACE TRIGGER check_marks
BEFORE INSERT OR UPDATE
ON marks
FOR EACH ROW
BEGIN

    IF :NEW.marks < 0 OR :NEW.marks > 100 THEN

        DBMS_OUTPUT.PUT_LINE(
            'Marks must be between 0 and 100'
        );

    END IF;

END;



CREATE OR REPLACE TRIGGER marks_message
AFTER INSERT
ON marks
FOR EACH ROW
BEGIN

    DBMS_OUTPUT.PUT_LINE(
        'Marks added successfully for student ' ||
        :NEW.student_id
    );

END;





SELECT
    s.student_id,
    s.student_name,
    sub.subject_name,
    m.marks
FROM students s
JOIN marks m
    ON s.student_id = m.student_id
JOIN subjects sub
    ON m.subject_id = sub.subject_id
ORDER BY s.student_id;




SET SERVEROUTPUT ON;

BEGIN
    display_result(1);
END;



BEGIN
    display_result(2);
END;



BEGIN
    display_result(3);
END;