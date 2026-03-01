import 'dart:io';

void main() {
  List<String> todoList = [];

  while (true) {
    print("\n---- TODO LIST MENU ----");
    print("1. Add Task");
    print("2. View Tasks");
    print("3. Remove Task");
    print("4. Exit");

    stdout.write("Enter your choice: ");
    int choice = int.parse(stdin.readLineSync()!);

    switch (choice) {
      case 1:
        stdout.write("Enter task to add: ");
        String task = stdin.readLineSync()!;
        todoList.add(task);
        print("Task added!");
        break;

      case 2:
        print("\n---- Current Tasks ----");
        if (todoList.isEmpty) {
          print("No tasks available.");
        } else {
          for (int i = 0; i < todoList.length; i++) {
            print("${i + 1}. ${todoList[i]}");
          }
        }
        break;

      case 3:
        if (todoList.isEmpty) {
          print("No tasks to remove.");
          break;
        }

        stdout.write("Enter task number to remove: ");
        int index = int.parse(stdin.readLineSync()!);

        if (index > 0 && index <= todoList.length) {
          todoList.removeAt(index - 1);
          print("Task removed!");
        } else {
          print("Invalid task number.");
        }
        break;

      case 4:
        print("Exiting... Goodbye!");
        return;

      default:
        print("Invalid choice, try again.");
    }
  }
}
