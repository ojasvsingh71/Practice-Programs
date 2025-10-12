// Q6 find minimum and maximum element in a tree set

import java.util.*;

class chonchu6{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        TreeSet<Integer> ts=new TreeSet<>();

        String s=sc.nextLine();
        String ss[]=s.split(" ");
        for(String t:ss){
            ts.add(Integer.parseInt(t));
        }

        System.out.println(ts);
        System.out.println(ts.first());
        System.out.println(ts.last());
    }
}