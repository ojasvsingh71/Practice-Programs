// Q11.  In a bank, each account has a certain balance.
// Write a Java program to demonstrate a customized exception named InsufficientBalanceException.
// If a user tries to withdraw an amount greater than the current balance,
// the program should throw the exception with the message "Insufficient Balance!".

import java.util.*;

class InsufficientBalanceException extends Exception{
    InsufficientBalanceException(){
        super("Insufficient Balance!");
    }
}

class chonchu11{

    static void doing(int balance,int withdraw)throws InsufficientBalanceException{
        if(withdraw>balance) {
            throw new InsufficientBalanceException();
        }else{
            System.out.println("Withdraw Successful!");
        }
    }

    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        int number=sc.nextInt();
        int balance=sc.nextInt();
        int withdraw=sc.nextInt();
        try{
            doing(balance,withdraw);
        }catch (InsufficientBalanceException e){
            System.out.println(e.getMessage());
        }
    }
}