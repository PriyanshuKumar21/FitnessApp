import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Path Finder'),
        ),
        body: const PathFinderWidget(),
      ),
    );
  }
}

class PathFinderWidget extends StatefulWidget {
  const PathFinderWidget({Key? key}) : super(key: key);

  @override
  State<PathFinderWidget> createState() => _PathFinderWidgetState();
}

class _PathFinderWidgetState extends State<PathFinderWidget> {
  String appDocPath = 'Loading...';
  String tempPath = 'Loading...';
  String appSupportPath = 'Loading...';
  
  @override
  void initState() {
    super.initState();
    _getPaths();
  }
  
  Future<void> _getPaths() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();
      
      print('APPLICATION DOCUMENTS DIRECTORY: ${docDir.path}');
      print('TEMPORARY DIRECTORY: ${tempDir.path}');
      
      setState(() {
        appDocPath = docDir.path;
        tempPath = tempDir.path;
      });
      
      try {
        final supportDir = await getApplicationSupportDirectory();
        print('APPLICATION SUPPORT DIRECTORY: ${supportDir.path}');
        setState(() {
          appSupportPath = supportDir.path;
        });
      } catch (e) {
        print('Error getting support directory: $e');
        setState(() {
          appSupportPath = 'Error: $e';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        appDocPath = 'Error: $e';
        tempPath = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Application Directories:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Documents: $appDocPath'),
            const SizedBox(height: 10),
            Text('Temporary: $tempPath'),
            const SizedBox(height: 10),
            Text('Support: $appSupportPath'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _getPaths,
              child: const Text('Refresh Paths'),
            ),
          ],
        ),
      ),
    );
  }
} 