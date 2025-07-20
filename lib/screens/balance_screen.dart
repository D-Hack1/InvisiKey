import 'package:flutter/material.dart';

class BalanceScreen extends StatelessWidget {
  final double balance;

  BalanceScreen({required this.balance});

  final List<Map<String, dynamic>> transactions = [
    {
      "name": "Flipkart",
      "desc": "Paid to Flipkart",
      "amount": 500,
      "time": "10:30 AM",
      "isCredit": false,
      "date": "Today"
    },
    {
      "name": "Nivdeditaa",
      "desc": "Received from Niveditaa",
      "amount": 2000,
      "time": "9:10 AM",
      "isCredit": true,
      "date": "Today"
    },
    {
      "name": "ATM",
      "desc": "ATM Withdrawal",
      "amount": 1000,
      "time": "18:15",
      "isCredit": false,
      "date": "04 July 2025"
    },
    {
      "name": "Netflix",
      "desc": "Paid for Netflix",
      "amount": 299,
      "time": "20:45",
      "isCredit": false,
      "date": "04 July 2025"
    },
  ];

  @override
  Widget build(BuildContext context) {
    String? lastDate;

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Summary'),
        backgroundColor: Colors.blue.shade800,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centered Balance Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '₹${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Transactions
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isCredit = tx['isCredit'] as bool;
                  final currentDate = tx["date"] ?? "";
                  final showDate = currentDate != lastDate;
                  lastDate = currentDate;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDate && currentDate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 6),
                          child: Text(
                            currentDate,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isCredit
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              child: Icon(
                                isCredit
                                    ? Icons.call_received
                                    : Icons.call_made,
                                color: isCredit ? Colors.green : Colors.red,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['desc'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    tx['time'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${isCredit ? "+" : "-"}₹${tx["amount"]}",
                              style: TextStyle(
                                color: isCredit ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
