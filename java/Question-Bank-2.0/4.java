// Q4 Find Largest word in a given string using array List.

import java.util.*;

class chonchu4{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        List<String> ls=new ArrayList<>();
        String s=sc.nextLine();
        String []ss=s.split(" ");
        String ans="";
        int maxi=0;
        for(String k:ss){
            ls.add(k);
            if(k.length()>maxi){
                maxi=k.length();
                ans=k;
            }
        }System.out.println(ls);
        System.out.println("Largest element is : "+ans);
    }
}