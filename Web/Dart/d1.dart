void greet(){
  print("Hello");
}

int add(int a,int b) {
  return a+b;
}

void main(){
  var name="chonchu";
  int n=1;
  double version = 1.00;
  print("Cutu $name");

  greet();
  print(add(1,2));

  dynamic animal="hourse";
  print(animal);
  animal=10;
  print(animal);

  const house=10000;
  print(house);
  // house=10;

  print(9/7);
  print(9~/7);
  print(9%7);

  var d=100;
  d??=10;
  print(d);

  int? m;
  print(m);
}