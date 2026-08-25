create or replace package student_pkg as
    procedure show_data(sid number);
end;

create or replace package body student_pkg as
    PROCEDURE show_data(sid number)
    is
        name varchar2(20);
    begin
        select first_name  into name
        from student
        where student_id=sid;

        dbms_output.PUT_LINE(name);
    end;
end;

BEGIN
    STUDENT_PKG.SHOW_DATA(120);
end;
