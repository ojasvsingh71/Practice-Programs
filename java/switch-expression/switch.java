import java.util.*;

class chonchu{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        int n=sc.nextInt();

        // switch(n){
        //     case 1 : System.out.println("case 1");
        //     case 2 : System.out.println("case 2");
        //     case 3 : System.out.println("case 3");
        //     case 4 : System.out.println("case 4");
        // }

        // switch(n){
        //     case 1 -> System.out.println("case 1");
        //     case 2 -> System.out.println("case 2");
        //     case 3 -> System.out.println("case 3");
        //     case 4 -> System.out.println("case 4");
        //     default-> System.out.println("default");
        // }

        String ans=switch(n){
            case 1 -> "first case";
            case 2 -> {
                System.out.println("case 2");
                yield "ojasv";   
            }
            case 3 -> {
                System.out.println("case 3");
                yield "ojasv3";
            }
            case 4 -> {
                System.out.println("case 4");
                yield "ojasv4";
            }
            default-> {
                System.out.println("default");
                yield "default";
            }
        };
        System.out.println(ans);
    }
}