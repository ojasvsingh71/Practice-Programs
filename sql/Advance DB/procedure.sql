
create or replace procedure find_sname
(i_student_id in number, o_first_name out varchar2,
    o_city out VARCHAR2
    )
as 
BEGIN
    select first_name, city
        into o_first_name, o_city
        from STUDENT
    where student_id=i_student_id;
EXCEPTION
    when OTHERS
    then
        dbms_output.put_line('Error in finding student_id ' || i_student_id);
END find_sname;



declare 
o_first_name VARCHAR2(25);
o_city VARCHAR2(25);
BEGIN
    FIND_SNAME(120,o_first_name,o_city);
    dbms_output.put_line(o_first_name || ' ' || o_city);
end;