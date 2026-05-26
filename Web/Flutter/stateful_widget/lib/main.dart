import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Interest Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Simple Interest Calculator'),
        ),
        body: Center(
          child: SimpleInterestForm(),
        ),
      ),
    );
  }
}

class SimpleInterestCalculator {
  double principal = 0.0;
  double rate = 0.0;
  int time = 0;

  void calculate() {
    if (principal > 0 && rate > 0 && time > 0) {
      final interest = (principal * rate * time) / 100;
      print('Simple Interest: \$${interest.toStringAsFixed(2)}');
    } else {
      print('Please enter valid principal, rate, and time.');
    }
  }

  void setPrincipal(double value) => principal = value;
  void setRate(double value) => rate = value;
  void setTime(int value) => time = value;
}

class SimpleInterestForm extends StatefulWidget {
  @override
  _SimpleInterestFormState createState() => _SimpleInterestFormState();
}

class _SimpleInterestFormState extends State<SimpleInterestForm> {
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  SimpleInterestCalculator calculator = SimpleInterestCalculator();

  void calculateInterest() {
    calculator.calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _principalController,
            decoration: InputDecoration(labelText: 'Principal'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                calculator.setPrincipal(double.tryParse(value) ?? 0);
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: _rateController,
            decoration: InputDecoration(labelText: 'Rate (%)'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                calculator.setRate(double.tryParse(value) ?? 0);
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: _timeController,
            decoration: InputDecoration(labelText: 'Time (Years)'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                calculator.setTime(int.tryParse(value) ?? 0);
              });
            },
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: calculateInterest,
            child: Text('Calculate'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
