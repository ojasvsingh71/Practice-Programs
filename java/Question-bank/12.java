// 12.	Illustrate abstract class and customize an abstract class 'Bank' with an abstract method 'getBalance'. ForExample: $100, $150 and $200 are deposited in banks A, B and C respectively. 'BankA', 'BankB' and 'BankC' are subclasses of class 'Bank', each having a method named 'getBalance'. Call this method by creating an object of each of the three classes and Print balance of each Bank as BankABalance$100 BankBBalance$150 BankCBalance$200

// Test Case:
// case= 1
// input= $100 $150 $200
// output= BankABalance$100 BankBBalance$150 BankCBalance$200
 
// case= 2
// input= $200 $100 $300
// output= BankABalance$200 BankBBalance$100 BankCBalance$300
 
// case= 3
// input= $300 $200 $400
// output= BankABalance$300 BankBBalance$200 BankCBalance$400

import java.util.*;

abstract class Bank{
    abstract void getBalance();
}

class BankA extends Bank{
    int balance;
    BankA(int balance){
        this.balance=balance;
    }
    void getBalance(){
        System.out.print("BankABalance$"+this.balance+" ");
    }
}

class BankB extends Bank{
    int balance;
    BankB(int balance){
        this.balance=balance;
    }
    void getBalance(){
        System.out.print("BankBBalance$"+this.balance+" ");
    }
}

class BankC extends Bank{
    int balance;
    BankC(int balance){
        this.balance=balance;
    }
    void getBalance(){
        System.out.print("BankCBalance$"+this.balance+" ");
    }
}

class chonchu12{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        String s=sc.nextLine();
        String []n=s.split(" ");

        Bank a=new BankA(Integer.parseInt(n[0].substring(1)));
        Bank b=new BankB(Integer.parseInt(n[1].substring(1)));
        Bank c=new BankC(Integer.parseInt(n[2].substring(1)));

        a.getBalance();
        b.getBalance();
        c.getBalance();
    }
}