// WAP to return the day position of a week using switch expression an return illegalStateException using default

import java.util.*;

class week{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        String day=sc.nextLine();

        int n=switch(day){
            case "sunday","monday","friday" -> 6;
            case "tuesday" -> 7;
            case "thursday","saturday" -> 8;
            case "wednesday" -> 9;
            default -> throw new IllegalStateException("this a wrong input");
        };

        System.out.println(n);
    }
}