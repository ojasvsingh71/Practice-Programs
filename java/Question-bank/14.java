// 14.	Write a Java program using HashMap to:
// 1.	Store the student names (String) as keys and their marks (Integer) as values.
// 2.	Print all student details.
// 3.	Search for a particular student and print their marks.
// 4.	Remove a student from the HashMap.
// 5.	Print the updated HashMap.
// 6.	Check for map is empty or not

import java.util.*;

class chonchu14{
    public static void main(String arg[]){
        Map<String,Integer> mp=new HashMap<>();

        mp.put("ojasv",91);
        mp.put("milind",93);
        mp.put("khushi",95);
        mp.put("ojasv",92);
        mp.put("akshat",91);
        mp.put("milind",91);

        System.out.println(mp);

        System.out.println(mp.get("khushi"));

        mp.remove("ojasv");
        System.out.println(mp);

        if(mp.isEmpty()) System.out.println("Map is empty");
        else System.out.println("Map is not empty");
    }
}