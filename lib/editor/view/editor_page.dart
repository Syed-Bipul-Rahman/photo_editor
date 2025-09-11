import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:photo_management_app/editor/crop/crop_your_image.dart';
import 'package:flutter/services.dart' show rootBundle;

class EditorPage extends StatefulWidget {
  final VoidCallback? onCrop;

  const EditorPage({super.key, this.onCrop});

  @override
  State<EditorPage> createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  static const _images = const [
    'assets/images/for_preview_delete_this_later.png',
  ];

  final _cropController = CropController();

  void performCrop() {
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  @override
  void initState() {
    super.initState();
    widget.onCrop != null ? _setupCropCallback() : null;
    _loadAllImages();
  }

  void _setupCropCallback() {
    // Store the crop function reference for external access
  }

  final _imageDataList = <Uint8List>[];

  var _loadingImage = false;
  var _currentImage = 0;

  set currentImage(int value) {
    setState(() {
      _currentImage = value;
    });
    _cropController.image = _imageDataList[_currentImage];
  }

  var _isThumbnail = false;
  var _isCropping = false;
  Uint8List? _croppedData;
  var _isOverlayActive = true;

  Future<void> _loadAllImages() async {
    setState(() {
      _loadingImage = true;
    });
    for (final assetName in _images) {
      _imageDataList.add(await _load(assetName));
    }
    setState(() {
      _loadingImage = false;
    });
  }

  Future<Uint8List> _load(String assetName) async {
    final assetData = await rootBundle.load(assetName);
    return assetData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Visibility(
          visible: !_loadingImage && !_isCropping,
          child: Column(
            children: [
              Expanded(
                child: Visibility(
                  visible: _croppedData == null,
                  child: Stack(
                    children: [
                      if (_imageDataList.isNotEmpty) ...[
                        Crop(
                          willUpdateScale: (newScale) => newScale < 5,
                          controller: _cropController,
                          image: _imageDataList[_currentImage],
                          onCropped: (result) {
                            switch (result) {
                              case CropSuccess(:final croppedImage):
                                _croppedData = croppedImage;
                              case CropFailure(:final cause):
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Error'),
                                    content: Text(
                                      'Failed to crop image: ${cause}',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                            }
                            setState(() => _isCropping = false);
                          },

                          maskColor: _isThumbnail ? Colors.white : null,
                          cornerDotBuilder: (size, edgeAlignment) =>
                              const Icon(Icons.circle, color: Colors.white),
                          interactive: false,
                          fixCropRect: false,
                          // radius: 20,
                          initialRectBuilder: InitialRectBuilder.withBuilder((
                            viewportRect,
                            imageRect,
                          ) {
                            // Calculate 90% of image dimensions
                            final imageWidth = imageRect.width;
                            final imageHeight = imageRect.height;
                            final cropWidth = imageWidth * 0.9;
                            final cropHeight = imageHeight * 0.9;

                            // Center the crop rect within the image
                            final centerX = imageRect.left + (imageWidth / 2);
                            final centerY = imageRect.top + (imageHeight / 2);

                            return Rect.fromCenter(
                              center: Offset(centerX, centerY),
                              width: cropWidth,
                              height: cropHeight,
                            );
                          }),

                          overlayBuilder: _isOverlayActive
                              ? (context, rect) {
                                  final overlay = CustomPaint(
                                    painter: GridPainter(),
                                  );
                                  return overlay;
                                }
                              : null,
                        ),
                      ],
                    ],
                  ),
                  replacement: Center(
                    child: _croppedData == null
                        ? SizedBox.shrink()
                        : Image.memory(_croppedData!),
                  ),
                ),
              ),
            ],
          ),
          replacement: CupertinoActivityIndicator(),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final divisions = 2;
  final strokeWidth = 1.0;
  final Color color = Colors.black54;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..color = color;

    final spacing = size / (divisions + 1);
    for (var i = 1; i < divisions + 1; i++) {
      // draw vertical line
      canvas.drawLine(
        Offset(spacing.width * i, 0),
        Offset(spacing.width * i, size.height),
        paint,
      );

      // draw horizontal line
      canvas.drawLine(
        Offset(0, spacing.height * i),
        Offset(size.width, spacing.height * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
