import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:frontend/filepicker.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.username, required this.files});
  final String username;
  final List<String> files;
  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DropIt"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centers everything vertically
          children: [
            // Header Row with Labels (Centered & Limited Width)
            SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.8, // 80% of screen width
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey[300],
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Name of File",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Actions",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ListView for Displaying Files
            Expanded(
              child: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.8, // Keep ListView within 80% width
                child: ListView.builder(
                  itemCount: widget.files.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                        title: Text(widget.files[index]),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteFile(widget.files[index], widget.username)
                                  .then((statusCode) {
                                if (statusCode == 200) {
                                  setState(() {
                                    widget.files.removeAt(index);
                                  });
                                } else {
                                  // Handle error
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Error deleting file"),
                                    ),
                                  );
                                }
                              });
                            }),
                        onTap: () async {
                          Uri fileUri = Uri.parse(await fetchDocument(
                              widget.username,
                              widget.files[index])); // Convert string to Uri

                          if (await canLaunchUrl(fileUri)) {
                            await launchUrl(fileUri,
                                mode: LaunchMode
                                    .externalApplication); // Open in browser
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Cannot open file")),
                            );
                          }
                        });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var fileData =
              await pickFile(); // Returns {"fileName": ..., "fileBytes": ...}

          if (fileData != null) {
            String fileName = fileData["fileName"];
            Uint8List fileBytes = fileData["fileBytes"];

            int statusCode = await uploadFile(fileBytes, fileName,
                widget.username // Send bytes instead of path
                );

            if (statusCode == 200) {
              setState(() {
                widget.files
                    .add(fileName); // Only update UI after successful upload
              });
            }
          }
        },
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
