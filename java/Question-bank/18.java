// 18.	A company maintains a task list where each task is stored in the order it was assigned.
// You are asked to use LinkedList in Java to manage the tasks with the following operations:
// 1.	Add tasks to the list.
// 2.	Display all tasks.
// 3.	Remove the first task (task completed).
// 4.	Remove the last task (canceled).
// 5.	Search for a particular task in the list.
// Test Case 1
// Input:
// 4
// Prepare Report
// Team Meeting
// Code Review
// Client Call
// Team Meeting
// Output:
// All Tasks: [Prepare Report, Team Meeting, Code Review, Client Call]
// Completed Task: Prepare Report
// Canceled Task: Client Call
// Team Meeting is in the task list.
// Remaining Tasks: [Team Meeting, Code Review]
// ________________________________________
// Test Case 2
// Input:
// 3
// Design UI
// Fix Bugs
// Write Documentation
// Fix Bugs
// Output:
// All Tasks: [Design UI, Fix Bugs, Write Documentation]
// Completed Task: Design UI
// Canceled Task: Write Documentation
// Fix Bugs is in the task list.
// Remaining Tasks: [Fix Bugs]
// ________________________________________
// Test Case 3 (Edge Case: Only one task)
// Input:
// 1
// Deploy Application
// Deploy Application
// Output:
// All Tasks: [Deploy Application]
// Completed Task: Deploy Application
// Remaining Tasks: []
// Deploy Application not found in the task list.

import java.util.*;

class chonchu18{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        int n=sc.nextInt();
        LinkedList<String> ls=new LinkedList<>();
        sc.nextLine();
        for(int i=0;i<n;i++){
            ls.add(sc.nextLine());
        }
        String target=sc.nextLine();
        System.out.println("All Tasks: "+ls);

        System.out.println("Completed task: "+ls.removeFirst());
        System.out.println("Removed task: "+ls.removeLast());

        if(ls.contains(target)){
            System.out.println(target+" is in the list");
        }else{
            System.out.println(target+" is not in the list");
        }
    }
}