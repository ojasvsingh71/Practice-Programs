import java.util.*;

class fib{
    static HashMap<Integer,Integer> mp=new HashMap<>();

    static int fibu(int n){
        if(n==1 || n==0) return n;
        if(mp.containsKey(n)) return mp.get(n);
        mp.put(n,fibu(n-1)+fibu(n-2));
        return mp.get(n);
    }

    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        int n=sc.nextInt();

        System.out.println(fibu(n));
    }
}