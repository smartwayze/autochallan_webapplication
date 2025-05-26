import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';


class paidChallanScreen extends StatefulWidget {
  @override
  _paidChallanScreenState createState() => _paidChallanScreenState();
}

class _paidChallanScreenState extends State<paidChallanScreen> {
  List<Map<String, dynamic>> challans = [];
  Set<String> processedImages = {};
  bool isInitialLoaded = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadAllExistingChallans();
  }

  Future<void> loadAllExistingChallans() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('uploaded_images')
          .where('status', isEqualTo: "Paid")
          .get();

      print("Firestore docs count: ${snapshot.docs.length}");

      for (var doc in snapshot.docs) {
        final imageUrl = doc['url'] as String? ?? '';
        final docId = doc.id;

        if (imageUrl.isEmpty) {
          print("Document $docId has empty URL, skipping.");
          continue;
        }

        if (!processedImages.contains(imageUrl)) {
          final challanData = await loadRandomChallanFromCSV();
          challans.add({...challanData, 'imageUrl': imageUrl, 'docId': docId});
          processedImages.add(imageUrl);
          print("Added challan for image $imageUrl");
        }
      }

      setState(() {
        isInitialLoaded = true;
        isLoading = false;
      });
      print("Finished loading challans, total: ${challans.length}");
    } catch (e, st) {
      print("Error loading challans: $e");
      print(st);
      setState(() {
        isLoading = false;
        isInitialLoaded = true;
      });
    }
  }

  Future<Map<String, String>> loadRandomChallanFromCSV() async {
    try {
      final rawData = await rootBundle.loadString('assets/challan_data.csv');
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData);
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
        "Owner Contact"
      ];

      if (csvData.length < 2) {
        // no data rows
        print("CSV has no data rows");
        return {};
      }

      final dataRows = csvData.sublist(1);
      final randomRow = dataRows[Random().nextInt(dataRows.length)];

      final Map<String, String> challan = {};
      for (int i = 0; i < headers.length; i++) {
        challan[headers[i]] = i < randomRow.length ? randomRow[i].toString() : '';
      }

      print("Random challan loaded: ${challan['Vehicle Number']}");

      return challan;
    } catch (e) {
      print("Error loading CSV: $e");
      return {};
    }
  }

  void showChallanDialog(Map<String, dynamic> data) {
    final String imageUrl = data['imageUrl'] ?? '';
    final String docId = data['docId'] ?? '';

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
                  Row(
                    children: [
                      const Icon(Icons.local_police, color: Colors.red, size: 36),
                      const SizedBox(width: 10),
                      Text("Islamabad Police Challan",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          )),
                    ],
                  ),
                  const Divider(thickness: 2, height: 30),
                  const SizedBox(height: 20),
                  Text("🚗 Vehicle Information", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                      )
                          : const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1.5),
                  Text("📄 Challan Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildInfoRow("Challan Number", data["Challan Number"]),
                  _buildInfoRow("Challan Date", data["Challan Date"]),
                  _buildInfoRow("Challan Amount", "Rs. ${data["Challan Amount"]}"),
                  _buildInfoRow("Challan Reason", data["Challan Reason"]),
                  const Divider(height: 30, thickness: 1.5),
                  Text("👤 Owner Information", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildInfoRow("Owner Name", data["Owner Name"]),
                  _buildInfoRow("Owner Address", data["Owner Address"]),
                  _buildInfoRow("Owner Contact", data["Owner Contact"]),
                  const SizedBox(height: 30),
                  Row(
                    children: [


                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      )
                    ],
                  ),
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
        children: [
          SizedBox(
            width: 160,
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(child: Text(value ?? '', style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Paid Challans'),
        backgroundColor: Colors.yellow[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isInitialLoaded
          ? const Center(child: Text('Loading...'))
          : challans.isEmpty
          ? const Center(child: Text('No challans found.'))
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: challans.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final data = challans[index];
            return GestureDetector(
              onTap: () => showChallanDialog(data),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(1, 2),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["Vehicle Number"] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Reason: ${data["Challan Reason"] ?? ''}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: data["imageUrl"] != null && data["imageUrl"].toString().isNotEmpty
                              ? Image.network(
                            data["imageUrl"],
                            width: double.infinity,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
                          )
                              : const Icon(Icons.broken_image, size: 60),
                        ),
                      ),
                      Text(
                        "Amount: Rs. ${data["Challan Amount"] ?? '0'}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                      ),
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
