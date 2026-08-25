create or replace function adder(n1 in number,n2 in number)
    return NUMBER
is 
    n3 number(8);
BEGIN
    n3:=n1+n2;
    return n3;
end;



declare 
    n3 number(2);
BEGIN
    n3:=adder(1,3);
    dbms_output.put_line('Addition is '|| n3);
end;



create table course(course_no VARCHAR2(30),description VARCHAR2(20));

insert into course values('IB401','ARDBMS');

insert into course values('CS441','ADBMS');

create or replace function show_description
(i_course_no course.course_no%TYPE) return VARCHAR2
as
    v_description VARCHAR2(50);
BEGIN
    select description
    into v_description
    from course
    where course_no=i_course_no;
    return v_description;
EXCEPTION
    when no_data_found
    then 
        return ('The course is not in the database');
    when OTHERS
    then
        return ('Error in running show_description');
end;

declare 
    v_description VARCHAR2(20);
BEGIN
    v_description:=SHOW_DESCRIPTION('CS441');
    dbms_output.PUT_LINE(v_description);
end;





create or replace FUNCTION findmax(x in number,y in number)
return NUMBER
is
    z number;
BEGIN
    if x>y THEN
        z:=x;
    else 
        z:=y;
    end if;
    return z;
end;

DECLARE
    a number;
    b number;
    c number;
BEGIN
    a:=10;
    b:=20;
    c:=FINDMAX(a,b);
    dbms_output.PUT_LINE('max element : ' ||c);
end;
