// 13.	Solve below program using treeset
// 1.	Create a TreeSet of Strings to store fruit names.
// 2.	Add the following fruits to the TreeSet:
// o	"Banana"
// o	"Apple"
// o	"Mango"
// o	"Grapes"
// o	"Apple" (duplicate - should not be added)
// 3.	Display the contents of the TreeSet.
// 4.	Check whether "Mango" and "Orange" exist in the set.
// 5.	Remove "Grapes" from the set and display the updated set.
// 6.	Iterate and display all elements in sorted order.
// 7.	Display the total number of fruits in the set.
// 8.	Clear the entire set and confirm that it is empty.
// ________________________________________
// 🔍 Test Cases:
// Test Case	Operation	Expected Result
// TC1	Add fruits + duplicate check	Only unique fruits, sorted in alphabetical order
// TC2	Search "Mango" and "Orange"	Mango = true, Orange = false
// TC3	Remove "Grapes"	Set no longer contains "Grapes"
// TC4	Iterate and display elements	Output in alphabetical order
// TC5	Display size	Count of unique fruits after modifications
// TC6	Clear set and check if empty	Set becomes empty, isEmpty() returns true

import java.util.*;

class chonchu13{
    public static void main(String arg[]){
        Set<String> ts=new TreeSet<>();
        ts.add("Banana");
        ts.add("Apple");
        ts.add("Mango");
        ts.add("Grapes");
        ts.add("Apple");

        System.out.println(ts);

        if(ts.contains("Mango")) System.out.println("Mango present");
        if(ts.contains("Orange")) System.out.println("Orange present");

        ts.remove("Grapes");

        System.out.println(ts);
        
        for(String fruit:ts) System.out.println(fruit);

        System.out.println(ts.size());

        ts.clear();

        if(ts.isEmpty()) System.out.println("TreeSet is empty");
    }
}
