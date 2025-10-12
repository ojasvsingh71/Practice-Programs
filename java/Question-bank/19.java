// 19.	Create a custom exception LowMarksException that is thrown when a student’s marks are less than 50.
// Write a Java program to:
// 1.	Accept student name and marks.
// 2.	Throw and handle the exception if marks < 50.
// 3.	Otherwise, display the student result as PASS.
// Test Case 1
// Input:
// Riya
// 45
// Output:
// Exception Caught: Student Riya failed with marks: 45
// ________________________________________
// Test Case 2
// Input:
// Aman
// 72
// Output:
// Student Aman passed with marks: 72
// ________________________________________
// Test Case 3 (Edge Case: Exactly 50 marks)
// Input:
// Meera
// 50
// Output:
// Student Meera passed with marks: 50

import java.util.*;

class LowMarksException extends Exception{
    LowMarksException(String name,int marks){
        super("Student "+name+" failed with "+marks);
    }
}

class chonchu19{
    static void check(String name,int marks) throws LowMarksException{
        if(marks<50) throw new LowMarksException(name,marks);
    }

    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        String name=sc.nextLine();
        int marks=sc.nextInt();
        try{
            check(name,marks);
            System.out.println("Student "+name+" passed with marks: "+marks);
        }catch(LowMarksException e){
            System.out.println("Exception Caught: "+e.getMessage());
        }
    }
}