DECLARE
cursor c_student IS
    select * from student;
abc c_student%ROWTYPE;
BEGIN
    open c_student;
    loop 
        fetch c_student into abc;
        exit when c_student%notfound;
        dbms_output.put_line('ID: ' || abc.student_id);
        dbms_output.put_line('First Name: ' || abc.first_name);
        dbms_output.put_line('Last Name: ' || abc.last_name);
        dbms_output.put_line('City: ' || abc.city);
        dbms_output.put_line('Marks: ' || abc.marks);
    end loop;
    close c_student;
end;