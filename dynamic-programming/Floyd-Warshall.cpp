#include<bits/stdc++.h>
using namespace std;

int main(){
	int v;
	cin>>v;
	int e;
	cin>>e;
	int INF=1e9;
	vector<vector<int>> dist(v,vector<int>(v,INF));
	for(int i=0;i<v;i++){
		dist[i][i]=0;
	}
	for(int i=0;i<e;i++){
		int s,d,w;
		cin>>s>>d>>w;
		dist[s-1][d-1]=w;
	}
	for(int via=0;via<v;via++){
		for(int i=0;i<v;i++){
			for(int j=0;j<v;j++){
				dist[i][j]=min(dist[i][j],dist[i][via]+dist[via][j]);
			}
		}
	}
	for(int i=0;i<v;i++){
		for(int j=0;j<v;j++){
			if(dist[i][j]==INF) cout<<"INF ";
			else cout<<dist[i][j]<<" ";
		}cout<<"\n";
	}
}


// 4       
// 5       
// 1 2 4   
// 1 4 10  
// 1 3 6   
// 2 4 5   
// 3 4 2
// 0 4 6 8 


// INF 0 INF 5 
// INF INF 0 2 
// INF INF INF 0 