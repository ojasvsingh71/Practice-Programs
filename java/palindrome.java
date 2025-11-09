import java.util.*;

class chonchu18{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        String s=sc.nextLine();
        Stack<String> st=new Stack<>();

        String ss[]=s.split("");
        for(String t:ss){
            st.push(t);
        }
        String rev="";
        int n=st.size();
        for(int i=0;i<n;i++){
            rev+=st.pop();
        }
        if(rev.equals(s)){
            System.out.println("Palindrome");
        }
         else   System.out.println("Not Palindrome");

    }
}