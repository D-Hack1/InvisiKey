import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rhythm_verify_screen.dart';

class Bill {
  final String name;
  final double amount;
  bool isPaid;

  Bill({required this.name, required this.amount, this.isPaid = false});
}

class BillPaymentScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  
  const BillPaymentScreen({Key? key, this.onTabChanged}) : super(key: key);
  
  @override
  _BillPaymentScreenState createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  List<Bill> bills = [
    Bill(name: "Electricity", amount: 1200),
    Bill(name: "Gas", amount: 600),
    Bill(name: "Water", amount: 300),
    Bill(name: "Internet", amount: 999, isPaid: true),
    Bill(name: "Mobile Recharge", amount: 299),
  ];

  int currentStep = 0;
  Bill? selectedBill;
  final pinController = TextEditingController();
  bool _paymentSuccess = false;

  void _startPayment(Bill bill) {
    setState(() {
      selectedBill = bill;
      currentStep = 1;
      pinController.clear();
      _paymentSuccess = false;
    });
  }

  void _validatePin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('password');
    final secretButton = prefs.getString('secret_button');

    if (pinController.text != savedPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect PIN.")),
      );
      return;
    }

    final verified = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RhythmVerifyScreen(
          onSuccess: () => Navigator.pop(context, true),
          button: secretButton ?? '',
        ),
      ),
    );

    if (verified == true) {
      setState(() {
        selectedBill?.isPaid = true;
        _paymentSuccess = true;
        currentStep = 2;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rhythm verification failed.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bill Payments"),
        backgroundColor: const Color.fromARGB(255, 23, 53, 160),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onTabChanged != null) {
              widget.onTabChanged!(0); // Navigate to home tab
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          if (currentStep == 1 || currentStep == 2)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.25,
              child: Center(
                child: SvgPicture.asset(
                  'assets/Canara_Bank_Logo.svg',
                  height: screenHeight * 0.08,
                ),
              ),
            ),
          Positioned.fill(
            top: currentStep == 0 ? 0 : screenHeight * 0.25,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: currentStep == 0
                  ? _buildBillList()
                  : currentStep == 1
                  ? _buildPinEntry()
                  : _buildSuccessMessage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillList() {
    return ListView.builder(
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: bill.isPaid
                ? Colors.green.withOpacity(0.2)
                : const Color.fromARGB(255, 255, 230, 200),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: bill.isPaid ? Colors.green : Colors.orange,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Icon(
              bill.isPaid ? Icons.check_circle : Icons.access_time,
              color: bill.isPaid ? Colors.green : Colors.orange,
            ),
            title: Text(bill.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: bill.isPaid ? Colors.green[800] : Colors.black)),
            subtitle: Text("Amount: ₹${bill.amount}",
                style: const TextStyle(color: Colors.black87)),
            trailing: bill.isPaid
                ? const Text("Paid",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green))
                : ElevatedButton(
              onPressed: () => _startPayment(bill),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text("Pay"),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter PIN",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: "PIN",
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _validatePin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 23, 53, 160),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text("Confirm"),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Center(
      child: Column(
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 80),
          SizedBox(height: 20),
          Text(
            "Payment Successful!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
