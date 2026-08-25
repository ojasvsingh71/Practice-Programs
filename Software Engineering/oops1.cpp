#include <bits/stdc++.h>
using namespace std;

class TestGrader{
    string answer;
    
    public : void setKey(string s){
        answer=s;
    }

    public : string grade(string s){
        int marks=0;
        string wrong;
        for(int i=0;i<20;i++){
            if(s[i]==answer[i]) marks++;
            else wrong+=to_string(i+1)+" ";
        }
        string result;
        if(marks>=15) result="Pass\n";
        else result="Fail\n";
        return "\n"+result+"Right Answers : "+to_string(marks)+"\n"+"Wrong Answers : "+to_string(20-marks)+"\n"+wrong; 
    } 
};


int main() {
    
    string answer="BDAACABACDBCDADCCBDA";

    TestGrader* t=new TestGrader();
    t->setKey(answer);

    string input;
    cin>>input;

    cout<<t->grade(input)<<"\n";
    
    return 0;
}
