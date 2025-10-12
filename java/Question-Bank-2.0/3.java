// Q3 find freequency of word in a given string using array List.

import java.util.*;

class chonchu3{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        ArrayList<String> ls=new ArrayList<>();
        String s=sc.nextLine();
        String []ss=s.split(" ");
        for(String w:ss){
            ls.add(w);
        }
        // sc.next();
        String tar=sc.nextLine();
        System.out.println(ls);
        int count=0;
        for(String k:ls){
            if(k.equals(tar)) count++;
        }
        System.out.println(count);
    }
}