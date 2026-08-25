BEGIN
    dbms_output.PUT_LINE('hello world');
END;



DECLARE
a number(5);
b number(5);
c number(5);

BEGIN
    a:=100;
    b:=110;
    c:=a+b;
    dbms_output.PUT_LINE(c);
end;



DECLARE
today date :=sysdate;

begin
    dbms_output.PUT_LINE(
        'today is ' || to_char(today,'Day'));
    exception when others then 
        dbms_output.PUT_LINE(sqlerrm);
end;




create table student(
    student_id varchar2(20) primary key,
    first_name VARCHAR2(20),
    last_name VARCHAR2(20),
    city VARCHAR2(20),
    marks number(10)
);



insert into student values(120,'Ojasv','Singh','Lucknow',95);



DECLARE
v_first_name varchar2(35);
v_last_name varchar2(35);

BEGIN
    SELECT first_name, last_name
    INTO v_first_name, v_last_name
    FROM student
    WHERE student_id=120;
    dbms_output.PUT_LINE('Student name: '|| v_first_name ||' ' || v_last_name);
END;




DECLARE
mark VARCHAR2(30);

BEGIN
    SELECT marks
    into mark
    from student
    where marks>196;
    DBMS_OUTPUT.PUT_LINE('highest marks is ' || mark);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    dbms_output.PUT_LINE('there is no data');
end;





DECLARE
    v_student_id VARCHAR2(30) :=&v_student_id;
    v_first_name VARCHAR2(30);
    v_last_name VARCHAR2(30);

begin
    select first_name, last_name
    into v_first_name, v_last_name
    from student 
    where student_id=v_student_id;
    dbms_output.PUT_LINE('The result student is '|| v_first_name || ' ' || v_last_name);
end;




SET SERVEROUTPUT ON
<< outer_block>>

DECLARE 
    v_test NUMBER :=123;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Outer block, v_test: '||v_test);
        << inner_block>>
        DECLARE
            v_test NUMBER:=456;
        BEGIN
            DBMS_OUTPUT.PUT_LINE('Inner block, v_test: '|| v_test);
            DBMS_OUTPUT.PUT_LINE('Inner block, v_test: '|| outer_block.v_test);
        END;
END;




DECLARE
    l_today date:=sysdate;
BEGIN
    if to_char(l_today,'D') < 4 THEN
        dbms_output.PUT_LINE(
            'Have a wonderful week'
        );
    else 
        dbms_output.PUT_LINE(
            'Enjoy the rest of the week'
        );
    END IF;
    dbms_output.PUT_LINE(
        'today is '||
        to_char(l_today,'Day') ||
        'day ' || to_char(l_today,'D') ||
        ' of the week.'
    );
END;




BEGIN
    for i in 1..5 loop
        dbms_output.PUT_LINE(i);
    end loop;
end;




DECLARE 
    i number:=1;
BEGIN
    WHILE i<=5 LOOP
        dbms_output.put_line(i);
        i:=i+1;
    END LOOP;
END;

