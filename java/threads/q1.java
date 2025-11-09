// WAP to print numbers from 1 to 100 and 100 to 1 by using different threads.

class chonchu2 extends Thread{
    public void run(){
        for(int i=100;i>0;i--){
            System.out.print(i+" ");
        }System.out.println();
    }
}

class chonchu1 extends Thread{
    public void run(){
        for(int i=1;i<=10000d;i++){
            System.out.print(i+" ");
        }System.out.println();
    }
}

class chonchu {
    public static void main(String arg[]) throws Exception{
        chonchu1 th1=new chonchu1();
        chonchu2 th2=new chonchu2();

        th1.start();
        th1.sleep(1000);
        th2.start();
    }
}