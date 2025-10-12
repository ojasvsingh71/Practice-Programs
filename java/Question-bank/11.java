// 11.	Consider a real-world scenario involving an Employee system where different types of employees (like Manager and Developer) have different implementations for the calculateSalary method.  Implement given scenario using Run Time Polymorphism to demonstrate how each employee type calculates their salary differently.
// ForExample: When user enters ManagerA basicsalary as 80000 and bonus as 20000, whereas DeveloperA basicsalary as 70000 and overtime as 10000 then output should be ManagerASalary as 100000 DeveloperASalary as 80000

// Test Cases:
// case= 1
// input= ManagerA 80000 20000 DeveloperA 70000 10000
// output= ManagerASalary 100000 DeveloperASalary 80000
 
 
// case= 2
// input= ManagerB 90000 20000 DeveloperB 60000 10000
// output= ManagerBSalary 110000 DeveloperBSalary 70000
 
// case= 3
// input= ManagerC 70000 20000 DeveloperC 50000 10000
// output= ManagerCSalary 90000 DeveloperCSalary 60000

import java.util.*;

class Employee{
    String name;
    int basicsalary;
    Employee(String name,int basicsalary){
        this.name=name;
        this.basicsalary=basicsalary;
    }
    void calculateSalary(){}
}

class Manager extends Employee{
    int bonus;
    Manager(String name,int basicsalary,int bonus){
        super(name,basicsalary);
        this.bonus=bonus;
    }
    void calculateSalary(){
        System.out.print(super.name+"Salary "+(super.basicsalary+this.bonus));
    }
}

class Developer extends Employee{
    int overtime;
    Developer(String name,int basicsalary,int overtime){
        super(name,basicsalary);
        this.overtime=overtime;
    }
    void calculateSalary(){
        System.out.print(super.name+"Salary "+(super.basicsalary+this.overtime));
    }
}

class chonchu11{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        String Manager=sc.nextLine();

        String []m_data=Manager.split(" ");
        // System.out.println(Manager);

        Employee m=new Manager(m_data[0],Integer.parseInt(m_data[1]),Integer.parseInt(m_data[2]));
        Employee d=new Developer(m_data[3],Integer.parseInt(m_data[4]),Integer.parseInt(m_data[5]));

        m.calculateSalary();
        System.out.print(" ");
        d.calculateSalary();
    }
}