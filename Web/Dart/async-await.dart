Future<String> fetchData() async {
  return "Hi";
}

Future<void> impData() async{
  return Future.delayed(Duration(seconds: 2),(){
    print("Thanks for waiting !!!");
  });
}


void main() {
  fetchData().then((val) => {print(val)});
  print("Now data will come !!!");
  impData();
}
