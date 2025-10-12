// Q 10. In a bank, each account number is mapped to its balance.
// Write a Java program using  HashMap<Integer, Double>
// to perform the following operations:
// 1.	Add a new account
// 2.	Deposit money
// 3.	Withdraw money
// 4.	Display all accounts and balances

import java.util.*;

class chonchu10{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        Map<Integer,Double> mp=new HashMap<>();

        while(true){
            System.out.println("1. Add a new account\n" +
                   "2. Deposit money\n" +
                   "3. Withdraw money\n" +
                   "4. Display all accounts and balances\n" +
                   "5. Exit");
            
            int n=sc.nextInt();
            if(n==1){
                int number=sc.nextInt();
                mp.put(number,0.0);
            }else if(n==2){
                int number=sc.nextInt();
                double money=sc.nextDouble();
                if(!mp.containsKey(number)){
                    System.out.println("Account does not exits");
                    continue;
                }
                mp.put(number,money);
            }else if(n==3){
                int number=sc.nextInt();
                double Withdraw=sc.nextDouble();

                if(mp.get(number)<Withdraw){
                    System.out.println("Insufficient Balance");
                }else{
                    mp.put(number,mp.get(number)-Withdraw);
                }
            }else if(n==4){
                System.out.println(mp);
            }else if(n==5){
                break;
            }else{
                System.out.println("Enter valid option");
            }
        }
    }
}