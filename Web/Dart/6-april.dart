class User {
  String? name;
  int? age;

  User(this.name, this.age) {}
  void display() {
    print("Name ${name} , Age ${age}");
  }
}

void main() {
  User u = User("Ojasv", 19);
  u.display();
}
