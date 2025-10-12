// Q5. A university library maintains records of books and their borrowers (students and professors). The library is managed by a Librarian.
// Design a Java program using OOP principles with the following requirements:
// lasses to Create:
// 1.	Book
// o	Fields: bookId, title, author, isIssued
// o	Methods:
// 	issueBook()
// 	returnBook()
// 	displayBookInfo()
// 2.	Person (Base Class)
// o	Fields: personId, name
// o	Methods: displayInfo()
// 3.	Student (inherits from Person)
// o	Fields: courseName, rollNo
// o	Can borrow up to 3 books
// 4.	Professor (inherits from Person)
// o	Fields: departmentName
// o	Can borrow up to 5 books
// 5.	Librarian
// o	Fields: name
// o	Methods:
// 	issueBook(Book b, Person p)
// 	returnBook(Book b, Person p)
// 6.	Library (composition)
// o	Has a list of books
// o	Has a list of registered members (students/professors)


class Book{
    int bookId;
    String title;
    String author;
    boolean isIssued;
    
    void issueBook(int bookId,String title,String author){
        this.bookId=bookId;
        this.title=title;
        this.author=author;
        this.isIssued=!this.isIssued;
    }

    void returnBook(int bookId,String title,String author){
        this.bookId=0;
        this.title="";
        this.author="";
        this.isIssued=false;
    }

    void displayBookInfo(){
        System.out.println(this.bookId);
        System.out.println(this.title);
        System.out.println(this.author);
        System.out.println(this.isIssued);
    }
}

class Person{
    int personId;
    String name;

    void displayInfo(){};
}

class Student extends Person{
    String courseName;
    int rollNo;
}

class Professor extends Person{
    String departmentName;
}

class Librarian{
    String name;
    issueBook(Book b,Person p);
    returnBook(Book b,Person p);
}