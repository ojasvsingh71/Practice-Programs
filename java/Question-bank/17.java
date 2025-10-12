// 17.	Write a Java program using the Stack collection class to:
// 1.	Push elements into a stack.
// 2.	Display all elements in the stack.
// 3.	Pop the top element. // alwys check stack isEmpty() while pop and peek
// 4.	Peek at the top element without removing it.
// 5.	Search for a given element in the stack.
// Test Case 1
// Input:
// 5
// 10 20 30 40 50
// 30
// Output
// tack Elements: [10, 20, 30, 40, 50]
// Popped Element: 50
// Top Element (Peek): 40
// 30 found at position (from top): 2
// Test Case 2 (Edge Case: Empty stack after pop)
// Input:
// 1
// 99
// 50
// Output:
// Stack Elements: [99]
// Popped Element: 99
// Stack is empty, no top element!
// 50 not found in stack
// Test Case 2
// Input:
// 3
// 5 15 25
// 10
// Output:
// Stack Elements: [5, 15, 25]
// Popped Element: 25
// Top Element (Peek): 15
// 10 not found in stack

import java.util.*;

class chonchu17{
    public static void main(String arg[]){
        Scanner sc=new Scanner(System.in);
        int n=sc.nextInt();
        Stack<Integer> st=new Stack<>();

        for(int i=0;i<n;i++){
            st.push(sc.nextInt());
        }
        int target=sc.nextInt();

        System.out.println("Stack Elements: "+st);

        if(!st.isEmpty()){
            System.out.println("Popped Element: "+st.pop());
        }
        
        if(!st.isEmpty()){
            System.out.println("Top Element: "+st.peek());
        }
        int index=st.search(target);
        if(index!=-1){
            System.out.println(target+" found at position (from the top): "+index);
        }else{
            System.out.println(target+" not found in stack");
        }
    }
}