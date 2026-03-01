import 'dart:io';

double add(double a, double b) => a + b;
double subtract(double a, double b) => a - b;
double multiply(double a, double b) => a * b;
double divide(double a, double b) => a / b;

void main() {
  print("Hello World!!!");
  stdout.write("Enter first number: ");
  double num1 = double.parse(stdin.readLineSync()!);

  stdout.write("Enter second number: ");
  double num2 = double.parse(stdin.readLineSync()!);

  print("\nChoose operation:");
  print("1. Addition");
  print("2. Subtraction");
  print("3. Multiplication");
  print("4. Division");
  stdout.write("Enter choice 1-4: ");

  int choice = int.parse(stdin.readLineSync()!);

  double result;

  switch (choice) {
    case 1:
      result = add(num1, num2);
      break;
    case 2:
      result = subtract(num1, num2);
      break;
    case 3:
      result = multiply(num1, num2);
      break;
    case 4:
      if (num2 == 0) {
        print("Error: Cannot divide by zero.");
        return;
      }
      result = divide(num1, num2);
      break;
    default:
      print("Invalid choice!");
      return;
  }

  print("\nResult: $result");
}