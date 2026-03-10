// 1. Write a Dart program that defines a function performOperation()
// which accepts two numbers and a callback function.
// The callback should perform addition, subtraction, or
// multiplication based on user choice.

void performOperation(int a,int b,Function operate){
  int result=operate(a,b);
  print("Result ${result}");
}

int add(int a,int b){
  return a+b;
}

int subtract(int a,int b){
  return a-b;
}

int multiply(int a,int b){
  return a*b;
}



// 2. Create a function greetUser() that accepts a username and a
// callback function.
// The callback should print a personalized welcome message.

void greetUser(String username,Function greet){
  greet(username);
}

void greet(String name){
  print("Welcome $name");
}


void main(){
  int a=5,b=10;
  String op="+";

  switch (op){
    case "+":
      performOperation(a,b,add);
      break;
    case "-":
      performOperation(a,b,subtract);
      break;
    case "*":
      performOperation(a,b,multiply);
      break;
    default:
      break;
  }

  greetUser("Ojasv",greet);
}