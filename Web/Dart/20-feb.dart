import 'dart:async';

Future<String> fetchData() async{
  await Future.delayed(Duration(seconds: 2));
  return "Data loaded";
}

void main() async{
  print("Start");
  String result= await fetchData();
  print(result);
  print("End");
}