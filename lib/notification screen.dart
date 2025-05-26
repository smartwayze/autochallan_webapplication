import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, String>> challans = [];
  Set<String> processedImages = {};
  bool isInitialLoaded = false;
var index=1;
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

    // Show all challans dialogs one by one automatically
    await showAllChallansSequentially();
  }

  Future<void> showAllChallansSequentially() async {
    for (int i = 0; i < challans.length; i++) {
      final challan = challans[i];
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: EdgeInsets.all(20),
          child: SizedBox(
            width: 550,
            height: 550,
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
                        Text("          Notification #${i + 1}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16,)),
                      ],
                    ),
                    const Divider(thickness: 2, height: 30),
                    const SizedBox(height: 15),

                    // Vehicle Info
                    Text("🚗 Vehicle Information",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildInfoRow("Vehicle Number", challan["Vehicle Number"]),
                    _buildInfoRow("Vehicle Type", challan["Vehicle Type"]),
                    _buildInfoRow("Vehicle Color", challan["Vehicle Color"]),
                    _buildInfoRow("Parking Location", challan["Parking Location"]),
                    _buildInfoRow("Parking Time", challan["Parking Time"]),
                    _buildInfoRow("Parking Duration", challan["Parking Duration"]),

                    const Divider(height: 10, thickness: 1.5),

                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          challan['imageUrl']!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                    ),

                    const Divider(height: 10, thickness: 1.5),

                    // Challan Details
                    Text("📄 Challan Details",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildInfoRow("Challan Number", challan["Challan Number"]),
                    _buildInfoRow("Challan Date", challan["Challan Date"]),
                    _buildInfoRow("Challan Amount", "Rs. ${challan["Challan Amount"]}"),
                    _buildInfoRow("Challan Reason", challan["Challan Reason"]),

                    const Divider(height: 10, thickness: 1.5),

                    // Owner Info
                    Text("👤 Owner Information",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildInfoRow("Owner Name", challan["Owner Name"]),
                    _buildInfoRow("Owner Address", challan["Owner Address"]),
                    _buildInfoRow("Owner Contact", challan["Owner Contact"]),

                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
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
          }
        }
      }
    });
  }

  Future<Map<String, String>> loadRandomChallanFromCSV() async {
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
                  const SizedBox(height: 25),

                  // Vehicle Info
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
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1.5),

                  // Challan Details
                  Text("📄 Challan Details",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow("Challan Number", data["Challan Number"]),
                  _buildInfoRow("Challan Date", data["Challan Date"]),
                  _buildInfoRow("Challan Amount", "Rs. ${data["Challan Amount"]}"),
                  _buildInfoRow("Challan Reason", data["Challan Reason"]),

                  const Divider(height: 30, thickness: 1.5),

                  // Owner Info
                  Text("👤 Owner Information",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow("Owner Name", data["Owner Name"]),
                  _buildInfoRow("Owner Address", data["Owner Address"]),
                  _buildInfoRow("Owner Contact", data["Owner Contact"]),

                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$title:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value ?? ""),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notification Screen"),  backgroundColor: Colors.yellow[700],),
      body: challans.isEmpty
          ? const Center(child: Text("No challans found."))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
        ),
        itemCount: challans.length,
        itemBuilder: (context, index) {
          final challan = challans[index];
          return GestureDetector(
            onTap: () {
              showChallanDialog(challan['imageUrl']!, challan);
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Notification #${index + 1}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    const SizedBox(height: 6),
                    Text(
                      challan["Vehicle Number"] ?? "",
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      challan["Challan Number"] ?? "",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
