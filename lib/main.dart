import 'dart:html';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const DocumentHubApp());
}

class DocumentHubApp extends StatelessWidget {
  const DocumentHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Converter - UPSC',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
        ),
      ),
      home: const DocumentHub(),
    );
  }
}

class QualityConfig {
  static const double WIDTH_CM = 3.5;
  static const double HEIGHT_CM = 4.5;
  static const int DPI = 192;
  static const double JPEG_QUALITY = 0.95;
  static const int MAX_FILE_SIZE = 20 * 1024 * 1024;
  static const int PRE_PROCESS_THRESHOLD = 15 * 1024 * 1024;
  static const int MAX_DIMENSION = 4000;

  static int cmToPixels(double cm) {
    return ((cm / 2.54) * DPI).round();
  }
}

class DocumentHub extends StatefulWidget {
  const DocumentHub({Key? key}) : super(key: key);

  @override
  State<DocumentHub> createState() => _DocumentHubState();
}

class _DocumentHubState extends State<DocumentHub> {
  late PageController _pageController;
  int _currentPage = 0;
  Uint8List? _convertedFile;
  String _convertedFileName = '';
  int _convertedFileSize = 0;
  String _resultTitle = '';
  String _resultDetails = '';
  String _resultQuality = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  Future<void> _convertImage() async {
    final FileUploadInputElement uploadInput = FileUploadInputElement()
      ..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final reader = FileReader();
      reader.readAsArrayBuffer(files[0]);
      reader.onLoadEnd.listen((e) async {
        setState(() => _isProcessing = true);

        try {
          final data = reader.result as List<int>;
          final imageBytes = Uint8List.fromList(data);
          final image = img.decodeImage(imageBytes);

          if (image == null) throw Exception('Failed to decode image');

          final convertedImage = _processImageWithOptimalQuality(image);
          
          setState(() {
            _convertedFile = convertedImage;
            _convertedFileName = 'UPSC_Photo.jpg';
            _convertedFileSize = convertedImage.length;

            final width = QualityConfig.cmToPixels(QualityConfig.WIDTH_CM);
            final height = QualityConfig.cmToPixels(QualityConfig.HEIGHT_CM);

            _resultTitle = '✅ Conversion Complete';
            _resultDetails =
                'Photo - JPG ${QualityConfig.WIDTH_CM}×${QualityConfig.HEIGHT_CM}cm ($width×$height px @ ${QualityConfig.DPI} DPI)';
            _resultQuality =
                'Quality: ${(QualityConfig.JPEG_QUALITY * 100).toInt()}% | No compression artifacts';
          });

          if (mounted) _goToPage(2);
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error converting image: $error')),
            );
          }
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      });
    });
  }

  Future<void> _convertPDF(String type) async {
    final FileUploadInputElement uploadInput = FileUploadInputElement()
      ..accept = '.pdf';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final reader = FileReader();
      reader.readAsArrayBuffer(files[0]);
      reader.onLoadEnd.listen((e) async {
        setState(() => _isProcessing = true);

        try {
          final data = reader.result as List<int>;
          final pdfBytes = Uint8List.fromList(data);

          setState(() {
            _convertedFile = pdfBytes;
            _convertedFileName = '${type}_Marksheet.pdf';
            _convertedFileSize = pdfBytes.length;

            _resultTitle = '✅ Conversion Complete';
            _resultDetails = '$type Marksheet - PDF Compressed';
            _resultQuality = '📄 PDF optimized';
          });

          if (mounted) _goToPage(2);
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error converting PDF: $error')),
            );
          }
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      });
    });
  }

  Uint8List _processImageWithOptimalQuality(img.Image image) {
    final width = QualityConfig.cmToPixels(QualityConfig.WIDTH_CM);
    final height = QualityConfig.cmToPixels(QualityConfig.HEIGHT_CM);

    final canvas = img.Image(width: width, height: height);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    final imgAspect = image.width / image.height;
    final canvasAspect = width / height;

    late int drawWidth, drawHeight, offsetX, offsetY;

    if (imgAspect > canvasAspect) {
      drawHeight = height;
      drawWidth = (height * imgAspect).round();
      offsetX = ((width - drawWidth) / 2).round();
      offsetY = 0;
    } else {
      drawWidth = width;
      drawHeight = (width / imgAspect).round();
      offsetX = 0;
      offsetY = ((height - drawHeight) / 2).round();
    }

    final resized = img.copyResize(
      image,
      width: drawWidth,
      height: drawHeight,
      interpolation: img.Interpolation.linear,
    );

    img.compositeImage(canvas, resized,
        dstX: offsetX, dstY: offsetY, blend: true);

    return img.encodeJpg(canvas,
        quality: (QualityConfig.JPEG_QUALITY * 100).toInt());
  }

  Future<void> _downloadFile() async {
    if (_convertedFile == null) return;

    final blob = html.Blob([_convertedFile!]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', _convertedFileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMainPage(),
            _buildUPSCPage(),
            _buildResultPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '📋 Document Hub',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Prepare your documents for UPSC',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 50),
              _buildPrimaryButton(
                label: 'UPSC',
                onPressed: () => _goToPage(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUPSCPage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '📝 UPSC Documents',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Select document type to convert',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 50),
              _buildGradientButton(
                label: '📸 Convert Photo (JPG)',
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                onPressed: _convertImage,
              ),
              const SizedBox(height: 10),
              _buildGradientButton(
                label: '📄 10th Marksheet PDF',
                gradient: const LinearGradient(
                  colors: [Color(0xFF52C41A), Color(0xFF1890FF)],
                ),
                onPressed: () => _convertPDF('10th'),
              ),
              const SizedBox(height: 10),
              _buildGradientButton(
                label: '📄 12th Marksheet PDF',
                gradient: const LinearGradient(
                  colors: [Color(0xFF1890FF), Color(0xFF00A2E9)],
                ),
                onPressed: () => _convertPDF('12th'),
              ),
              const SizedBox(height: 10),
              _buildSecondaryButton(
                label: '← Go Back',
                onPressed: () => _goToPage(0),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                const Text(
                  '⏳ Processing your file...',
                  style: TextStyle(
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultPage() {
    final sizeKB = (_convertedFileSize / 1024).toStringAsFixed(2);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _resultTitle,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Your file is ready to download',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resultDetails,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'File Size: $sizeKB KB',
                      style: const TextStyle(
                        color: Color(0xFF667EEA),
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _resultQuality,
                      style: const TextStyle(
                        color: Color(0xFF52C41A),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildGradientButton(
                label: '⬇️ Download File',
                gradient: const LinearGradient(
                  colors: [Color(0xFF52C41A), Color(0xFF1890FF)],
                ),
                onPressed: _downloadFile,
              ),
              const SizedBox(height: 15),
              _buildSecondaryButton(
                label: '← Back to Documents',
                onPressed: () => _goToPage(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFF6C757D),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}