class thre extends Thread{
    void me(){
        System.out.println("This is Method");
    }

    public void run(){
        System.out.println("This is Thread");
    }

    public static void main(String[] arg) throws Exception{
        thre th1=new thre();    // thread creation
        thre th2=new thre();    // thread creation

        th1.start();            // thread runable + running
        th1.me();
        th1.sleep(3000);
        th2.start();
        th2.me();
    }
}