import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Demo Download File'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loading = false;
  double progress = 0.0;

  Future<bool> _saveFile(String url, String fileName) async {
    Directory directory;
    final Dio dio = Dio();

    try {
      ///CEK PERMISSION DAN MENENTUKAN LOKASI PENYIMPANAN
      if (Platform.isAndroid) {
        if (await _requestPermission(Permission.storage)) {
          directory = (await getExternalStorageDirectory())!;
          print("DEFAULT STORAGE : ${directory.path}");

          String newPath = '';

          ///storage/emulated/0/Android/data/com.example.demo_saving_file/files
          List<String> folders = directory.path.split('/');

          for (int x = 1; x < folders.length; x++) {
            String folder = folders[x];
            if (folder != 'Android') {
              newPath += '/' + folder;
            } else {
              break;
            }
          }

          newPath = newPath + '/DemoSavingFileApp';
          directory = Directory(newPath);
          print("NEW STORAGE : ${directory.path}");
        } else {
          return false;
        }
      } else {
        if (await _requestPermission(Permission.photos)) {
          directory = await getTemporaryDirectory();
        } else {
          return false;
        }
      }

      ///MEMBUAT FOLDER JIKA BELUM ADA
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      ///PROSES DOWNLOAD FILE
      if (await directory.exists()) {
        File saveFile = File(directory.path + "/$fileName");
        await dio.download(
          url,
          saveFile.path,
          onReceiveProgress: (downloaded, totalSize) {
            setState(
              () {
                progress = downloaded / totalSize;
              },
            );
          },
        );

        if (Platform.isIOS) {
          await ImageGallerySaver.saveFile(saveFile.path,
              isReturnPathOfIOS: true);
        }

        return true;
      }
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  _downloadFile() async {
    setState(() {
      loading = true;
    });

    bool downloaded = await _saveFile(
        "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4",
        'video.mp4');

    if (downloaded) {
      print('File Downloaded');
    } else {
      print('Problem Downloading file');
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: loading
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: progress,
                ),
              )
            : ElevatedButton.icon(
                onPressed: _downloadFile,
                icon: Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  "Download File",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                  ),
                ),
              ),
      ),
    );
  }
}
