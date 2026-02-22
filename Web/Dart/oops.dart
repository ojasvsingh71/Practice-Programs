class person {
  String name;
  int age;

  person(this.name, this.age);

  void show() {
    print("Hi, My name is ${name} and I'm ${age} years old!!!");
  }
}

void main() {
  person p = new person("Ojasv", 19);
  p.show();
}
