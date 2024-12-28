import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

void runSpeechToTextWithGemini() async {
  FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
  GenerativeModel model =
      vertexAI.generativeModel(model: "gemini-1.5-flash-001");

  final Response responseData = await get(Uri.parse(
      "https://firebasestorage.googleapis.com/v0/b/mirrorview-ai.appspot.com/o/audio_input_speech2text%2FrecordedFile.mp3?alt=media&token=ea632e99-8e66-4906-a036-ddb7d099b3ee"));
  var uint8list = responseData.bodyBytes;

  GenerateContentResponse content = await model.generateContent([
    Content("user", [
      TextPart(
          "Transcribe the following audio file. Please provide the transcription in text format, ensuring accuracy and proper punctuation."),
      DataPart("audio/mpeg", uint8list)
    ])
  ]);
  if (kDebugMode) {
    print(content.text);
    print(content.candidates);
  }
}

void saveAudioData(Uint8List data) async {
  File recordedFile = File(
      "${(await getApplicationDocumentsDirectory()).path}/recordedFile.wav");
  if (kDebugMode) {
    print(recordedFile.path);
  }
  recordedFile.writeAsBytes(data);
}

void deletePrompts() async {
  Directory dir = Directory((await getApplicationDocumentsDirectory()).path);
  List<FileSystemEntity> entities = dir.listSync();
  bool exsits =
      entities.any((fse) => fse.uri.pathSegments.last.startsWith("prompts_x_"));
  if (exsits) {
    FileSystemEntity fse = entities.firstWhere(
        (fse) => fse.uri.pathSegments.last.startsWith("prompts_x_"));
    final fileName = fse.uri.pathSegments.last;
    File("${dir.path}/$fileName").deleteSync();
  }
}
