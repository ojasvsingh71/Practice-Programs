// 15.	Write a Java program using HashMap to:
// 1.	Insert employee details (EmployeeID → Salary).
// 2.	Print all employee details.
// 3.	Search for a given EmployeeID and print the salary.
// 4.	Remove an employee using their EmployeeID.
// 5.	Print the updated employee list.
// 6.	Check for map is empty or not
// Case : All Employees:
// 101 => 50000
// 102 => 60000
// 103 => 45000
// 104 => 70000

// Employee 102 Salary: 60000

// After Removing 103:
// 101 => 50000
// 102 => 60000
// 104 => 70000

import java.util.*;

class chonchu15{
    public static void main(String arg[]){
        Map<Integer,Integer> mp=new HashMap<>();

        mp.put(101,50000);
        mp.put(102,60000);
        mp.put(103,45000);
        mp.put(104,70000);

        System.out.println(mp);

        System.out.println(mp.get(102));

        mp.remove(103);

        System.out.println(mp);

        if(mp.isEmpty()) System.out.println("Map is empty");
        else System.out.println("Map is not empty");
    }
}
