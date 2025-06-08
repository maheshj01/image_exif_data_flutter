import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  final Function(XFile?) onImageClicked;
  const CameraPage({super.key, required this.onImageClicked});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: CameraAwesomeBuilder.awesome(
          saveConfig: SaveConfig.photo(
            exifPreferences: ExifPreferences(
              saveGPSLocation: true,
            ),
          ),
          sensorConfig: SensorConfig.single(
            sensor: Sensor.position(SensorPosition.back),
            flashMode: FlashMode.auto,
            aspectRatio: CameraAspectRatios.ratio_4_3,
            zoom: 0.0,
          ),
          enablePhysicalButton: true,

          // filter: AwesomeFilter.AddictiveRed,
          previewAlignment: Alignment.center,
          previewFit: CameraPreviewFit.contain,
          onMediaTap: (mediaCapture) {
            mediaCapture.isPicture
                ? debugPrint(
                    'Picture taken: ${mediaCapture.captureRequest.path}')
                : debugPrint(
                    'Video recorded: ${mediaCapture.captureRequest.path}');
            mediaCapture.captureRequest.when(
              single: (single) {
                debugPrint('single: ${single.file?.path}');
                widget.onImageClicked(single.file);
                Navigator.of(context).pop();
              },
              multiple: (multiple) {
                multiple.fileBySensor.forEach((key, value) {
                  debugPrint('multiple file taken: $key ${value?.path}');
                  value?.openRead();
                });
              },
            );
          },
        ),
      ),
    );
  }
}
