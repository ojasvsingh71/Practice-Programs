import java.util.*;

class vec{
    public static void main(String []arg){
        Vector<Integer> chonchu=new Vector<>();
        chonchu.add(50);
        chonchu.add(50);
        chonchu.add(20);
        chonchu.add(60);
        chonchu.add(10);
        System.out.println(chonchu);
        chonchu.remove(1);
        System.out.println(chonchu);
        Collections.reverse(chonchu);
        System.out.println(chonchu);
    }
}