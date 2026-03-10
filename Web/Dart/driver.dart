/*
===========================================================
Dart Assignment - Moodle Template
Course: Flutter & Dart Programming
Syllabus Coverage:
- Functions & Control Flow (Calculator)
- Lists & Loops (Todo Logic)
- OOP (Classes, Inheritance, Encapsulation)
- Async / Future / async-await
Instructions:
- DO NOT change function names
- DO NOT modify driver function
- Implement logic only inside marked sections
- Each function carries 1 mark
===========================================================
*/

/*
-----------------------------------------------------------
DUMMY DATA
-----------------------------------------------------------
*/

List<String> todoList = ["Buy Milk", "Study Dart", "Submit Assignment"];

Map<String, dynamic> studentData = {
  "name": "Aarav",
  "id": 101,
  "course": "B.Tech"
};

/*
-----------------------------------------------------------
OOP CLASSES (DO NOT MODIFY)
-----------------------------------------------------------
*/

class Person {
  String name;

  Person(this.name);

  String getRole() {
    return "Person";
  }
}

class Student extends Person {
  int id;
  String course;

  Student(String name, this.id, this.course) : super(name);

  @override
  String getRole() {
    return "Student";
  }
}

class Professor extends Person {
  String subject;

  Professor(String name, this.subject) : super(name);

  @override
  String getRole() {
    return "Professor";
  }
}

/*
-----------------------------------------------------------
FUNCTION 1
-----------------------------------------------------------
Purpose:
Perform basic arithmetic using SWITCH statement

Parameters:
- a (int)
- b (int)
- operator (String: "+", "-", "*", "/")

Constraints:
- Must use switch
- Handle division by zero

Base Test Cases:
calculate(10, 5, "+") → 15
calculate(10, 0, "/") → "Error"
*/

dynamic calculate(int a, int b, String operator) {
  // STUDENT CODE STARTS HERE
  switch (operator){
    case "+":
      return a+b;
    case "-":
      return a-b;
    case "*":
      return a*b;
    case "/":
      if(b==0) return "Error";
      return a/b;
  }

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 2
-----------------------------------------------------------
Purpose:
Add a task to Todo list

Parameters:
- list (List<String>)
- task (String)

Constraints:
- Must use list methods
- Return updated list

Base Test Cases:
addTask(["A"], "B") → ["A", "B"]
*/

List<String> addTask(List<String> list, String task) {
  // STUDENT CODE STARTS HERE
  list.add(task);
  return list;
  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 3
-----------------------------------------------------------
Purpose:
Remove a task from Todo list

Parameters:
- list (List<String>)
- task (String)

Constraints:
- Must use loop or remove()
- Return updated list

Base Test Cases:
removeTask(["A","B"], "A") → ["B"]
*/

List<String> removeTask(List<String> list, String task) {
  // STUDENT CODE STARTS HERE
  list.remove(task);
  return list;

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 4
-----------------------------------------------------------
Purpose:
View all tasks

Parameters:
- list (List<String>)

Constraints:
- Must use loop
- Print tasks using print()

Base Test Cases:
viewTasks(["Task1","Task2"])
→ Prints all tasks
*/

void viewTasks(List<String> list) {
  // STUDENT CODE STARTS HERE
  for(var c in list){
    print(c);
  }

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 5
-----------------------------------------------------------
Purpose:
Create Student object using Map data

Parameters:
- data (Map<String, dynamic>)

Constraints:
- Must return Student object

Base Test Case:
createStudent(studentData) → Student object
*/

Student createStudent(Map<String, dynamic> data) {
  // STUDENT CODE STARTS HERE
  Student s= Student(data["name"],data["id"],data["course"]);
  return s;
  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 6
-----------------------------------------------------------
Purpose:
Display role of a Person (Polymorphism)

Parameters:
- person (Person)

Constraints:
- Must call overridden method

Base Test Cases:
displayRole(Student) → "Student"
displayRole(Professor) → "Professor"
*/

String displayRole(Person person) {
  // STUDENT CODE STARTS HERE
  return person.getRole();

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 7
-----------------------------------------------------------
Purpose:
Count number of tasks using LOOP

Parameters:
- list (List<String>)

Constraints:
- Must use loop
- Return integer count

Base Test Cases:
countTasks(["A","B","C"]) → 3
*/

int countTasks(List<String> list) {
  // STUDENT CODE STARTS HERE
  int len=0;
  for(int i=0;i<list.length;i++) len++;
  return len;

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 8
-----------------------------------------------------------
Purpose:
Simulate fetching data using Future

Parameters:
- message (String)

Constraints:
- Use Future.delayed
- Delay: 2 seconds
- Return Future<String>

Base Test Case:
fetchData("Hello") → Completes with "Hello"
*/

Future<String> fetchData(String message) {
  // STUDENT CODE STARTS HERE
  return Future.delayed(Duration(seconds: 2),(){
    return message;
  });  

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 9
-----------------------------------------------------------
Purpose:
Use ASYNC/AWAIT to consume Future

Parameters:
- future (Future<String>)

Constraints:
- Must use async/await
- Print result

Base Test Case:
await consumeFuture(fetchData("Done"))
→ Prints "Done"
*/

Future<void> consumeFuture(Future<String> future) async {
  // STUDENT CODE STARTS HERE
  print(await future);

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 10
-----------------------------------------------------------
Purpose:
Create Professor object

Parameters:
- name (String)
- subject (String)

Constraints:
- Must return Professor object

Base Test Case:
createProfessor("Dr. Kumar", "AI")
→ Professor object
*/

Professor createProfessor(String name, String subject) {
  // STUDENT CODE STARTS HERE
  Professor p=Professor(name,subject);
  return p;

  // STUDENT CODE ENDS HERE
}

/*
-----------------------------------------------------------
FUNCTION 11 (DRIVER FUNCTION)
-----------------------------------------------------------
Purpose:
Test all student functions
DO NOT MODIFY THIS FUNCTION
-----------------------------------------------------------
*/

void driver() async {
  print("---- DART ASSIGNMENT DRIVER START ----");

  print("Calculator: ${calculate(10, 5, "+")}");
  print("Calculator Error: ${calculate(10, 0, "/")}");

  todoList = addTask(todoList, "Practice Flutter");
  todoList = removeTask(todoList, "Buy Milk");
  viewTasks(todoList);

  print("Task Count: ${countTasks(todoList)}");

  Student student = createStudent(studentData);
  Professor professor = createProfessor("Dr. Kumar", "AI");

  print("Student Role: ${displayRole(student)}");
  print("Professor Role: ${displayRole(professor)}");

  await consumeFuture(fetchData("Data Loaded Successfully"));

  print("---- DART ASSIGNMENT DRIVER END ----");
}

/*
-----------------------------------------------------------
RUN DRIVER
-----------------------------------------------------------
*/

void main()  {
   driver();
}
