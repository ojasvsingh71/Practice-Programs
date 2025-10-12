// 20.	Create two interfaces:
// 1.	Sports → contains method play().
// 2.	Study → contains method read().
// A class Student implements both interfaces and shows how multiple inheritance works in Java.
// Test Case 1
// Input (Student Name):
// Riya
// Output:
// Riya is playing football.
// Riya is studying Java.
// ________________________________________
// 📝 Test Case 2
// Input (Student Name):
// Aman
// Output:
// Aman is playing football.
// Aman is studying Java.
// ________________________________________
// 📝 Test Case 3 (Multiple students in main)
// Code snippet in main:
// Student s3 = new Student("Meera");
// s3.play();
// s3.read();
// Output:
// Meera is playing football.
// Meera is studying Java.

import java.util.*;

interface Sports{
    void play();
}

interface Study{
    void read();
}

class Student implements Study,Sports{
    String name;
    Student(String name){
        this.name=name;
    }
    public void play(){
        System.out.println(this.name+" is playing football");
    }
    public void read(){
        System.out.println(this.name+" is studying java");
    }
}

class chonchu20 {
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        String name=sc.nextLine();
        Student s=new Student(name);
        s.play();
        s.read();
    }
}