import 'dart:html';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DocumentConverter(),
    );
  }
}

class DocumentConverter extends StatefulWidget {
  @override
  _DocumentConverterState createState() => _DocumentConverterState();
}

class _DocumentConverterState extends State<DocumentConverter> {
  String? _fileName;
  String? _fileContent;

  void _pickFile() async {
    FileUploadInputElement uploadInput = FileUploadInputElement();
    uploadInput.accept = '.txt, .pdf';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final reader = FileReader();
      reader.readAsText(uploadInput.files![0]);
      reader.onLoadEnd.listen((e) {
        setState(() {
          _fileName = uploadInput.files![0].name;
          _fileContent = reader.result as String;
        });
      });
    });
  }

  void _downloadFile() {
    if (_fileName != null && _fileContent != null) {
      AnchorElement(href: 'data:text/plain;charset=utf-8,' + Uri.encodeComponent(_fileContent!))
        ..setAttribute('download', _fileName!)
        ..click();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Converter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_fileName ?? 'No file selected'),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Pick a file'),
            ),
            ElevatedButton(
              onPressed: _downloadFile,
              child: Text('Download file'),
            ),
          ],
        ),
      ),
    );
  }
}