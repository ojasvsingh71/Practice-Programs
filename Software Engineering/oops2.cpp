#include <bits/stdc++.h>
using namespace std;

class animal{
    public:
        string name;
        int age;
        string sound;

        animal(string name,int age,string sound){
            this->name=name;
            this->age=age;
            this->sound=sound;
        }

        void display(){
            cout<<"Name :- "<<name<<"\n";
            cout<<"Age :- "<<age<<"\n";
            cout<<"Sound :- "<<sound<<"\n";
        }
};

int main() {
    
    animal a("Ojasv",50,"bubu");

    a.display();
    
    
    
    return 0;
}
