interface ab{
    void abs(int a);
}

class abs {
    public static void main(String arg[]){
        ab ob=(x)-> System.out.println("This is functional interface "+x);
        ob.abs(10);
    }
}