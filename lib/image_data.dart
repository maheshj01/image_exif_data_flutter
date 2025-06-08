import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageExifData extends StatefulWidget {
  final Map<String, dynamic>? metadata;
  final XFile? image;
  const ImageExifData({super.key, this.metadata, this.image});

  @override
  State<ImageExifData> createState() => _ImageExifDataState();
}

class _ImageExifDataState extends State<ImageExifData> {
  Widget _buildMetadataList() {
    if (widget.metadata == null) {
      return Container(); // Return an empty container if no metadata available
    }

    List<Widget> metadataWidgets = [];

    widget.metadata!.forEach((key, value) {
      metadataWidgets.add(
        ListTile(
          title: Text(key),
          subtitle: Text(value.toString()),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metadataWidgets,
    );
  }

  double _convertToDecimalDegrees(List<dynamic> dms, String ref) {
    double degrees = double.parse(dms[0].toString());
    double minutes = double.parse(dms[1].toString());
    double seconds = double.parse(dms[2].toString());
    if (dms.length == 4) {
      seconds = seconds / double.parse(dms[3].toString());
    }

    double decimal = degrees + (minutes / 60) + (seconds / 3600);
    if (ref == 'S' || ref == 'W') decimal *= -1;

    return decimal;
  }

  LatLng? extractLatLng(Map<String, dynamic> tags) {
    final latTag = tags['GPS GPSLatitude'];
    final latRefTag = tags['GPS GPSLatitudeRef'];
    final lonTag = tags['GPS GPSLongitude'];
    final lonRefTag = tags['GPS GPSLongitudeRef'];

    if (latTag == null ||
        latRefTag == null ||
        lonTag == null ||
        lonRefTag == null) {
      return null; // Missing EXIF GPS data
    }

    final latDMS = json.decode(latTag.printable.replaceFirst("/", ","));
    final lonDMS = json.decode(lonTag.printable.replaceFirst("/", ","));
    final latRef = latRefTag.printable;
    final lonRef = lonRefTag.printable;

    final latitude = _convertToDecimalDegrees(latDMS, latRef);
    final longitude = _convertToDecimalDegrees(lonDMS, lonRef);

    return LatLng(latitude, longitude);
  }

  var mapsUrl = 'https://www.google.com/maps/search/?api=1&query=';
  @override
  Widget build(BuildContext context) {
    final location = extractLatLng(widget.metadata!) ?? LatLng(0.0, 0.0);
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 10),
                      Text('Retake Image'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.image != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              'Image Path: ${widget.image!.path}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0.0),
                              ),
                              elevation: 5,
                              margin: const EdgeInsets.all(10),
                              child: Stack(children: [
                                Image.file(
                                  File(widget.image!.path),
                                  fit: BoxFit.fill,
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    if (widget.metadata!.containsKey("GPS GPSLatitude") &&
                        widget.metadata!.containsKey("GPS GPSLongitude"))
                      Center(
                        child: ElevatedButton(
                            onPressed: () async {
                              final url = Uri.parse(
                                  '$mapsUrl${location.latitude},${location.longitude}');
                              if (await canLaunchUrl(url)) {
                                launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Could not open maps')),
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Open in Maps'),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.map,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            )),
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'Image EXIF Data',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildMetadataList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng(latitude: $latitude, longitude: $longitude)';
}
