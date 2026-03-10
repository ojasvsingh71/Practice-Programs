Future<String> getData(){
  return Future.delayed(Duration(seconds:2),(){
    return "Data loaded";
  });
}

Future<void> getInfo() async{
  Future.delayed(Duration(seconds:2),(){ print("Hi");});
}

Future<String> getInfo2() async{
  return "Ojasv";
}

void main() async {
  print(await getInfo2());
  await getInfo();
  print(await getData());
}

