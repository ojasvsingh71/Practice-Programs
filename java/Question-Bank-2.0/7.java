// Q7 Implement reverse a string using Stack, and without stack.

import java.util.*;

class chonchu7{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        String s=sc.nextLine();
        String ss[]=s.split("");

        Stack<String> st=new Stack<>();
        for(String c:ss){
            st.push(c);
        }
        System.out.println(st);
        String rev="";
        int n=st.size();
        for(int i=0;i<n;i++){
            rev+=st.pop();
        }
        System.out.println(rev);
        System.out.println(new StringBuilder(s).reverse());
    }
}