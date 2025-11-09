// print count 1 to 10 using lambda expression

interface bu{
    void count(int n);
}

class chonchu{
    public static void main(String arg[]){
        bu ob=(n)->{
            for(int i=1;i<=n;i++){
                System.out.print(i+" ");
            }System.out.println();
        };
        ob.count(10);
    }
}