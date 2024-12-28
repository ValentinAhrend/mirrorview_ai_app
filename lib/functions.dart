// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:html/dom.dart' as d;
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mirror_view/tests.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> introNeeded() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool? introDone = prefs.getBool('introDone');
  if (introDone == null) {
    return true;
  }
  return !introDone;
}

void finishIntro() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('introDone', true);
}

double getSafeHeight(BuildContext context) {
  var padding = MediaQuery.of(context).padding;
  return MediaQuery.sizeOf(context).height - padding.top - padding.bottom;
}

const ConversationStandardValues = {
  "attitude": "nice",
  "type": "interview",
  "version": "1",
  "mainTopic": "New Interview",
  "insights": []
};

class ChatMessage extends Message {
  int loadingState = 0;
  File? audioFile;

  ChatMessage(super.jsonData, super.messageId);

  void setNewData(String content) {
    this.content = content;
    loadingState = 1;
  }

  void addAudioFile(audio) {
    audioFile = audio;
  }

  static ChatMessage fromMessage(Message msg) {
    ChatMessage m = ChatMessage(msg.toJSON(), msg.messageId);
    m.audioFile = null;
    m.loadingState = 2;
    return m;
  }
}

Future<File> generateAudio(String text, String audioId) async {
  final ref =
      FirebaseFirestore.instance.collection("text_input_text2speech").doc();
  await ref.set({"text": text});
  DocumentSnapshot<Map<String, dynamic>> snap =
      await ref.snapshots().firstWhere((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return snapshot.data()!.containsKey("audioPath");
    }
    return false;
  });
  final audioPath = snap.data()!["audioPath"];
  final gsReference = FirebaseStorage.instance.refFromURL(audioPath);

  /// download to cache file
  final cacheTemp = await getApplicationCacheDirectory();
  File audioFile = File("${cacheTemp.path}/$audioId.mp3");
  audioFile = await audioFile.create();
  DownloadTask task = gsReference.writeToFile(audioFile);
  await task;
  // delete audio file in storage...
    gsReference.delete();
  print(audioFile.path);
  return audioFile;
}

Future<int> registerTokens(int number_of_tokens) async {
  final result = await FirebaseFunctions.instance
      .httpsCallable("addTokens")
      .call({"text": number_of_tokens});
  if (result.data is num) {
    /// check if it is under MAX TOKEN LIMIT
    final max_prompts = int.parse(await loadPrompt("max_token_limit"));
    if (max_prompts < result.data) {
      /// PREVENT EXPLOIT
      exit(0);
    }
    return result.data;
  }
  return 0;
}

void saveTokens(GenerateContentResponse res) {
  if (res.usageMetadata != null) {
    if (res.usageMetadata!.totalTokenCount != null) {
      registerTokens(res.usageMetadata!.totalTokenCount!);
    }
  }
}

void countFeedback() async {
  await FirebaseFunctions.instance
      .httpsCallable("countFeedback")
      .call({"text": ""});
}

class Conversation {
  late String convId;
  late String attitude;
  late String type;
  late String version;
  late String mainTopic;
  late Map<String, dynamic> insights;

  String? profileId;
  InterviewProfile? realProfile;

  late List<ChatFeedback> feedbacks = [];
  late List<Message> messages = [];

  late DateTime? createdAt;

  Function(Message)? messageListener;
  Function? chatSettingListener;

  Conversation(var jsonData) {
    /// read json data
    if (jsonData is String) {
      jsonData = json.decode(jsonData);
    }
    init(jsonData);
  }
  void init(Map jsonData) {
    /// initialize conversation
    print(jsonData);
    List<String> mainKeys = [
      "conv_id",
      "attitude",
      "type",
      "version",
      "mainTopic",
      "insights"
    ];

    /// assert (jsonData.keys.every((key)=>mainKeys.contains(key)));??? other way around
    assert(mainKeys.every((key) => jsonData.keys.contains(key)));
    convId = jsonData[mainKeys[0]];
    attitude = jsonData[mainKeys[1]];
    type = jsonData[mainKeys[2]];
    version = jsonData[mainKeys[3]];
    mainTopic = jsonData[mainKeys[4]];
    insights = jsonData[mainKeys[5]];
    if (jsonData.keys.contains("profile_ref")) {
      profileId = jsonData["profile_ref"];
    }
    if (jsonData.keys.contains("feedbacks")) {
      feedbacks = [];
      for (var element in List.from(jsonData["feedbacks"])) {
        if (element.containsKey("overview")) {
          feedbacks.add(MainFeedback(element));
          continue;
        }

        feedbacks.add(ChatFeedback(element));
      }
    }
    if (jsonData.keys.contains("messages")) {
      messages = [];
      for (var i = 0; i < List.from(jsonData["messages"]).length; i++) {
        messages.add(Message(jsonData["messages"][i], i));
      }
    }
    if (profileId != null && profileId!.isNotEmpty) {
      /// load profile
      loadInterviewProfile(profileId!).then((x) {
        realProfile = x;
      });
    }
    if (jsonData.keys.contains("created_at")) {
      createdAt = jsonData["created_at"].toDate();
    }
  }

  bool isEmpty() {
    return convId == "-1";
  }

  void addCreatedAt(DateTime dt) {
    createdAt = dt;
  }

  void addMessageListener(Function(Message) listener) {
    messageListener = listener;
  }

  void dispose() {
    /// stop everything...
    ///
    session = null;
  }

  final STOP_SEQUENCE = "EndInterview_374952345_StopGenerate";
  ChatSession? session;

  Future<MainFeedback> createMainFeedback() async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('startConversation')
        .call({
      "body": {"": ""}
    });

    final response = result.data;
    realProfile ??= await loadInterviewProfile(profileId!);
    final basePrompt = response["prompt"];
    FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
    final model = vertexAI.generativeModel(
        model: "gemini-1.5-pro", systemInstruction: Content.system(basePrompt));
    session = model.startChat(
        generationConfig: GenerationConfig(stopSequences: [STOP_SEQUENCE]),
        history: [
          Content.text(json.encode(realProfile!.toJSON())),
          ...messages.map((msg) {
            if (msg.role == Role.bot) {
              return Content.model([TextPart(msg.content)]);
            } else {
              return Content.text(msg.content.replaceAll("\"", ""));
            }
          })
        ]);
    final endPrompt = await loadPrompt("chat_end_base");
    final taskPrompt = await loadPrompt("chat_end_task");
    // print(session!.history.map((x)=>x.role!));
    final finalResponse =
        await session!.sendMessage(Content.text("$endPrompt\n$taskPrompt"));
    var cText = finalResponse.text;
    saveTokens(finalResponse);
    if (cText == null) {
      return MainFeedback.empty();
    }
    File f = File("${(await getApplicationDocumentsDirectory()).path}/x.txt");
    f.writeAsBytes(Uint8List.fromList(cText.codeUnits));
    if (cText.startsWith("```json") && cText.contains("```", 3)) {
      final onlyJsonString = cText
          .trimRight()
          .substring("```json".length, cText.indexOf("```", 3));
      final jsonObject = json.decode(onlyJsonString);
      if (jsonObject != null && json.encode(jsonObject).startsWith("{")) {
        /// try to parse data
        var jsonData = {"created_at": Timestamp.now(), "msgId": -1};
        final headers = [
          "content_analysis",
          "language_analysis",
          "other_feedback"
        ];
        for (var head in headers) {
          if (!jsonObject.containsKey(head)) {
            continue;
          }
          final dd = jsonObject[head];
          var prefix = head.substring(0, head.indexOf("_"));
          if (prefix == "language") {
            prefix = "lang";
          }
          if (!(dd is String || dd is num || dd is List)) {
            dd.forEach((k, v) {
              if (k.toString().contains("rating")) {
                jsonData["${prefix}_rate"] = parseIf(v);
              }
              if (k.toString().contains("advice")) {
                jsonData["${prefix}_adv"] = v;
              }
              if (k.toString().contains("analysis")) {
                jsonData["${prefix}_problem"] = v;
              }
            });
          }
          if (jsonObject.containsKey("overview")) {
            jsonData["overview"] = jsonObject["overview"];
          }
        }
        countFeedback();
        MainFeedback newFeedback = MainFeedback(jsonData);
        feedbacks.add(newFeedback);

        await updateConversation(this);

        return newFeedback;
      }
    }
    return MainFeedback.empty();
  }

  Future<bool> endInterview() async {
    if (kDebugMode) {
      print("endInterview");
    }

    /// finish prompt is the stop sequence and a prompt delivered in a txt file...
    /// create real feedback
    if (session == null) {
      return false;
    }
    final endPrompt = await loadPrompt("chat_end_base");
    final taskPrompt = await loadPrompt("chat_end_task");
    final finalResponse =
        await session!.sendMessage(Content.text("$endPrompt\n$taskPrompt"));
    var cText = finalResponse.text;
    saveTokens(finalResponse);
    if (cText == null) {
      return false;
    }
    File f = File("${(await getApplicationDocumentsDirectory()).path}/x.txt");
    f.writeAsBytes(Uint8List.fromList(cText.codeUnits));
    if (kDebugMode) {
     
    }
     print(f.path);
    if (cText.startsWith("```json") && cText.contains("```", 3)) {
      final onlyJsonString = cText
          .trimRight()
          .substring("```json".length, cText.indexOf("```", 3));
      try {
        final jsonObject = json.decode(onlyJsonString);

        if (jsonObject != null && json.encode(jsonObject).startsWith("{")) {
          /// try to parse data
          var jsonData = {"created_at": Timestamp.now(), "msgId": -1};
          final headers = [
            "content_analysis",
            "language_analysis",
            "other_feedback"
          ];
          for (var head in headers) {
            if (!jsonObject.containsKey(head)) {
              continue;
            }
            final dd = jsonObject[head];
            var prefix = head.substring(0, head.indexOf("_"));
            if (prefix == "language") {
              prefix = "lang";
            }
            if (!(dd is String || dd is num || dd is List)) {
              dd.forEach((k, v) {
                if (k.toString().contains("rating")) {
                  jsonData["${prefix}_rate"] = parseIf(v);
                }
                if (k.toString().contains("advice")) {
                  jsonData["${prefix}_adv"] = v;
                }
                if (k.toString().contains("analysis")) {
                  jsonData["${prefix}_problem"] = v;
                }
              });
            }
            if (jsonObject.containsKey("overview")) {
              jsonData["overview"] = jsonObject["overview"];
            }
          }
          MainFeedback newFeedback = MainFeedback(jsonData);
          countFeedback();
          feedbacks.add(newFeedback);

          await updateConversation(this);

          return true;
        }
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  void startInterview() async {
    /// load prompt using firebase functions
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('startConversation')
          .call({
        "body": {"": ""}
      });

      var obj = {};
      bool cvJSONAvailable = await jsonCVThere();

      if (cvJSONAvailable) {
        ///load json content
        final fileName = "${currentUserAccountGlobally!.uid}_resume.json";
        File fx = File(
            "${(await getApplicationDocumentsDirectory()).path}/$fileName");
        print(fx.path);
        final jsonString = fx.readAsStringSync();
        obj = json.decode(jsonString);
      }
      final response = result.data;

      final basePrompt = response["prompt"];
      FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
      final model = vertexAI.generativeModel(
          model: "gemini-1.5-pro",
          systemInstruction: Content.system(basePrompt));
      session = model.startChat(
          generationConfig: GenerationConfig(
        stopSequences: [STOP_SEQUENCE],
      ));

      ChatMessage initialMessage = ChatMessage(
          {"content": "", "role": "bot", "created_at": Timestamp.now()}, 0);

      session!
          .sendMessage(
              Content.text(json.encode({...realProfile!.toJSON(), ...obj})))
          .then((res) {
        final txt = res.text;
        if (txt != null) {
          /// check if isVoice
          initialMessage.setNewData(txt);
          bool isVoice = chatSettingListener!();
          if (!isVoice) {
            initialMessage.loadingState = 2;
          }
          messageListener!(initialMessage);
          messages.add(initialMessage);
          if (isVoice) {
            /// generate audio
            print("generateAudio");
            generateAudio(txt, convId + initialMessage.messageId.toString())
                .then((audioFile) {
              print("audioGenerated");
              initialMessage.addAudioFile(audioFile);
              initialMessage.loadingState = 2;
              messages.removeWhere(
                  (msg) => msg.messageId == initialMessage.messageId);
              messages.add(initialMessage);
              messageListener!(initialMessage);
            });
          }
        }
      });
    } on FirebaseFunctionsException catch (error) {
      print(error.code);
      print(error.details);
      print(error.message);
    }
  }

  Future<bool> sendMessage(String content) async {
    if (session == null) {
      return false;
    }
    if (messages.isEmpty) {
      /// cannot be the first message
      return false;
    }

    /// does the message always has a prefix
    /// more secure
    const String msgPrefix = "Here is the answer:\n";
    ChatMessage nextMsg = ChatMessage(
        {"content": content, "role": "user", "created_at": Timestamp.now()},
        messages.length);
    nextMsg.loadingState = 2;
    ChatMessage nextResponse = ChatMessage(
        {"content": "", "role": "bot", "created_at": Timestamp.now()},
        messages.length + 1);
    messages.add(nextMsg);
    messageListener!(nextMsg);
    GenerateContentResponse res = await session!
        .sendMessage(Content.text(msgPrefix + content.replaceAll("\"", "")));
    if (res.text == null) {
      return false;
    }
    saveTokens(res);
    final cText = res.text!;
    bool isVoice = chatSettingListener!();
    nextResponse.setNewData(cText);
    if (!isVoice) {
      nextResponse.loadingState = 2;
    }
    messages.add(nextResponse);
    messageListener!(nextResponse);
    if (isVoice) {
      /// generate audio
      generateAudio(cText, convId + nextResponse.messageId.toString())
          .then((audioFile) {
        nextResponse.addAudioFile(audioFile);
        nextResponse.loadingState = 2;
        messages.removeWhere((msg) => msg.messageId == nextResponse.messageId);
        messages.add(nextResponse);
        messageListener!(nextResponse);
      });
    }
    print("sendMessage");
    await updateConversation(this);
    return true;
  }

  void setProfile(String profileId) async {
    this.profileId = profileId;
    realProfile = await loadInterviewProfile(profileId);
  }

  static Future<Conversation> createFromProfile(
      InterviewProfile profile) async {
    var mainTopic = profile.firmName;
    if (mainTopic.isEmpty) {
      mainTopic = ConversationStandardValues["mainTopic"].toString();
    }
    var attitude = ConversationStandardValues["attitude"].toString();
    var type = ConversationStandardValues["type"].toString();
    var version = ConversationStandardValues["version"].toString();

    /// insights are profile values with addiotionalInfo
    final Conversation freshConvo = Conversation({
      "conv_id": "-1",
      "attitude": attitude,
      "type": type,
      "version": version,
      "mainTopic": mainTopic,
      "insights": {}.cast<String, String>()
    });
    if (profile.profileId != null) {
      freshConvo.profileId = profile.profileId!;
      freshConvo.realProfile = profile;
    } else {
      print("profile ref is 0");
    }
    freshConvo.addCreatedAt(DateTime.now());
    return createNewConversationInCloud(freshConvo);
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> mainData = {
      "conv_id": convId,
      "attitude": attitude,
      "type": type,
      "insights": insights,
      "mainTopic": mainTopic,
      "profile_ref": profileId,
      "version": version,
      "created_at": Timestamp.fromDate(createdAt!),
      // ignore: unnecessary_null_comparison
      "feedbacks": feedbacks == null
          ? []
          : feedbacks.map((feedback) => feedback.toJSON()),
      // ignore: unnecessary_null_comparison
      "messages": messages == null ? [] : messages.map((msg) => msg.toJSON())
    };
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      mainData["uid"] = user.uid;
    }
    return mainData;
  }

  factory Conversation.fromFirestoreQuery(QueryDocumentSnapshot snapshot) {
    var data = snapshot.data();
    if (data == null) {
      return Conversation.empty();
    }
    data = data as Map;
    if (data.containsKey("conv_id") &&
        data.containsKey("attitude") &&
        data.containsKey("type") &&
        data.containsKey("version") &&
        data.containsKey("mainTopic") &&
        data.containsKey("insights") &&
        data.containsKey("profile_ref")) {
      Conversation freshConvo = Conversation(data);
      if (data.containsKey("created_at")) {
        freshConvo.addCreatedAt(data["created_at"] is Timestamp
            ? data["created_at"].toDate()
            : DateTime.now());
      }

      /// load profile from firestore
      /// final InterviewProfile profile = await loadInterviewProfile(freshConvo.profileId);
      /// freshConvo.realProfile = profile;
      freshConvo.setProfile(data["profile_ref"]);
      return freshConvo;
    } else {
      return Conversation.empty();
    }
  }

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      return Conversation.empty();
    }

    if (data.containsKey("conv_id") &&
        data.containsKey("attitude") &&
        data.containsKey("type") &&
        data.containsKey("version") &&
        data.containsKey("mainTopic") &&
        data.containsKey("insights") &&
        data.containsKey("profile_ref")) {
      Conversation freshConvo = Conversation(data);
      if (data.containsKey("created_at")) {
        freshConvo.addCreatedAt(data["created_at"] is Timestamp
            ? data["created_at"].toDate()
            : DateTime.now());
      }

      /// load profile from firestore
      /// final InterviewProfile profile = await loadInterviewProfile(freshConvo.profileId);
      /// freshConvo.realProfile = profile;
      freshConvo.setProfile(data["profile_ref"]);
      return freshConvo;
    } else {
      return Conversation.empty();
    }
  }
  static Conversation empty() {
    return Conversation({
      "conv_id": "-1",
      "attitude": "",
      "type": "",
      "version": "",
      "mainTopic": "",
      "insights": {}
    });
  }
}

int parseIf(dynamic input) {
  if (input is String) {
    return num.parse(input).toInt();
  }
  if(input is double) {
    return input.toInt();
  }
  if (input == null) {
    return 0;
  }
  return input;
}

class MainFeedback extends ChatFeedback {
  late String overview;

  late int otherRating;
  late String otherAdvice;
  late String otherAnalysis;

  MainFeedback(var jsonData) : super(jsonData) {
    if (jsonData is String) {
      jsonData = json.decode(jsonData);
    }
    otherRating = parseIf(jsonData["other_rate"]);
    otherAdvice = jsonData["other_adv"];
    otherAnalysis = jsonData["other_problem"];
    overview = jsonData["overview"];
  }

  static MainFeedback empty() {
    return MainFeedback({
      "lang_rate": 0,
      "lang_adv": "",
      "lang_problem": "",
      "other_rate": 0,
      "other_adv": "",
      "other_problem": "",
      "overview": "",
      "content_rate": 0,
      "content_adv": "",
      "content_problem": "",
      "msgId": -2,
      "created_at": Timestamp.now()
    });
  }

  @override
  dynamic toJSON() {
    return {
      "lang_rate": languageRating,
      "lang_adv": languageAdvice,
      "lang_problem": languageAnalysis,
      "content_rate": contentRating,
      "content_adv": contentAdvice,
      "content_problem": contentAnalysis,
      "messageId": messageId,
      "overview": overview,
      "other_rate": otherRating,
      "other_adv": otherAdvice,
      "other_problem": otherAnalysis,
      "created_at": Timestamp.fromDate(createdAt)
    };
  }
}

class ChatFeedback {
  late int languageRating;
  late String languageAdvice;
  late String languageAnalysis;

  late int contentRating;
  late String contentAdvice;
  late String contentAnalysis;

  late int messageId;
  late DateTime createdAt;

  ChatFeedback(var jsonData) {
    if (jsonData is String) {
      jsonData = json.decode(jsonData);
    }
    init(jsonData);
  }

  void init(Map<String, dynamic> jsonData) {
    languageRating = parseIf(jsonData["lang_rate"]);
    languageAdvice = jsonData["lang_adv"];
    languageAnalysis = jsonData["lang_problem"];
    contentRating = parseIf(jsonData["content_rate"]);
    contentAdvice = jsonData["content_adv"];
    contentAnalysis = jsonData["content_problem"];
    messageId = parseIf(jsonData["msgId"]);
    if (jsonData["created_at"] is Timestamp) {
      createdAt = jsonData["created_at"].toDate();
    } else {
      createdAt = DateTime.now();
    }
  }

  static ChatFeedback empty() {
    return ChatFeedback({
      "lang_rate": 0,
      "lang_adv": "",
      "lang_problem": "",
      "content_rate": 0,
      "content_adv": "",
      "content_problem": "",
      "msgId": -2,
      "created_at": Timestamp.now()
    });
  }

  bool isEmpty() {
    return messageId == -2;
  }

  dynamic toJSON() {
    return {
      "lang_rate": languageRating,
      "lang_adv": languageAdvice,
      "lang_problem": languageAnalysis,
      "content_rate": contentRating,
      "content_adv": contentAdvice,
      "content_problem": contentAnalysis,
      "messageId": messageId,
      "created_at": Timestamp.fromDate(createdAt)
    };
  }
}

enum Role { user, bot }

String nearestAgo(Duration d) {
  final sm = [d.inDays, d.inHours, d.inMinutes, d.inSeconds];
  final dm = ["d ago", "h ago", "min ago", "s ago"];
  for (var i = 0; i < sm.length; i++) {
    if (sm[i] > 0) {
      return sm[i].toString() + dm[i];
    }
  }
  return "now";
}

class Message {
  final int messageId;
  late String content;
  late Role role;

  late DateTime createdAt;

  Message(var jsonData, this.messageId) {
    if (jsonData is String) {
      jsonData = json.decode(jsonData);
    }
    init(jsonData);
  }

  void init(Map<String, dynamic> jsonData) {
    role = jsonData["role"] == "bot" ? Role.bot : Role.user;
    content = jsonData["content"];
    if (jsonData["created_at"] is Timestamp) {
      createdAt = jsonData["created_at"].toDate();
    } else {
      createdAt = DateTime.now();
    }
  }

  dynamic toJSON() {
    return {
      "created_at": Timestamp.fromDate(createdAt),
      "role": role.name,
      "content": content,
    };
  }
}

Future<String> transcribeWithGemini(Uint8List data) async {
  FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
  GenerativeModel model =
      vertexAI.generativeModel(model: "gemini-1.5-flash", safetySettings: []);

  saveAudioData(data);

  final trans_base = await loadPrompt("trans_base");
  final trans_task = await loadPrompt("trans_task");
  if (trans_task.isEmpty || trans_base.isEmpty) {
    if (kDebugMode) {
      print("TRANSCRIBE PROMPT NOT FOUND");
    }
  }
  GenerateContentResponse content = await model.generateContent([
    Content("user", [TextPart(trans_base), DataPart("audio/wav", data)]),
    Content("model", [TextPart(trans_task)])
  ]);
  if (content.promptFeedback != null) {
    if (content.promptFeedback!.blockReason != null) {
      if (kDebugMode) {
        print("Text was blocked");
      }
      return "";
    }
  }
  if (content.text == null) {
    if (kDebugMode) {
      print("Text is null");
    }
    return "";
  }
  saveTokens(content);
  return content.text!;
}

class AmplitudePreview {
  late double max;
  late double min;
  late List<double> dataPoints;
  late Duration previewDuration;

  late double rate = 0;

  AmplitudePreview(this.max, this.previewDuration) {
    dataPoints = [];
    if (max < 0) {
      min = -160;
    } else {
      min = 160;
    }
  }

  void add(double currentAmplitude) {
    if (rate < 0) {
      rate = DateTime.now().millisecondsSinceEpoch + rate;
    } else {
      if (rate == 0) {
        rate = -1.0 * DateTime.now().millisecondsSinceEpoch;
      } else {
        /// end of line
        if (dataPoints.length * rate >= previewDuration.inMilliseconds) {
          dataPoints.removeAt(0);
          dataPoints.add(currentAmplitude);
        } else {
          dataPoints.add(currentAmplitude);
        }
        return;
      }
    }
  }

  final double noise = 0.00001;
  final double diff = 1.7;
  final int sampleLength = 20;
  bool evaluateBreakpoint(double lastAmplitude, double nextAmplitude) {
    if (dataPoints.length < sampleLength) {
      return false;
    }
    lastAmplitude = (lastAmplitude).abs();
    nextAmplitude = (nextAmplitude).abs();

    /// calc percentage
    double lastVolume =
        ((lastAmplitude - max.abs()) / (min.abs() - max.abs())).abs();
    double nextVolume =
        ((nextAmplitude - max.abs()) / (min.abs() - max.abs())).abs();
    if (nextVolume > lastVolume) {
      /// check median
      if (lastVolume < noise) {
        /// breakup in every case
        return true;
      }

      /// check median
      double medianX = dataPoints
              .getRange(dataPoints.length - sampleLength, dataPoints.length)
              .map(((d) => ((d - max.abs()) / (min.abs() - max.abs())).abs()))
              .reduce((a, b) => a + b) /
          dataPoints.length;
      if (lastVolume * diff < medianX) {
        return true;
      }
    }
    return false;
  }
}

String mergeTexts(Map<double, String> texts) {
  List<double> doubleKeys = texts.keys.toList();
  doubleKeys.sort();
  List<String> sortedTexts = doubleKeys.map((d) => texts[d]!).toList();
  String totalText = "";
  var splitWordsLatest = [];
  for (var i = 0; i < sortedTexts.length; i++) {
    totalText = totalText + sortedTexts[i];
    if (i < sortedTexts.length - 1) {
      if (splitWordsLatest.isEmpty) {
        splitWordsLatest = sortedTexts[i].split(" ");
      }
      if (splitWordsLatest.isNotEmpty) {
        String lastWord = splitWordsLatest.last;
        splitWordsLatest = sortedTexts[i + 1].split(" ");
        if (splitWordsLatest.isNotEmpty) {
          String firstWord = splitWordsLatest.first;
          if (lastWord == firstWord) {
            sortedTexts[i + 1].substring(
                sortedTexts[i + 1].indexOf(firstWord) + firstWord.length);
          }
        }
      }
    }
  }
  return totalText;
}

void _extractOGData(d.Document document, Map data, String parameter) {
  var titleMetaTag = document.getElementsByTagName("meta").firstWhere(
      (meta) => meta.attributes['property'] == parameter,
      orElse: () =>
          d.Element.html("<div class='xxsdfhsakdhflaskjdfahl'></div>"));
  if (titleMetaTag.classes.isEmpty) {
    data[parameter] = titleMetaTag.attributes['content'];
  }
}

Future<List<String>> getTitleAndDescription(String url) async {
  try {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      return ["Could not fetch website."];
    }
    var document = parse(response.body);
    Map<String, String> data = {};
    _extractOGData(document, data, 'og:title');
    _extractOGData(document, data, 'og:description');
    if (data.keys.contains('og:title') &&
        data.keys.contains('og:description')) {
      return ["${data['og:title']!}: ", data['og:description']!].toList();
    } else {
      if (data.keys.contains('og:title')) {
        return [data['og:title']!, ""].toList();
      }
      if (data.keys.contains('og:description')) {
        return ["", data['og:description']!].toList();
      }
    }
    return ["Website looks good.", ""];
  } catch (e) {
    return ["Could not fetch website."];
  }
}

class InterviewProfile {
  late String expectedSalery;
  late String roleExpectation;
  late String qualification;
  late String firmName;
  late String firmDescription;
  late String jobDescription;

  late String? profileId;

  late DateTime createdAt;

  late Map<String, String> additionalData = {};

  InterviewProfile(
      this.expectedSalery,
      this.roleExpectation,
      this.qualification,
      this.firmName,
      this.firmDescription,
      this.jobDescription) {
    createdAt = DateTime.now();
  }

  static InterviewProfile empty() {
    return InterviewProfile("", "", "", "", "", "");
  }

  void addAdditionalData(String key, String value) {
    additionalData[key] = value;
  }

  void addProfileId(String profileId) {
    this.profileId = profileId;
  }

  bool isEmpty() {
    return ([
      expectedSalery,
      roleExpectation,
      qualification,
      firmName,
      firmDescription,
      jobDescription,
      ...additionalData.values
    ].every((x) => x.isEmpty));
  }

  String longestStringNotNull() {
    Map<int, String> lm = {};
    for (var value in [
      expectedSalery,
      roleExpectation,
      qualification,
      firmName,
      firmDescription,
      jobDescription,
      ...additionalData.values
    ]) {
      lm[value.length] = value;
    }
    int maxLength = lm.keys.toList().reduce(max);
    String preferredValue = lm[maxLength].toString();
    return preferredValue;
  }

  static Future<InterviewProfile> createFromWeb(String givenText) async {
    /// CREATE INTERVIEW PROFILE USING GEMINI AND WEB SCRAPING...
    /// 1. STEP: SCRAPE ALL TEXT OF WEBSITE (done)
    /// 2. STEP: PROMPT AND FEED GEMINI
    /// 3. STEP: ANALYSE GEMINI OUTPUT

    var prompt = await loadPrompt("web_scrape");
    if (prompt.isEmpty) {
      if (kDebugMode) {
        print("WEB SCRAPE PROMPT MISSING");
      }
    }
    FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
    GenerativeModel model =
        vertexAI.generativeModel(model: "gemini-1.5-flash", safetySettings: []);

    GenerateContentResponse content = await model.generateContent([
      Content("user", [
        TextPart(prompt),
        DataPart(
            "text/plain", Uint8List.fromList(utf8.encode(givenText).toList()))
      ])
    ]);
    saveTokens(content);
    var cText = content.text;
    if (cText == null) {
      return InterviewProfile.empty();
    }

    ///File f = File("${(await getApplicationDocumentsDirectory()).path}/x.txt");
    ///f.writeAsBytes(Uint8List.fromList(cText!.codeUnits));
    ///print(f.path);
    if (cText.startsWith("```json") && cText.contains("```", 3)) {
      final onlyJsonString = cText
          .trimRight()
          .substring("```json".length, cText.indexOf("```", 3));
      final jsonData = json.decode(onlyJsonString);
      var expected_salary = "";
      var role_expectation = "";
      var needed_qualification = "";
      var company_name = "";
      var company_description = "";
      var job_description = "";
      if (jsonData.keys.contains("expected_salary")) {
        if (jsonData["expected_salary"] is! String) {
          jsonData["expected_salary"] = jsonData["expected_salary"].toString();
        }
        if (jsonData["expected_salary"] == "null") {
          jsonData["expected_salary"] = "";
        }
        expected_salary = jsonData["expected_salary"];
      }
      if (jsonData.keys.contains("role_expectation")) {
        if (jsonData["role_expectation"] is! String) {
          jsonData["role_expectation"] =
              jsonData["role_expectation"].toString();
        }
        role_expectation = jsonData["role_expectation"];
      }
      if (jsonData.keys.contains("needed_qualification")) {
        if (jsonData["needed_qualification"] is! String) {
          jsonData["needed_qualification"] =
              jsonData["needed_qualification"].toString();
        }
        needed_qualification = jsonData["needed_qualification"];
      }
      if (jsonData.keys.contains("company_name")) {
        if (jsonData["company_name"] is! String) {
          jsonData["company_name"] = jsonData["company_name"].toString();
        }
        company_name = jsonData["company_name"];
      }
      if (jsonData.keys.contains("company_description")) {
        if (jsonData["company_description"] is! String) {
          jsonData["company_description"] =
              jsonData["company_description"].toString();
        }
        company_description = jsonData["company_description"];
      }
      if (jsonData.keys.contains("job_description")) {
        if (jsonData["job_description"] is! String) {
          jsonData["job_description"] = jsonData["job_description"].toString();
        }
        job_description = jsonData["job_description"];
      }
      return InterviewProfile(
          expected_salary,
          role_expectation,
          needed_qualification,
          company_name,
          company_description,
          job_description);
    } else {
      return InterviewProfile("", "", "", "", "", "");
    }
  }

  static Future<InterviewProfile> hallucinateProfile(
      List<Map<String, dynamic>> fulfillData) async {

        print(fulfillData);

    /// Create random profile using gemini....
    /// given: keys
    final initialPrompt = await loadPrompt("hall_base");
    final endingPrompt = await loadPrompt("hall_task");
    if (initialPrompt.isEmpty) {
      if (kDebugMode) {
        print("HALL PROMPT MISSING");
      }
    }
    String infoData = "";
    for (var m in fulfillData) {
      infoData = "${"${infoData + m["k"]}: " + m["description"]}\n";
      //infoData = "${"${infoData + m["k"]}: " + m["description"]}\n";
    }
    final finalPrompt = initialPrompt + infoData + endingPrompt;

    FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
    GenerativeModel model = vertexAI.generativeModel(
      model: "gemini-1.5-flash",
      safetySettings: [], /*generationConfig: GenerationConfig(responseMimeType: "application/json")*/
    );

    GenerateContentResponse content = await model.generateContent([
      Content("user", [
        TextPart(finalPrompt),
      ])
    ]);
    File f = File("${(await getApplicationDocumentsDirectory()).path}/x.txt");
  f.writeAsBytes(Uint8List.fromList(content.text!.codeUnits));
    saveTokens(content);
    var cText = content.text;
    if (cText == null) {
      return InterviewProfile.empty();
    }

    if (cText.startsWith("```json")) {
      if (cText.contains("```", 3)) {
        final jsonString =
            cText.substring("```json".length, cText.indexOf("```", 3));
        var jsonData = json.decode(jsonString);
        while (jsonData is List) {
          jsonData = jsonData[0];
        }
        if (!json.encode(jsonData).startsWith("{")) {
          return InterviewProfile.empty();
        }

        /// check if keys inside json
        Map<String, String> data = {};
        for (var element in fulfillData) {
          if (jsonData.containsKey(element["k"])) {
            data[element["k"]] = jsonData[element["k"]];
          }
        }
        final focusKeys = [
          "expected_salary",
          "role_expectation",
          "needed_qualification",
          "company_name",
          "company_description",
          "job_description"
        ];
        var focusValues = {};
        focusKeys.forEach((key){
          focusValues[key] = "";
        });
        data.forEach((k, v) {
          
            focusValues[k] = v;
          /// data.remove(k);
        });
        
        data.removeWhere((k, v) => focusKeys.contains(k));
        print("mainProfile");
        final InterviewProfile mainProfile = InterviewProfile(
            focusValues["expected_salary"],
            focusValues["role_expectation"],
            focusValues["needed_qualification"],
            focusValues["company_name"],
            focusValues["company_description"],
            focusValues["job_description"]);

        /// add any leftovers
        data.forEach((k, v) {
          mainProfile.addAdditionalData(k, v);
        });
        return mainProfile;
      }
    }

    return InterviewProfile.empty();
  }

  Map<String, dynamic> toJSON() {
    return {
      "expected_salary": expectedSalery,
      "role_expectation": roleExpectation,
      "needed_qualification": qualification,
      "company_name": firmName,
      "company_description": firmDescription,
      "job_description": jobDescription,
      ...additionalData
    };
  }

  Map<String, dynamic> toTextualJSON() {
    return {
      "Salary Expectation": expectedSalery,
      "Role Expectations": roleExpectation,
      "Qualifications": qualification,
      "Company Name": firmName,
      "Company Description": firmDescription,
      "Job Description": jobDescription
    };
  }

  void setCreationDate(DateTime dateTime) {
    createdAt = dateTime;
  }

  factory InterviewProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      return InterviewProfile.empty();
    } else {
      final focusValues = [];
      final focusKeys = [
        "expected_salary",
        "role_expectation",
        "needed_qualification",
        "company_name",
        "company_description",
        "job_description"
      ];
      for (var key in focusKeys) {
        if (data.containsKey(key)) {
          focusValues.add(data[key]);
        } else {
          focusValues.add("");
        }
      }
      final InterviewProfile main = InterviewProfile(
          focusValues[0],
          focusValues[1],
          focusValues[2],
          focusValues[3],
          focusValues[4],
          focusValues[5]);
      if (data.keys.any((key) => !focusKeys.contains(key))) {
        /// there are additional keys
        /// created_at key and uid keys are special
        if (data.containsKey("created_at")) {
          /// here?
          main.setCreationDate(data["created_at"] is Timestamp
              ? data["created_at"].toDate()
              : 0);
        }
        if (data.containsKey("user_ref")) {
          /// no action required, we know it's ours.
        }
        if (data.keys.any(
            (key) => !["created_at", "user_ref", ...focusKeys].contains(key))) {
          /// there is addional data for the interview
          final dataKeys = data.keys
              .where((key) =>
                  !["created_at", "user_ref", ...focusKeys].contains(key))
              .toList();
          for (var key in dataKeys) {
            main.addAdditionalData(key, data[key].toString());
          }
        }
      }
      return main;
    }
  }
  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> mainData = toJSON();
    mainData["created_at"] = Timestamp.fromDate(createdAt);

    /// get current user uid
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      mainData["user_ref"] = user.uid;
    }

    return mainData;
  }
}

class UserAccount {
  final String uid;
  late String resumeId = "";
  late List<String> profileIds = [];
  late List<String> conversationIds = [];
  late DateTime? lastSignIn;

  UserAccount(this.uid, {resumeId, profileIds, conversationIds, lastSignIn}) {
    if (resumeId != null) {
      this.resumeId = resumeId;
    }
    if (profileIds != null) {
      this.profileIds = profileIds;
    }
    if (conversationIds != null) {
      this.conversationIds = conversationIds;
    }
    if (lastSignIn != null) {
      this.lastSignIn = lastSignIn;
    }
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> mainData = {
      "uid": uid,
      "resumeId": resumeId,
      "profileIds": profileIds,
      "conversationIds": conversationIds,
      "lastSignIn": lastSignIn == null
          ? Timestamp.fromDate(DateTime.now())
          : Timestamp.fromDate(lastSignIn!)
    };
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      mainData["uid"] = user.uid;
    }
    return mainData;
  }

  bool isEmpty() {
    return uid.isEmpty;
  }

  static UserAccount empty() {
    return UserAccount("");
  }

  factory UserAccount.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      return UserAccount.empty();
    }

    final UserAccount account = UserAccount(data["uid"]);
    if (data.containsKey("resumeId")) {
      account.resumeId = data["resumeId"];
    }
    if (data.containsKey("profileIds")) {
      account.profileIds = data["profileIds"].cast<String>();
    }
    if (data.containsKey("conversationIds")) {
      account.conversationIds = data["conversationIds"].cast<String>();
    }
    if (data.containsKey("lastSignIn")) {
      account.lastSignIn = data["lastSignIn"] is Timestamp
          ? data["lastSignIn"].toDate()
          : DateTime.now();
    }
    return account;
  }
}

UserAccount? currentUserAccountGlobally;

Future<UserAccount> fetchUserAccount() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// check if signed in...
  FirebaseAuth auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    currentUserAccountGlobally = UserAccount.empty();
    return UserAccount.empty();
  }
  final String uid = auth.currentUser!.uid;

  final userRef = firestore
      .collection("users")
      .withConverter(
          fromFirestore: UserAccount.fromFirestore,
          toFirestore: (UserAccount p, options) => p.toFirestore())
      .doc(uid);
  final response = await userRef.get();
  if (response.exists) {
    /// get user account from ref
    UserAccount? userAccount = response.data();
    if (userAccount == null) {
      if (kDebugMode) {
        print("Error while user fetching");
      }
      currentUserAccountGlobally = UserAccount.empty();
      return UserAccount.empty();
    } else {
      currentUserAccountGlobally = userAccount;
      return userAccount;
    }
  } else {
    /// create new user account from zero
    UserAccount newUserAccount = UserAccount(uid);
    newUserAccount.lastSignIn = DateTime.now();
    userRef.set(newUserAccount);
    currentUserAccountGlobally = newUserAccount;
    return newUserAccount;
  }
}

Future<void> saveUserAccount(UserAccount user) async {
  currentUserAccountGlobally = user;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    currentUserAccountGlobally = UserAccount.empty();
    return;
  }
  final String uid = auth.currentUser!.uid;
  final userRef = firestore
      .collection("users")
      .withConverter(
          fromFirestore: UserAccount.fromFirestore,
          toFirestore: (UserAccount p, options) => p.toFirestore())
      .doc(uid);
  await userRef.set(user);
}

Future<InterviewProfile> createProfileInFirestore(
    InterviewProfile profile) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final docRef = firestore
      .collection("profiles")
      .withConverter(
          fromFirestore: InterviewProfile.fromFirestore,
          toFirestore: (InterviewProfile p, options) => p.toFirestore())
      .doc();
  final profileId = docRef.id;
  profile.addProfileId(profileId);
  await docRef.set(profile);

  /// save id in user data
  /// without using userAccount (but fetching)
  UserAccount currentAccount = await fetchUserAccount();
  currentAccount.profileIds.add(profileId);
  saveUserAccount(currentAccount);
  return profile;
}

Future<InterviewProfile> loadInterviewProfile(String profileId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final docRef = firestore
      .collection("profiles")
      .withConverter(
          fromFirestore: InterviewProfile.fromFirestore,
          toFirestore: (InterviewProfile p, options) => p.toFirestore())
      .doc(profileId);
  InterviewProfile? profile = (await docRef.get()).data();
  if (profile == null) {
    return InterviewProfile.empty();
  }
  profile.addProfileId(profileId);
  return profile;
}

Future<Conversation> createNewConversationInCloud(Conversation initial) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final conv_ref = firestore
      .collection("conv")
      .withConverter(
          fromFirestore: Conversation.fromFirestore,
          toFirestore: (Conversation c, options) => c.toFirestore())
      .doc();

  /// set conv_id
  initial.convId = conv_ref.id;

  /// add to profile
  if (currentUserAccountGlobally != null) {
    currentUserAccountGlobally!.conversationIds.add(conv_ref.id);
  } else {
    await fetchUserAccount();
    currentUserAccountGlobally!.conversationIds.add(conv_ref.id);
  }
  saveUserAccount(currentUserAccountGlobally!);

  await conv_ref.set(initial);
  return initial;
}

Future<List<InterviewProfile>> loadMyProfiles() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  UserAccount acc;
  List<InterviewProfile> profiles = [];
  if (currentUserAccountGlobally == null) {
    FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      currentUserAccountGlobally = UserAccount.empty();
      return [];
    }
    acc = await fetchUserAccount();
  } else {
    acc = currentUserAccountGlobally!;
  }
  for (var id in acc.profileIds) {
    var res = await firestore
        .collection("profiles")
        .withConverter(
            fromFirestore: InterviewProfile.fromFirestore,
            toFirestore: (InterviewProfile c, options) => c.toFirestore())
        .doc(id)
        .get();
    if (res.exists && res.data() != null) {
      print(res.data()!.toFirestore());
      var p = res.data()!;
      p.addProfileId(id);
      profiles.add(p);
    }
  }
  return profiles;
}

Future<Conversation> updateConversation(Conversation c) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  print(c.messages.length);
  print(c.toFirestore());
  await firestore
      .collection("conv")
      .withConverter(
          fromFirestore: Conversation.fromFirestore,
          toFirestore: (Conversation c, options) => c.toFirestore())
      .doc(c.convId)
      .set(c);

  return c;
}

Future<void> deleteProfile(String profileId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  UserAccount acc;
  if (currentUserAccountGlobally == null) {
    FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      currentUserAccountGlobally = UserAccount.empty();
      return;
    }
    acc = await fetchUserAccount();
  } else {
    acc = currentUserAccountGlobally!;
  }
  acc.profileIds.remove(profileId);
  final ref = firestore
      .collection("users")
      .withConverter(
          fromFirestore: UserAccount.fromFirestore,
          toFirestore: (UserAccount p, options) => p.toFirestore())
      .doc(acc.uid);
  await ref.set(acc);

  /// remove ref
  await firestore.collection("profiles").doc(profileId).delete();
}

Future<void> downloadQuestionFileFromStorage(String version) async {
  final ref = FirebaseStorage.instance.ref("/questions/questions100.json");
  File dataFile = File(
      "${(await getApplicationDocumentsDirectory()).path}/questions100_v$version.json");
  dataFile.createSync();
  await ref.writeToFile(dataFile);
}

Future<void> downloadPromptFileFromStorage(String version) async {
  final ref = FirebaseStorage.instance.ref("/questions/all_prompts.json");

  final millis = DateTime.now().millisecondsSinceEpoch;

  File dataFile = File(
      "${(await getApplicationDocumentsDirectory()).path}/prompts_x_${millis}_version_$version.json");
  dataFile.createSync();
  await ref.writeToFile(dataFile);
}

Future<Map<String, dynamic>> getQuestions() async {
  Directory dir = Directory((await getApplicationDocumentsDirectory()).path);
  List<FileSystemEntity> entities = dir.listSync();
  bool exsits = entities
      .any((fse) => fse.uri.pathSegments.last.startsWith("questions100_v"));
  if (!exsits) {
    await checkQuestions();
  }
  FileSystemEntity fse = entities.firstWhere(
      (fse) => fse.uri.pathSegments.last.startsWith("questions100_v"));
  final fileName = fse.uri.pathSegments.last;
  //final version = fileName.substring("questions100_v".length, fileName.length - ".json".length);
  File f = File("${dir.path}/$fileName");
  final jsonData = json.decode(f.readAsStringSync());
  return jsonData;
}

Future<void> checkQuestions() async {
  /// check if file exists
  /// FILE FORMAT-----
  ///
  /// questions100_v + [VERSION] .json
  ///
  ///
  /// -----

  Directory dir = Directory((await getApplicationDocumentsDirectory()).path);
  List<FileSystemEntity> entities = dir.listSync();
  bool exsits = entities
      .any((fse) => fse.uri.pathSegments.last.startsWith("questions100_v"));
  if (exsits) {
    FileSystemEntity fse = entities.firstWhere(
        (fse) => fse.uri.pathSegments.last.startsWith("questions100_v"));
    final fileName = fse.uri.pathSegments.last;
    final version = fileName.substring(
        "questions100_v".length, fileName.length - ".json".length);

    /// load version from firestore

    final data = await FirebaseFirestore.instance
        .collection("versions")
        .doc("data_versions")
        .get();
    if (data.data() != null) {
      final questionVersion = data.data()!["questions"];
      if (questionVersion != version) {
        File(fse.path).deleteSync();
        downloadQuestionFileFromStorage(questionVersion);
      }
    }
  } else {
    final data = await FirebaseFirestore.instance
        .collection("versions")
        .doc("data_versions")
        .get();
    if (data.data() != null) {
      final questionVersion = data.data()!["questions"];
      await downloadQuestionFileFromStorage(questionVersion);
    }
  }
}

const Duration maxCheckAge = Duration(days: 2);
Future<bool> checkNeeded() async {
  Directory dir = Directory((await getApplicationDocumentsDirectory()).path);
  List<FileSystemEntity> entities = dir.listSync();
  bool exsits =
      entities.any((fse) => fse.uri.pathSegments.last.startsWith("prompts_x_"));
  if (exsits) {
    FileSystemEntity fse = entities.firstWhere(
        (fse) => fse.uri.pathSegments.last.startsWith("prompts_x_"));
    final fileName = fse.uri.pathSegments.last;
    final millis = num.tryParse(
        fileName.substring("prompts_x_".length, fileName.indexOf("_version_")));
    if (millis != null) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(millis.toInt());
      final diff = DateTime.now().difference(dt);
      if (diff.inMilliseconds < maxCheckAge.inMilliseconds) {
        return false;
      }
    }
  }
  return true;
}

Future<void> checkPrompts() async {
  /// FILE FORMAT: "prompts_x_" + last_time_checked_in_millis + "_version_" + version + ".json"

  Directory dir = Directory((await getApplicationDocumentsDirectory()).path);
  List<FileSystemEntity> entities = dir.listSync();
  bool exsits =
      entities.any((fse) => fse.uri.pathSegments.last.startsWith("prompts_x_"));
  if (exsits) {
    FileSystemEntity fse = entities.firstWhere(
        (fse) => fse.uri.pathSegments.last.startsWith("prompts_x_"));
    final fileName = fse.uri.pathSegments.last;
    final version = fileName.substring(
        fileName.indexOf("_version_") + "_version_".length,
        fileName.length - ".json".length);

    /// load version from firestore

    final data = await FirebaseFirestore.instance
        .collection("versions")
        .doc("data_versions")
        .get();
    if (data.data() != null) {
      final questionVersion = data.data()!["prompts"];
      if (questionVersion != version) {
        File(fse.path).deleteSync();
        downloadPromptFileFromStorage(questionVersion);
      } else {
        /// update file name with current time
        final millis = DateTime.now().millisecondsSinceEpoch;
        await File(fse.path)
            .rename("${dir.path}/prompts_x_${millis}_version_$version.json");
      }
    }
  } else {
    final data = await FirebaseFirestore.instance
        .collection("versions")
        .doc("data_versions")
        .get();
    if (data.data() != null) {
      final questionVersion = data.data()!["prompts"];
      await downloadPromptFileFromStorage(questionVersion);
    }
  }
}

Future<Map<String, String>> getAllPrompt() async {
  if ((await checkNeeded())) {
    await checkPrompts();
  }
  Directory dir = Directory((await getApplicationDocumentsDirectory()).path);
  List<FileSystemEntity> entities = dir.listSync();
  bool exsits =
      entities.any((fse) => fse.uri.pathSegments.last.startsWith("prompts_x_"));
  if (!exsits) {
    await checkPrompts();
  }
  FileSystemEntity fse = entities
      .firstWhere((fse) => fse.uri.pathSegments.last.startsWith("prompts_x_"));
  final fileName = fse.uri.pathSegments.last;
  File promptFile = File("${dir.path}/$fileName");
  print(promptFile.path);
  final jsonData = json.decode(promptFile.readAsStringSync()) as Map;
  return Map.fromEntries(jsonData.cast<String, String>().entries);
}

Future<String> loadPrompt(String key) async {
  final allPrompts = await getAllPrompt();
  if (allPrompts.containsKey(key)) {
    return allPrompts[key]!;
  } else {
    /// prompt is missing ....
    /// TODO: firebase alert
    await checkPrompts();
    final allPrompts = await getAllPrompt();
    if (allPrompts.containsKey(key)) {
      return allPrompts[key]!;
    } else {
      print("prompt not found!!!!");
      return "";
    }
  }
}

dynamic findValueForKey(Map anyMap, String key) {
  if (anyMap.keys.contains(key)) {
    if (anyMap[key] is String || anyMap[key] is num || anyMap[key] is List) {
      return anyMap[key];
    }
    return findValueForKey(anyMap[key], key);
  } else {
    for (var value in anyMap.values) {
      if (!(value is String || value is num || value is List)) {
        final possibleValue = findValueForKey(value, key);
        if (possibleValue != null) {
          return possibleValue;
        }
      }
    }
  }
  return null;
}

Future<ChatFeedback?> createFeedbackFor2Messages(
    InterviewProfile profile, Message botMessage, Message userMessage) async {
  /// prompting machine
  /// BASE PROMPT: Who are you?
  /// INFO, DATA PART
  /// END PROMPT: What shoudl you do?

  final basePrompt = await loadPrompt("feedback_base");
  final info1Prompt = await loadPrompt("feedback_info_1");
  final info2Prompt = await loadPrompt("feedback_info_2");
  final taskPrompt = await loadPrompt("feedback_task");

  if ([basePrompt, info2Prompt, info1Prompt, taskPrompt]
      .any((x) => x.isEmpty)) {
    if (kDebugMode) {
      print("FEEDBACK PROMPT MISSING");
    }
  }

  final totalPrompt = basePrompt +
      json.encode(profile.toJSON()) +
      info1Prompt +
      botMessage.content +
      info2Prompt +
      userMessage.content.replaceAll("\"", "") +
      taskPrompt;
  FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
  final model = vertexAI.generativeModel(model: "gemini-1.5-flash");

  final response = await model.generateContent([Content.text(totalPrompt)]);
  if (response.text == null) {
    return null;
  } else {
    saveTokens(response);

    /// expect json format...
    if (response.text!.startsWith("```json") &&
        response.text!.contains("```", 3)) {
      /// json content found
      final jsonString = response.text!
          .substring("```json".length, response.text!.indexOf("```", 3));
      final jsonObject = json.decode(jsonString);
      if (jsonObject != null && json.encode(jsonObject).startsWith("{")) {
        var c_rate = findValueForKey(jsonObject, "content_rating");
        var l_rate = findValueForKey(jsonObject, "language_rating");
        l_rate ??= -1;
        c_rate ??= -1;
        if (c_rate is String) {
          c_rate = num.tryParse(c_rate);
          c_rate ??= -1;
        }
        if (l_rate is String) {
          l_rate = num.tryParse(l_rate);
          l_rate ??= -1;
        }

        var c_analysis = findValueForKey(jsonObject, "content_analysis");
        var l_analysis = findValueForKey(jsonObject, "language_analysis");

        c_analysis ??= "";
        l_analysis ??= "";

        var c_adv = findValueForKey(jsonObject, "content_advice");
        var l_adv = findValueForKey(jsonObject, "language_advice");

        c_adv ??= "";
        l_adv ??= "";
        countFeedback();
        ChatFeedback newFeedback = ChatFeedback({
          "msgId": userMessage.messageId,
          "lang_rate": l_rate!,
          "content_rate": c_rate!,
          "lang_adv": l_adv,
          "content_adv": c_adv,
          "lang_problem": l_analysis,
          "content_problem": c_analysis,
          "created_at": Timestamp.now()
        });
        return newFeedback;
      }
    }
  }
  return null;
}

Future<List<Conversation>> loadAllConversations() async {
  print("load All");
  UserAccount ua = await fetchUserAccount();
  List<String> convs = ua.conversationIds;
  List<Conversation> conversations = [];

  /// check if convId exists
  if (convs.isEmpty) {
    return [];
  }

  QuerySnapshot snap = await FirebaseFirestore.instance
      .collection('conv')
      .where(FieldPath.documentId, whereIn: convs)
      .get();
  print(snap);
  for (var snap in snap.docs) {
    if (snap.exists) {
      if (snap.data() != null) {
        Conversation newC = Conversation.fromFirestoreQuery(snap);
        if (!newC.isEmpty()) {
          conversations.add(newC);
        }
      }
    }
  }
  return conversations;
}

Future<File?> systemPdfFile() async {
  if (currentUserAccountGlobally == null) {
    await fetchUserAccount();
  }
  final fileName = "${currentUserAccountGlobally!.uid}_resume.pdf";
  File possibleFile =
      File("${(await getApplicationDocumentsDirectory()).path}/$fileName");
  if (!possibleFile.existsSync()) {
    return null;
  }
  return possibleFile;
}

Future<void> deleletAllData() async {
  UserAccount ua = await fetchUserAccount();
  List<String> convs = ua.conversationIds;
  List<String> profileIds = ua.profileIds;

  for (var m in convs) {
    await FirebaseFirestore.instance.collection('conv').doc(m).delete();
  }
  for (var m in profileIds) {
    await FirebaseFirestore.instance.collection('profiles').doc(m).delete();
  }

  /// also delete local cv and cv in storage
  if (currentUserAccountGlobally == null) {
    await fetchUserAccount();
  }
  final fileName = "${currentUserAccountGlobally!.uid}_resume.pdf";
  File possibleFile =
      File("${(await getApplicationDocumentsDirectory()).path}/$fileName");
  if (possibleFile.existsSync()) {
    possibleFile.deleteSync();
  }
  try {
    final ref = FirebaseStorage.instance.ref("cvs").child(fileName);
    if ((await ref.getDownloadURL()).isNotEmpty) {
      await ref.delete();
    }
  } catch (e) {
    if (kDebugMode) {
      print("nothing uploaded");
    }
  }
}

Future<void> createJSONcv(File f) async {
  final systemPrompt = await loadPrompt("extract_pdf");
  FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
  final model = vertexAI.generativeModel(
      model: "gemini-1.5-flash",
      systemInstruction: Content.system(systemPrompt));
  final content = await model.generateContent([
    Content.multi([
      TextPart("Please analyze the following PDF file:"),
      DataPart("application/pdf", f.readAsBytesSync())
    ])
  ]);
  saveTokens(content);
  final cText = content.text;
  if (cText == null) {
    return;
  }
  if (cText.startsWith("```json") && cText.contains("```", 3)) {
    final onlyJsonString =
        cText.trimRight().substring("```json".length, cText.indexOf("```", 3));
    final jsonObject = json.decode(onlyJsonString);
    if (jsonObject != null && json.encode(jsonObject).startsWith("{")) {
      if (currentUserAccountGlobally == null) {
        await fetchUserAccount();
      }
      final fileName = "${currentUserAccountGlobally!.uid}_resume.json";
      File fx =
          File("${(await getApplicationDocumentsDirectory()).path}/$fileName");
      print(fx.path);
      if (!fx.existsSync()) {
        fx.createSync();
      }
      fx.writeAsStringSync(json.encode(jsonObject));
    }
  }
}

Future<bool> jsonCVThere() async {
  final fileName = "${currentUserAccountGlobally!.uid}_resume.json";
  File fx =
      File("${(await getApplicationDocumentsDirectory()).path}/$fileName");
  return await fx.exists();
}

Future<void> uploadFileToStorage(File f) async {
  if (currentUserAccountGlobally == null) {
    await fetchUserAccount();
  }
  final fileName = "${currentUserAccountGlobally!.uid}_resume.pdf";
  await saveCopy(f, fileName);
  await createJSONcv(f);
  await FirebaseStorage.instance.ref("/cvs/").child(fileName).putFile(f);
}

Future<bool> cvAlreadyUploaded() async {
  if (currentUserAccountGlobally == null) {
    await fetchUserAccount();
  }
  final fileName = "${currentUserAccountGlobally!.uid}_resume.pdf";
  File possibleFile =
      File("${(await getApplicationDocumentsDirectory()).path}/$fileName");
  if (possibleFile.existsSync()) {
    return true;
  }
  return false;
}

Future<void> deletDataAndProfile() async {
  await deleletAllData();
  final usr = FirebaseAuth.instance.currentUser;
  if (usr == null) {
    return;
  }
  try {
    await usr.delete();
  } catch (e) {
    await FirebaseAuth.instance.signOut();
  }
}

Future<void> saveCopy(File f, String fileName) async {
  File newFile =
      File("${(await getApplicationDocumentsDirectory()).path}/$fileName");
  if (!newFile.existsSync()) {
    newFile.createSync();
  }
  newFile.writeAsBytes(f.readAsBytesSync());
}

Future<MainFeedback> createMainFeedback100Questions(
    ChatMessage q, ChatMessage a) async {
  /// with function calling...
  bool cvJSONAvailable = await jsonCVThere();
  final basePrompt = await loadPrompt("f2_base");
  final info1 = await loadPrompt("f2_info1");
  final task = await loadPrompt("f2_task");
  var finalPrompt = "";
  if (cvJSONAvailable) {
    final info2 = await loadPrompt("f2_info2");

    ///load json content
    final fileName = "${currentUserAccountGlobally!.uid}_resume.json";
    File fx =
        File("${(await getApplicationDocumentsDirectory()).path}/$fileName");
    final jsonString = fx.readAsStringSync();
    finalPrompt = basePrompt +
        q.content.replaceAll("\"", "") +
        info1 +
        a.content.replaceAll("\"", "") +
        info2 +
        jsonString +
        task;
  } else {
    finalPrompt = basePrompt +
        q.content.replaceAll("\"", "") +
        info1 +
        a.content.replaceAll("\"", "") +
        task;
  }

  FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
  final model = vertexAI.generativeModel(
      model: "gemini-1.5-flash",
      systemInstruction:
          Content.system("Follow the instructions given by the user."));
  final response = await model.generateContent([Content.text(finalPrompt)]);
  saveTokens(response);
  var cText = response.text;

  if (cText == null) {
    return MainFeedback.empty();
  }
  File f = File("${(await getApplicationDocumentsDirectory()).path}/x.txt");
  f.writeAsBytes(Uint8List.fromList(cText.codeUnits));
  if (cText.startsWith("```json") && cText.contains("```", 3)) {
    final onlyJsonString =
        cText.trimRight().substring("```json".length, cText.indexOf("```", 3));
    final jsonObject = json.decode(onlyJsonString);
    if (jsonObject != null && json.encode(jsonObject).startsWith("{")) {
      /// try to parse data
      var jsonData = {"created_at": Timestamp.now(), "msgId": -1};
      final headers = [
        "content_analysis",
        "language_analysis",
        "other_feedback"
      ];
      for (var head in headers) {
        if (!jsonObject.containsKey(head)) {
          continue;
        }
        final dd = jsonObject[head];
        var prefix = head.substring(0, head.indexOf("_"));
        if (prefix == "language") {
          prefix = "lang";
        }
        if (!(dd is String || dd is num || dd is List)) {
          dd.forEach((k, v) {
            if (k.toString().contains("rating")) {
              jsonData["${prefix}_rate"] = parseIf(v);
            }
            if (k.toString().contains("advice")) {
              jsonData["${prefix}_adv"] = v;
            }
            if (k.toString().contains("analysis")) {
              jsonData["${prefix}_problem"] = v;
            }
          });
        }
        if (jsonObject.containsKey("overview")) {
          jsonData["overview"] = jsonObject["overview"];
        }
      }
      countFeedback();
      MainFeedback newFeedback = MainFeedback(jsonData);
      return newFeedback;
    }
  }
  return MainFeedback.empty();
}

ChatSession createInterroChat() {
  /// final basePrompt = await loadPrompt("interro_base");
  FirebaseVertexAI vertexAI = FirebaseVertexAI.instance;
  final model = vertexAI.generativeModel(model: "gemini-1.5-flash");
  return model.startChat();
}

Future<List> loadQuestions(ChatSession chat, File pdf, bool isFirst) async {
  GenerateContentResponse msg;
  if (isFirst) {
    final basePrompt = await loadPrompt("interro_base");
    msg = await chat.sendMessage(Content.multi([
      TextPart(basePrompt),
      DataPart("application/pdf", pdf.readAsBytesSync())
    ]));
  } else {
    final nextPrompt = await loadPrompt("interro_next");
    msg = await chat.sendMessage(Content.text(nextPrompt));
  }
  saveTokens(msg);
  final cText = msg.text;
  if (cText == null) {
    return [];
  }
  if (cText.startsWith("```json") && cText.contains("```", 3)) {
    final onlyJsonString =
        cText.trimRight().substring("```json".length, cText.indexOf("```", 3));
    final jsonObject = json.decode(onlyJsonString);
    if (jsonObject != null && json.encode(jsonObject).startsWith("[")) {
      if (jsonObject[0] is String) {
        return jsonObject;
      } else {
        return [];
      }
    }
  }
  return [];
}
