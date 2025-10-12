// Q2. A store maintains an inventory of products.
// Each product has a unique productId, name, price, and quantity.
// There are two types of products:
// 1.	Electronics – has an additional field warrantyInMonths
// 2.	Grocery – has an additional field expiryDate
// The store should be able to:
// •	Add a new product to the inventory
// •	Display all products
// •	Find a product by its ID
// •	Update quantity of a product
// •	Calculate total inventory value

import java.util.*;

class Product{
    int productId;
    String name;
    int price;
    String quantity;
}

class Electronics extends Product{
    String warrantyInMonths;
}

class Grocery extends Product{
    String expiryDate;
}

class chonchu2{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        Product e=new Electronics();
        Product g=new Grocery();
        e.productId=sc.nextInt();
        e.name=sc.next();
        e.price=sc.nextInt();
        
        g.productId=sc.nextInt();   
        g.name=sc.next();
        g.price=sc.nextInt();

        System.out.println(e.name);
        System.out.println(g.name);
    }
}