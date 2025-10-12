// Q12. An e-commerce platform wants to maintain a shopping cart.
// •	Product: productId, name, price
// •	Cart: List of Products
// Requirements:
// •	Use encapsulation (private fields + getters/setters).
// •	Methods: addToCart(), removeFromCart(), calculateTotal().
// •	Display all products in the cart.

import java.util.*;

class e_commerce{
    private int productId;
    private String name;
    private int price;
    private List<String> Cart=new ArrayList<>();
    private Map<String,Integer> mp=new HashMap<>();

    public void addToCart(int productId,String name,int price){
        this.productId=productId;
        this.name=name;
        this.price=price;
        this.Cart.add(name);
        mp.put(name,price);
    }

    public void removeFromCart(String name){
        this.Cart.remove(name);
    }

    public void calculateTotal(){
        int sum=0;
        for(int i=0;i<Cart.size();i++){
            System.out.print(Cart.get(i)+" ");
            sum+=mp.get(Cart.get(i));
        }System.out.println();
        System.out.println("Total Cost : "+sum);
        
    }
}

class chonchu12{
    public static void main(String arg[]){
        e_commerce e=new e_commerce();
        e.addToCart(101,"muli",150);
        e.addToCart(102,"apple",50);
        e.addToCart(103,"gajar",450);

        e.calculateTotal();

        e.removeFromCart("gajar");

        e.calculateTotal();
    }
}