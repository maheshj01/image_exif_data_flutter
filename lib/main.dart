import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_exif_data/image_data.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter EXIF Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ExifDemo(),
    );
  }
}

class ExifDemo extends StatefulWidget {
  const ExifDemo({Key? key}) : super(key: key);

  @override
  _ExifDemoState createState() => _ExifDemoState();
}

class _ExifDemoState extends State<ExifDemo> {
  XFile? _image;
  Map<String, dynamic>? _metadata;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPermissions();
    });
    super.initState();
  }

  Future<void> requestPermissions() async {
    final status = await Permission.accessMediaLocation.request();
    if (status.isGranted) {
      print("Media location access granted");
    } else if (status.isDenied) {
      print("Media location access denied");
      // Optionally, you can show a dialog to inform the user about the denied permission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Media location access denied. Please allow it in settings."),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      print("Media location access permanently denied");
      openAppSettings();
    } else {
      print("Media location access status: $status");
    }
  }

  Future<void> getImage({required bool isGallery}) async {
    ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    try {
      pickedFile = isGallery
          ? await picker.pickImage(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.camera);
    } on PlatformException catch (error) {
      switch (error.code.toLowerCase()) {
        case 'photo_access_denied':
          print(error.code);
          break;
        case 'camera_access_denied':
          print(error.code);
          break;
        default:
          print(error.code);
          break;
      }
    } catch (error) {
      print(error);
    }

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _metadata = null;
      });
      await readExifData();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageExifData(
            metadata: _metadata,
            image: _image,
          ),
        ),
      );
    }
  }

  Future<void> readExifData() async {
    if (_image != null) {
      final _imageBytes = File(_image!.path).readAsBytesSync();
      final exifData = await readExifFromBytes(_imageBytes);

      setState(() {
        _metadata = exifData;
      });
      if (_metadata!.isEmpty) {
        print("No EXIF information found");
        return;
      }

      print('Path : ${_image!.path}');
      for (final entry in _metadata!.entries) {
        print("${entry.key}: ${entry.value}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  getImage(isGallery: false);
                },
                child: const Icon(
                  Icons.camera,
                  size: 25,
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  getImage(isGallery: true);
                },
                child: const Icon(
                  Icons.photo_library_rounded,
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
