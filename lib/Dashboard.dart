import 'package:automatic_challan_generator/paid%20chalan.dart';
import 'package:automatic_challan_generator/pending%20chalan.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'ChallanScreen.dart';
import 'notification screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentPage = 1;
  int itemsPerPage = 5;
  int totalChallans = 0; // dynamic challan count

  final sidebarOptions = [
    'Generated Challans',
    'Pending Challans',
    'Resolved Challans',
    'Alerts Sent',
  ];

  @override
  void initState() {
    super.initState();
    fetchTotalChallans();
  }

  Future<void> fetchTotalChallans() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('uploaded_images').get();
      setState(() {
        totalChallans = snapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching challans: $e');
    }
  }

  List<int> getCurrentPageItems() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    return List.generate(totalChallans, (index) => index + 1).sublist(
      startIndex,
      endIndex > totalChallans ? totalChallans : endIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<int> currentItems = getCurrentPageItems();

    return Scaffold(
      backgroundColor: Colors.yellow[100],
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.yellow[700],
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      "assets/Logo1.png",
                      width: 250,
                      height: 240,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 10,
                      child: Text(
                        "Welcome!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.8),
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ...sidebarOptions.map((text) => SidebarButton(text: text)).toList(),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header with dynamic total
                  Container(
                    width: double.infinity,
                    color: Colors.yellow[700],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Center(
                      child: Text(
                        "Challan Dashboard",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Summary Cards
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 15,
                      alignment: WrapAlignment.center,
                      children: [
                        ChallanCard(title: "Current Challans", amount: "$totalChallans", icon: Icons.receipt),
                        InkWell(
                            onTap:  (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>ChallanScreen()));},
                            child: ChallanCard(title: "Total Challans", amount: "$totalChallans", icon: Icons.assignment)),
                         InkWell(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationScreen()));},
                            child: ChallanCard(title: "Alerts Sent",amount: "$totalChallans", icon: Icons.notifications)),


                        InkWell(onTap:(){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>PendingChallanScreen()));

                        },child: ChallanCard(title: "Pending Challans", amount: "", icon: Icons.pending_actions)),

                        InkWell(onTap:(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>paidChallanScreen()));}
    ,child: ChallanCard(title: "Resolved Challans", amount: "", icon: Icons.check_circle)),
                         ],
                    ),
                  ),

                  // Recent Challans List
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recent Challans",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: currentItems.length,
                          itemBuilder: (context, index) {
                            int challanNumber = currentItems[index];
                            return Card(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChallanScreen()));
                                },
                                child: ListTile(
                                  leading: Icon(Icons.receipt_long, color: Colors.orange[900]),
                                  title: Text("Challan #$challanNumber"),
                                  subtitle: Text("Amount: Rs ${challanNumber * 100}"),
                                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    width: double.infinity,
                    color: Colors.yellow[700],
                    padding: EdgeInsets.all(15),
                    child: Center(
                      child: Text(
                        "© 2025 Challan Dashboard. All Rights Reserved.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sidebar Button Widget
class SidebarButton extends StatelessWidget {
  final String text;
  SidebarButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextButton(
          onPressed: () {
            if (text == 'Generated Challans') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChallanScreen()),
              );
            } else if (text == 'Pending Challans') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PendingChallanScreen()),
              );
            }
            else if (text == 'Alerts Sent') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );

            }
            else if (text == 'Resolved Challans' ) {
              FirebaseFirestore.instance
                  .collection('challans')
                  .where('status', isEqualTo: 'paid')
                  .get()
                  .then((snapshot) {
                final paidChallans = snapshot.docs.map((doc) {
                  final data = doc.data();

                  // Convert dynamic values to string safely
                  return {
                    'Vehicle Number': data['Vehicle Number']?.toString() ?? '',
                    'Challan Number': data['Challan Number']?.toString() ?? '',
                    'Challan Amount': data['Challan Amount']?.toString() ?? '',
                  };
                }).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  paidChallanScreen()),
                );

              });
            }

          }
        ,style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_right, color: Colors.white),
            SizedBox(width: 10),
            Text(text, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class ChallanCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  ChallanCard({required this.title, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.orange[900]),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(amount, style: TextStyle(fontSize: 16, color: Colors.orange[900])),
          ],
        ),
      ),
    );
  }
}
