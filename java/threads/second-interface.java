class thre implements Runnable{
    void me(){
        System.out.println("This is Method");
    }

    public void run(){
        System.out.println("This is Thread");
    }

    public static void main(String[] arg) throws Exception{
        thre th1=new thre();    // thread creation
        thre th2=new thre();    // thread creation
        Thread tr1=new Thread(th1);
        Thread tr2=new Thread(th2);

        tr1.start();            // thread runable + running
        th1.me();
        tr1.sleep(3000);
        tr2.start();
        th2.me();
    }
}