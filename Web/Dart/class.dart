class obj{
  int? n;
  int? m;

  void set(int a,int b){
    this.n=a;
    this.m=b;
  }
  void prnt(){
    print(n!+m!);
  }
}

void main(){
  obj a=obj();
  obj b=obj();

  a.set(2,3);
  a.prnt();

  b..set(5,3)..prnt();


  List lst=[1,2,3,4,4];
  lst.forEach((value){
    print("$value \n");
  });

  for(int i=0;i<lst.length;i++){
    print(lst[i]);
  }
}

