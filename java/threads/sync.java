class sy{
    static synchronized void syn(){
        for(int i=0;i<7;i++){
            System.out.print(i+" ");
        }System.out.println();
    }
}

class cos extends Thread{
    public void run(){
        sy.syn();
    }
}

class chonchu{
    public static void main(String arg[]) throws Exception{
        cos th1=new cos();
        cos th2=new cos();

        th1.start();
        // th1.sleep(1000);
        th2.start();

        System.out.println(th1.getPriority());
        System.out.println(th2.getPriority());

    }
}