interface ab{
    void abss();
}

class chonchu{
    void m(){                        // static for static
        System.out.println("This is method reference");
    }

    public static void main(String arg[]){
        chonchu c=new chonchu();    // for non static 
        ab ob=c::m;                      
        ob.abss();
    }
}