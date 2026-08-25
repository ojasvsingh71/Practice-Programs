create or replace trigger trg_student_marks_log2
after update of marks on student
for each ROW
begin
    insert into student_log(
        student_id,
        log_date,
        new_marks
    )
    values(
        :NEW.student_id,
        SYSDATE,
        :NEW.marks
    );
END;

update student set marks=99 where student_id=105;

select * from STUDENT;
select * from STUDENT_LOG;