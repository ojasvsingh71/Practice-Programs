// Q8 A school wants to store and manage student marks for subjects.
// Each student can have multiple subjects with marks.
// •	Store student name as key, and a Map of subjects and marks as value.
// •	Display all students with their subject-wise marks.
// •	Find the student with the highest total marks.

import java.util.*;

class chonchu8{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        HashMap<String,HashMap<String,Integer>> mp=new HashMap<>();

        int n=sc.nextInt();
        sc.nextLine();
        for(int i=0;i<n;i++){
            String s=sc.nextLine();
            String ss[]=s.split(" ");
            String name=ss[0];
            String sub=ss[1];
            int marks=Integer.parseInt(ss[2]);
            
            mp.putIfAbsent(name,new HashMap<>());
            mp.get(name).put(sub,marks);
        }
        String max_name="";
        int maxi=0;
        for(Map.Entry<String,HashMap<String,Integer>> entry:mp.entrySet()){
            String name=entry.getKey();
            HashMap<String,Integer> marks=entry.getValue();
            System.out.println(name+":");
            int m=0;
            for(Map.Entry<String,Integer> bu:marks.entrySet()){
                System.out.println(bu.getKey()+":"+bu.getValue());
                m+=bu.getValue();
            }
            if(m>maxi){
                maxi=m;
                max_name=entry.getKey();
            }
        }
        System.out.println("Student with maximum marks is : "+max_name);
    }
}