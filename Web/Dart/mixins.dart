class Vehicle {
  void start() {
    print("Vehicle started");
  }
}

mixin Electric {
  void charge() {
    print("Charging battery");
  }
}

class Tesla extends Vehicle with Electric {}

void main() {
  Tesla car = Tesla();
  car.start();
  car.charge();
}
