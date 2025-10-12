// 16.	Write a Java program using TreeSet to:
// 1.	Insert a set of integers.
// 2.	Print all elements in sorted order.
// 3.	Check tree is empty or not
// 4.	Check tree has only one element then smallest and largest will be equal
// 5.	Find and print the smallest element.
// 6.	Find and print the largest element.
// Test Case 1
// Input:
// 5
// 20 5 15 30 10
// Output:
// TreeSet Elements: [5, 10, 15, 20, 30]
// Smallest Element: 5
// Largest Element: 30
//    Test Case 2
// Input:
// 6
// 100 50 200 150 75 25
// Output:
// TreeSet Elements: [25, 50, 75, 100, 150, 200]
// Smallest Element: 25
// Largest Element: 200

import java.util.*;

class chonchu16{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        TreeSet<Integer> ts=new TreeSet<>();
        int n=sc.nextInt();
        for(int i=0;i<n;i++){
            ts.add(sc.nextInt());
        }

        System.out.println("TreeSet Elements: "+ts);
        System.out.println("Smallest Element: "+ts.first());
        System.out.println("Largest Elements: "+ts.last());
    }
}