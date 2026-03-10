mixin body{
  int hands=2;
  int legs=2;
  int eyes=2;
  int thumnb=2;
  int nostril=2;
}

mixin face{
  var nose="Medium";
  int ear_hole=2;
}

class child with body, face{
  void feature(){
    print("I have $eyes eyes,$thumnb thumbs and my nose size is $nose");
  }
}

void main(){
  child khushi =child();
  khushi.feature();
}