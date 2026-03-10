class Courses{
  List? subjects;
  Courses(this.subjects);
}

class Person extends Courses{
  String? name;

  Person(this.name,List subjects) : super(subjects);
}

class Student extends Person{
  int? id;

  Student(this.id,String name,List subjects) : super(name,subjects);
}

class Professor extends Person{
  Professor(String name,List subjects) : super(name,subjects);
}

void main(){
  Student s1=Student(101,"Ojasv",["DAA","WEB TECH"]);
  Professor p1=Professor("Chonhu",["DAA","WEB TECH"]);

  [s1,p1].forEach((ob){
    final idText=ob is Student ? ob.id :"Professor";
    print("ID : $idText\nName : ${ob.name}\nSubjects : ${ob.subjects}");
  });
}