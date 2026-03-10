class parent{
  var eye="Brown";
  var teeth="white";
  String? mind;

  void run(){
    print("Running");
  }
}

class child extends parent{
  
  child(){
    mind="Brilliant";
  }

  void feature(){
    print("My eye color is ${eye}");
    print("My mind is ${mind}");
  }
}

void main(){
  child chonchu=child();
  khushi.feature();
  khushi.run();
}