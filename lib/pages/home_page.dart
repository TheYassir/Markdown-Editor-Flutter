// ignore_for_file: avoid_print

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

  // Automatiquement appelée par Flutter à l'initialisation du Widget
  @override
  void initState() {
    // Alternative au TextField#onChanged(), (la ligne 187)
    // _textEditingController.addListener(() {
    //   setState(() {});
    // });

    super.initState();
  }

  // Automatiquement appelée par Flutter quand le widget est détruit
  // à utiliser par exemple pour libérer les ressources
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
    // setState() va déclancher le rebuild de mon widget
    setState(() {
      // Mettre ici UNIQUEMENT l'affectation de valeur aux attribut du State
      // (Convention Flutter, évite des erreurs de build asynchrone)
      // https://api.flutter.dev/flutter/widgets/State/setState.html
      _selectedFile = file;
      _currentContent = content;
      _textEditingController.text = content;
    });
  }

  void _openFile() async {
    try {
      // Utilise la lib file_picker pour afficher une fenêtre de choix de fichier
      // adaptée à la plateforme d'éxecution (Windows, Linux ou macOS)
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

      // On instancie un variable de la class dart File avec le path choisi par l'utilisateur
      // (représente directement un Fichier sur le système)
      File file = File(filePath);
      // On lit le contenu du fichier
      // L'accès au fichier sur le disque se fait uniquement à ce moment
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
      // On écrit le contenu du fichier sur le disque (écrase le contenu existant)
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

    // On utilise la lib FilePicker pour afficher une fenêtre de choix de fichier
    // FilePicker.saveFile() permet de choisir un fichier et de définir un nom de fichier 
    String? outputFilePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Veuillez choisir un fichier :',
      fileName: basename(_selectedFile!.path),
    );

    if (outputFilePath == null) {
      // User canceled the picker
      return;
    }

    print('Nouveau fichier choisi : $outputFilePath');
    // On change le fichier sélectionné par l'utilisateur
    File file = File(outputFilePath);
    setSelectedFile(file: file, content: _currentContent!);
    // ignore: use_build_context_synchronously
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
              Text("Opened file : ${_selectedFile!.path}"),
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
