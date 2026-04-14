#include <bits/stdc++.h>
using namespace std;

int main(){
    priority_queue<int,vector<int>,greater<int>> pq;
    pq.push(10);
    pq.push(20);
    pq.push(30);
    pq.push(50);
    pq.push(0);
    pq.push(90);
    while(!pq.empty()){
        cout<<pq.top()<<" ";
        pq.pop();
    }
}