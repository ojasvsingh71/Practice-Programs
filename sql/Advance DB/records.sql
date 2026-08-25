declare
    abc student%ROWTYPE;
Begin
    select *
        into abc
        from student
        where rownum=1;
    dbms_output.put_line('ID: ' || abc.student_id);
    dbms_output.put_line('First Name: ' || abc.first_name);
    dbms_output.put_line('Last Name: ' || abc.last_name);
    dbms_output.put_line('City: ' || abc.city);
    dbms_output.put_line('Marks: ' || abc.marks);
END;
