create table students(
    student_id VARCHAR2(30) primary key,
    first_name varchar2(30) not null,
    last_name varchar2(30) not null,
    student_email VARCHAR2(30) not null,
    student_dob date not null,
    program_id varchar2(30) not null,
    total_marks number not null,

    foreign key(program_id) references programs(program_id)
);


create table programs(
    program_id VARCHAR2(30) primary key,
    program_name VARCHAR2(30) not null
);


INSERT INTO programs (program_id, program_name) VALUES ('P001', 'B.Tech CSE');
INSERT INTO programs (program_id, program_name) VALUES ('P002', 'B.Tech ECE');
INSERT INTO programs (program_id, program_name) VALUES ('P003', 'B.Tech Mechanical');
INSERT INTO programs (program_id, program_name) VALUES ('P004', 'B.Tech Civil');
INSERT INTO programs (program_id, program_name) VALUES ('P005', 'BCA');
INSERT INTO programs (program_id, program_name) VALUES ('P006', 'MCA');
INSERT INTO programs (program_id, program_name) VALUES ('P007', 'B.Sc IT');
INSERT INTO programs (program_id, program_name) VALUES ('P008', 'BBA');
INSERT INTO programs (program_id, program_name) VALUES ('P009', 'MBA');
INSERT INTO programs (program_id, program_name) VALUES ('P010', 'M.Tech CSE');

INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU001', 'Aarav', 'Sharma', 'aarav.sharma@gmail.com', TO_DATE('2004-05-12','YYYY-MM-DD'), 'P001', 892);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU002', 'Priya', 'Verma', 'priya.verma@gmail.com', TO_DATE('2005-02-18','YYYY-MM-DD'), 'P001', 934);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU003', 'Aditya', 'Singh', 'aditya.singh@gmail.com', TO_DATE('2004-11-25','YYYY-MM-DD'), 'P002', 821);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU004', 'Ananya', 'Gupta', 'ananya.gupta@gmail.com', TO_DATE('2005-07-09','YYYY-MM-DD'), 'P001', 967);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU005', 'Rohan', 'Mehta', 'rohan.mehta@gmail.com', TO_DATE('2004-03-21','YYYY-MM-DD'), 'P003', 786);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU006', 'Sneha', 'Patel', 'sneha.patel@gmail.com', TO_DATE('2005-09-14','YYYY-MM-DD'), 'P005', 912);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU007', 'Arjun', 'Kumar', 'arjun.kumar@gmail.com', TO_DATE('2004-01-30','YYYY-MM-DD'), 'P002', 854);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU008', 'Kavya', 'Reddy', 'kavya.reddy@gmail.com', TO_DATE('2005-06-17','YYYY-MM-DD'), 'P004', 879);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU009', 'Rahul', 'Yadav', 'rahul.yadav@gmail.com', TO_DATE('2004-08-05','YYYY-MM-DD'), 'P003', 743);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU010', 'Ishita', 'Malhotra', 'ishita.malhotra@gmail.com', TO_DATE('2005-12-11','YYYY-MM-DD'), 'P005', 956);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU011', 'Vivek', 'Joshi', 'vivek.joshi@gmail.com', TO_DATE('2004-04-19','YYYY-MM-DD'), 'P006', 817);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU012', 'Neha', 'Chauhan', 'neha.chauhan@gmail.com', TO_DATE('2005-10-23','YYYY-MM-DD'), 'P007', 901);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU013', 'Karan', 'Agarwal', 'karan.agarwal@gmail.com', TO_DATE('2004-02-07','YYYY-MM-DD'), 'P008', 768);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU014', 'Riya', 'Mishra', 'riya.mishra@gmail.com', TO_DATE('2005-05-29','YYYY-MM-DD'), 'P001', 945);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU015', 'Siddharth', 'Tiwari', 'siddharth.tiwari@gmail.com', TO_DATE('2004-09-03','YYYY-MM-DD'), 'P002', 833);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU016', 'Pooja', 'Saxena', 'pooja.saxena@gmail.com', TO_DATE('2005-01-16','YYYY-MM-DD'), 'P006', 889);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU017', 'Yash', 'Bansal', 'yash.bansal@gmail.com', TO_DATE('2004-06-24','YYYY-MM-DD'), 'P007', 776);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU018', 'Simran', 'Kaur', 'simran.kaur@gmail.com', TO_DATE('2005-03-08','YYYY-MM-DD'), 'P008', 918);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU019', 'Manish', 'Thakur', 'manish.thakur@gmail.com', TO_DATE('2004-12-27','YYYY-MM-DD'), 'P003', 805);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU020', 'Nandini', 'Iyer', 'nandini.iyer@gmail.com', TO_DATE('2005-08-15','YYYY-MM-DD'), 'P004', 932);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU021', 'Akash', 'Srivastava', 'akash.srivastava@gmail.com', TO_DATE('2004-07-02','YYYY-MM-DD'), 'P010', 874);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU022', 'Megha', 'Nair', 'megha.nair@gmail.com', TO_DATE('2005-11-19','YYYY-MM-DD'), 'P009', 947);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU023', 'Varun', 'Kapoor', 'varun.kapoor@gmail.com', TO_DATE('2004-10-10','YYYY-MM-DD'), 'P010', 819);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU024', 'Aditi', 'Shukla', 'aditi.shukla@gmail.com', TO_DATE('2005-04-04','YYYY-MM-DD'), 'P006', 963);
INSERT INTO students
(student_id, first_name, last_name, student_email, student_dob, program_id, total_marks)
VALUES
('STU025', 'Mohit', 'Saini', 'mohit.saini@gmail.com', TO_DATE('2004-03-15','YYYY-MM-DD'), 'P005', 731);

