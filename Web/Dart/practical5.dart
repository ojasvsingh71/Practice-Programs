import 'dart:async';

class Person {
  String _name;
  int _age;

  Person(this._name, this._age);

  String get name => _name;
  int get age => _age;

  set name(String value) => _name = value;
  set age(int value) => _age = value;

  void displayInfo() {
    print("Name: $_name, Age: $_age");
  }
}

class Student extends Person {
  String _studentId;
  List<Course> _courses = [];

  Student(String name, int age, this._studentId) : super(name, age);

  String get studentId => _studentId;

  void enrollCourse(Course course) {
    _courses.add(course);
  }

  void showCourses() {
    print("Courses for $name:");
    for (var course in _courses) {
      print("- ${course.courseName}");
    }
  }
}

class Professor extends Person {
  String _employeeId;
  List<Course> _teachingCourses = [];

  Professor(String name, int age, this._employeeId) : super(name, age);

  void assignCourse(Course course) {
    _teachingCourses.add(course);
  }

  void showCourses() {
    print("Courses taught by $name:");
    for (var course in _teachingCourses) {
      print("- ${course.courseName}");
    }
  }
}

class Course {
  String _courseName;
  String _courseCode;

  Course(this._courseName, this._courseCode);

  String get courseName => _courseName;
  String get courseCode => _courseCode;
}

Future<List<Course>> fetchCoursesFromServer() async {
  print("Fetching courses from server...");
  
  await Future.delayed(Duration(seconds: 2)); 

  return [
    Course("Data Structures", "CS101"),
    Course("Operating Systems", "CS102"),
    Course("Database Systems", "CS103"),
  ];
}

Future<void> main() async {
  // Create objects
  Student student = Student("Ojasv", 19, "S001");
  Professor professor = Professor("Dr. Raju", 45, "P001");

  List<Course> courses = await fetchCoursesFromServer();

  for (var course in courses) {
    student.enrollCourse(course);
    professor.assignCourse(course);
  }

  print("\n--- Student Info ---");
  student.displayInfo();
  student.showCourses();

  print("\n--- Professor Info ---");
  professor.displayInfo();
  professor.showCourses();
}