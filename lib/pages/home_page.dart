import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({
    super.key,
    required this.title,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  File? _selectedFile;
  String? _currentContent;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTextFieldChanged(value) {
    setState(() {
      _currentContent = value;
    });
  }

  Future<void> onSaveShortcutPressed(BuildContext context) async {
    await _saveFile(context);
  }

  void setSelectedFile({required File file, required String content}) {
    setState(() {
      _selectedFile = file;
      _currentContent = content;
      _textEditingController.text = content;
    });
  }

  void _openFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
      );
      print("FilePicker result : $result");

      if (result == null) {
        return;
      }
      String? filePath = result.files.single.path;
      if (filePath == null) {
        return;
      }

      File file = File(filePath);
      String content = await file.readAsString();
      print("Contenu du fichier : ${content.substring(0, 100)} [...]");

      setSelectedFile(file: file, content: content);
    } catch (error) {
      print("Problème d'ouverture du fichier : $error");
    }
  }

  Future<void> _saveFile(BuildContext context) async {
    if (_selectedFile == null || _currentContent == null) {
      return;
    }
    print(
        "Contenu de la saisie utilisateur : ${_currentContent!.substring(0, 100)} [...]");
    try {
      await _selectedFile!.writeAsString(_currentContent!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fichier sauvegardé avec succès !'),
        ));
      }
    } catch (error) {
      print("Problème à la sauvegarde du fichier : $error");
    }
  }

  Future<void> _saveFileAs(BuildContext context) async {
    if (_selectedFile == null || _currentContent == null) {
      return;
    }

    String? outputFilePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Veuillez choisir un fichier :',
      fileName: basename(_selectedFile!.path),
    );

    if (outputFilePath == null) {
      // User canceled the picker
      return;
    }

    print('Nouveau fichier choisi : $outputFilePath');
    File file = File(outputFilePath);
    setSelectedFile(file: file, content: _currentContent!);
    await _saveFile(context);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyS,
            control: !Platform.isMacOS,
            meta: Platform.isMacOS): () => onSaveShortcutPressed(context),
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Markdown Editor"),
        ),
        body: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _openFile,
                    child: const Text("Ouvrir un fichier"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed:
                        _selectedFile != null ? () => _saveFile(context) : null,
                    child: const Text("Sauvegarder le fichier"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _selectedFile != null
                        ? () => _saveFileAs(context)
                        : null,
                    child: const Text("Sauvegarder le fichier sous..."),
                  ),
                ),
              ],
            ),
            if (_selectedFile != null)
              Text("Opened file : ${_selectedFile!.uri}"),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: TextField(
                        controller: _textEditingController,
                        expands: true,
                        maxLines: null,
                        onChanged: _onTextFieldChanged,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: VerticalDivider(
                        thickness: 4,
                      ),
                    ),
                    Flexible(
                        flex: 1,
                        child: Markdown(
                          data: _currentContent ?? '',
                        )),
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
