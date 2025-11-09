import java.util.*;

class a implements Comparable<a>{
    int id;
    String name;
    int cid;

    a(int id,String name,int cid){
        this.id=id;
        this.name=name;
        this.cid=cid;
    }

    public int compareTo(a ms){
        return ms.id - this.cid;
    }
}

class chonchu{
    public static void main(String arg[]){
        
        ArrayList<a> li=new ArrayList<>();

        li.add(new a(2,"mradul",8));
        li.add(new a(4,"akshat",9));
        li.add(new a(3,"khushi",9));
        li.add(new a(1,"ojasv",9));
        li.add(new a(5,"rupesh",8));

        Collections.sort(li);

        for(a i:li){
            System.out.println(i.id+"\t"+i.name+"\t"+i.cid);
        }
    }
}