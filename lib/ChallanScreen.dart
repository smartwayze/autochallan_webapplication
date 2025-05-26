import 'dart:math';
import 'package:pdf/pdf.dart'; // for PdfPageFormat
import 'package:printing/printing.dart'; // for Printing.layoutPdf
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';import 'package:url_launcher/url_launcher.dart';



class ChallanScreen extends StatefulWidget {
  @override
  _ChallanScreenState createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  List<Map<String, String>> challans = [];
  Set<String> processedImages = {};
  bool isInitialLoaded = false;

  @override
  void initState() {
    super.initState();
    loadAllExistingChallans().then((_) {
      listenForUploadedImages();
    });
  }

  Future<void> loadAllExistingChallans() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('uploaded_images')
        .orderBy('timestamp', descending: true)
        .get();

    for (var doc in snapshot.docs) {
      final imageUrl = doc['url'];
      if (!processedImages.contains(imageUrl)) {
        final challanData = await loadRandomChallanFromCSV();
        challans.add({...challanData, 'imageUrl': imageUrl});
        processedImages.add(imageUrl);
      }
    }

    setState(() {
      isInitialLoaded = true;
    });
  }
  Future<void> launchSMS(String message, String phoneNumber) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      print("Could not launch SMS app");
    }
  }

  void listenForUploadedImages() {
    FirebaseFirestore.instance
        .collection('uploaded_images')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final imageUrl = change.doc['url'];
          if (!processedImages.contains(imageUrl)) {
            final challanData = await loadRandomChallanFromCSV();
            setState(() {
              challans.insert(0, {...challanData, 'imageUrl': imageUrl});
              processedImages.add(imageUrl);
            });
            showChallanDialog(imageUrl, challanData);
            launchSMS(
                "A new challan has been generated for vehicle number: ${challanData['Vehicle Number']}.\nReason: ${challanData['Challan Reason']}\nAmount: Rs. ${challanData['Challan Amount']}",
                '03228669870'
            );


          }
        }
      }
    });
  }

  Future<Map<String, String>> loadRandomChallanFromCSV() async {
    final rawData = await rootBundle.loadString('assets/challan_data.csv');
    final List<List<dynamic>> csvData =
    const CsvToListConverter().convert(rawData);

    final headers = [
      "Vehicle Number",
      "Vehicle Type",
      "Vehicle Color",
      "Parking Location",
      "Parking Time",
      "Parking Duration",
      "Challan Number",
      "Challan Date",
      "Challan Amount",
      "Challan Reason",
      "Owner Name",
      "Owner Address",
      "Owner Contact",
    ];

    final dataRows = csvData.sublist(1);
    final randomRow = dataRows[Random().nextInt(dataRows.length)];

    final Map<String, String> challan = {};
    for (int i = 0; i < headers.length; i++) {
      challan[headers[i]] = randomRow[i].toString();
    }

    return challan;
  }

  void showChallanDialog(String imageUrl, Map<String, String> data) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 800,
          height: 900,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.local_police, color: Colors.red, size: 36),
                      const SizedBox(width: 10),
                      Text(
                        "Islamabad Police Challan",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const Divider(thickness: 2, height: 30),

                  // I

                  const SizedBox(height: 25),

                  // Section 1: Vehicle Info
                  Text("🚗 Vehicle Information",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow("Vehicle Number", data["Vehicle Number"]),
                  _buildInfoRow("Vehicle Type", data["Vehicle Type"]),
                  _buildInfoRow("Vehicle Color", data["Vehicle Color"]),
                  _buildInfoRow("Parking Location", data["Parking Location"]),
                  _buildInfoRow("Parking Time", data["Parking Time"]),
                  _buildInfoRow("Parking Duration", data["Parking Duration"]),

                  const Divider(height: 30, thickness: 1.5),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1.5),
                  // Section 2: Challan Details
                  Text("📄 Challan Details",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow("Challan Number", data["Challan Number"]),
                  _buildInfoRow("Challan Date", data["Challan Date"]),
                  _buildInfoRow("Challan Amount", "Rs. ${data["Challan Amount"]}"),
                  _buildInfoRow("Challan Reason", data["Challan Reason"]),

                  const Divider(height: 30, thickness: 1.5),

                  // Section 3: Owner Info
                  Text("👤 Owner Information",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow("Owner Name", data["Owner Name"]),
                  _buildInfoRow("Owner Address", data["Owner Address"]),
                  _buildInfoRow("Owner Contact", data["Owner Contact"]),

                  const SizedBox(height: 30),
                  Row(
                    children: [ ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text("Print Challan"),
                      onPressed: () {
                        Navigator.pop(context); // Optional: close dialog
                        Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
                          return await generateChallanPdf(imageUrl, data);
                        });
                      },
                    ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ),
                      ),



                    ],
                  ), const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }


  void deleteChallan(String imageUrl) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('uploaded_images')
          .where('url', isEqualTo: imageUrl)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        challans.removeWhere((challan) => challan['imageUrl'] == imageUrl);
        processedImages.remove(imageUrl);
      });
    } catch (e) {
      print("Error deleting challan: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete challan.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(

        title: const Text('Challan Generator'),
        backgroundColor:Colors.yellow[700],
      ),
      body: !isInitialLoaded
          ? const Center(child: CircularProgressIndicator())
          : challans.isEmpty
          ? const Center(child: Text('No challans found.'))
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: challans.length,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final data = challans[index];
            final imageUrl = data['imageUrl']!;
            return InkWell(
              onTap: () {
                showChallanDialog(imageUrl, data);
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_police,
                              color: Colors.red, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            "Islamabad Police",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title:
                                    const Text("Confirm Deletion"),
                                    content: const Text(
                                        "Are you sure you want to delete this challan?"),
                                    actions: [
                                      TextButton(
                                        child: const Text("Cancel"),
                                        onPressed: () =>
                                            Navigator.pop(context),
                                      ),
                                      TextButton(
                                        child: const Text("Yes"),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          deleteChallan(imageUrl);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Challan'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image,
                              size: 100),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("🚗 Vehicle Information",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 5),
                      Text("Vehicle No: ${data['Vehicle Number']}"),
                      Text("Type: ${data['Vehicle Type']}"),
                      Text("Color: ${data['Vehicle Color']}"),
                      Text("Location: ${data['Parking Location']}"),
                      Text("Time: ${data['Parking Time']}"),
                      Text("Duration: ${data['Parking Duration']}"),
                      const Divider(height: 18, thickness: 1),
                      Text("📄 Challan Details",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 5),
                      Text("Number: ${data['Challan Number']}"),
                      Text("Date: ${data['Challan Date']}"),
                      Text("Amount: Rs. ${data['Challan Amount']}"),
                      Text("Reason: ${data['Challan Reason']}"),
                      const Divider(height: 18, thickness: 1),
                      Text("👤 Owner Information",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 5),
                      Text("Name: ${data['Owner Name']}"),
                      Text("Address: ${data['Owner Address']}"),
                      Text("Contact: ${data['Owner Contact']}"),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<Uint8List> generateChallanPdf(String imageUrl, Map<String, String> data) async {
  final pdf = pw.Document();

  final netImage = await networkImage(imageUrl);

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Header(level: 0, child: pw.Text('Islamabad Police Challan', style: pw.TextStyle(fontSize: 24))),
        pw.Divider(),

        pw.Text("🚗 Vehicle Information", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        buildPdfRow("Vehicle Number", data["Vehicle Number"]),
        buildPdfRow("Vehicle Type", data["Vehicle Type"]),
        buildPdfRow("Vehicle Color", data["Vehicle Color"]),
        buildPdfRow("Parking Location", data["Parking Location"]),
        buildPdfRow("Parking Time", data["Parking Time"]),
        buildPdfRow("Parking Duration", data["Parking Duration"]),
        pw.SizedBox(height: 10),

        pw.Image(netImage, height: 200),

        pw.Divider(),
        pw.Text("📄 Challan Details", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        buildPdfRow("Challan Number", data["Challan Number"]),
        buildPdfRow("Challan Date", data["Challan Date"]),
        buildPdfRow("Challan Amount", "Rs. ${data["Challan Amount"]}"),
        buildPdfRow("Challan Reason", data["Challan Reason"]),

        pw.Divider(),
        pw.Text("👤 Owner Information", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        buildPdfRow("Owner Name", data["Owner Name"]),
        buildPdfRow("Owner Address", data["Owner Address"]),
        buildPdfRow("Owner Contact", data["Owner Contact"]),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget buildPdfRow(String title, String? value) {
  return pw.Row(
    children: [
      pw.Text("$title: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Expanded(child: pw.Text(value ?? "-")),
    ],
  );
}
