import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:mirror_view/components.dart';
import 'package:mirror_view/functions.dart';

import 'simulate_interview.dart';


class Interro extends StatefulWidget {
  const Interro({super.key});

  @override
  State<Interro> createState() => _InterroState();
}

class ChatTopBarInterro extends StatelessWidget {
  final Function leaveChat;
  final Function liveInfo;
  final Function selectInput;

  final bool isOnline;
  final bool isVoice;

  final String title;

  const ChatTopBarInterro(
      {super.key,
      required this.leaveChat,
      required this.liveInfo,
      required this.isOnline,
      required this.selectInput,
      required this.isVoice,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Flex(direction: Axis.vertical, children: [
      Container(
        color: Colors.white,
        height: 48.0,
        width: MediaQuery.of(context).size.width,
      ),
      SizedBox(
          height: 95.0,
          child: Stack(children: [
            Container(
                padding: const EdgeInsets.only(
                    top: 13.0, left: 16.0, right: 16.0, bottom: 24.0),
                decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade700, width: 1.0)),
                  color: Colors.white,
                ),
                child: Flex(direction: Axis.horizontal, children: [
                  GestureDetector(
                      onTap: () {
                        /// Leave
                        leaveChat();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          color: Colors.grey.shade300,
                        ),
                        height: 40.0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 10.0),
                        child: Center(
                            child: Flex(direction: Axis.horizontal, children: [
                          Icon(Icons.close, color: Colors.grey.shade700),
                          const HorizontalFlexSpacer(width: 4.0),
                          Text(
                            "Leave",
                            style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold),
                          ),
                        ])),
                      )),
                  const Spacer(),
                  TypeWriter(
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500),
                    duration: const Duration(seconds: 1),
                    text: title,
                  ),
                  const Spacer(),
                  GestureDetector(
                      onTap: () {
                        /// Leave
                        liveInfo();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          color: Colors.grey.shade300,
                        ),
                        height: 40.0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 10.0),
                        child: Center(
                            child: Flex(
                          direction: Axis.horizontal,
                          children: [
                            Container(
                              child: isOnline
                                  ? Container(
                                      decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [
                                                Color.fromRGBO(
                                                    113, 80, 238, 1.0),
                                                Color.fromRGBO(
                                                    46, 205, 240, 1.0)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              stops: [-0.2, 1.2]),
                                          borderRadius:
                                              BorderRadius.circular(12.0)),
                                      height: 12.0,
                                      width: 12.0,
                                    )
                                  : Container(
                                      width: 12.0,
                                      height: 12.0,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          color: Colors.grey.shade700),
                                    ),
                            ),
                            const HorizontalFlexSpacer(width: 12.0),
                            Text(
                              isOnline ? "Live" : "Ready",
                              style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.grey.shade700,
                                  fontWeight: isOnline
                                      ? FontWeight.w600
                                      : FontWeight.normal),
                            )
                          ],
                        )),
                      ))
                ])),
            Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Center(
                    child: Container(
                  width: 170.0,
                  height: 35,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(24.0),
                      color: Colors.white),
                  child: Stack(
                    children: [
                      SizedBox(
                          width: 180.0,
                          child: Flex(
                            direction: Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  selectInput("Voice");
                                },
                                child: Container(
                                    width: 84.0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0),
                                    child: const Center(
                                        child: Text(
                                      "Voice",
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey),
                                    ))),
                              ),
                              GestureDetector(
                                onTap: () {
                                  selectInput("Text");
                                },
                                child: Container(
                                    width: 84.0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0),
                                    child: const Center(
                                        child: Text(
                                      "Text",
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey),
                                    ))),
                              )
                            ],
                          )),
                      AnimatedPositioned(
                        curve: Curves.easeIn,
                        duration: const Duration(milliseconds: 300),
                        top: 0.0,
                        bottom: 0.0,
                        left: isVoice ? 0.0 : 70.0,
                        right: isVoice ? 70.0 : 0.0,
                        child: Container(
                            width: 100.0,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [
                                      Color.fromRGBO(113, 80, 238, 1.0),
                                      Color.fromRGBO(46, 205, 240, 1.0)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    stops: [-0.2, 1.2]),
                                borderRadius: BorderRadius.circular(24.0)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 16.0),
                            child: Center(
                                child: Text(
                              isVoice ? "Voice" : "Text",
                              style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ))),
                      )
                    ],
                  ),
                )))
          ]))
    ]);
  }
}

class _InterroState extends State<Interro> {
  List<ChatMessage> messages = [];
  List<ChatFeedback> feedbacks = [];

  List<Widget> buildChatMessages() {
    List<Widget> elements = [];
    elements.add(const SizedBox(
      height: 20.0,
    ));
    print(messages);
    for (var msg in messages) {
      elements.add(MessageView(
          chatMessage: msg,
          currentPlayer: -1,
          requestCurrentPlayer: () {},
          getPrevious: () {
            final index = msg.messageId;
            return messages[index - 1];
          },
          requestFeedback: (ChatMessage msg) {
            print("feedback");

            /// load feedback
            /// get above messages
            final index = msg.messageId;
            if (index > 0) {
              final prevMessage = messages[index - 1];
              if (prevMessage.role == Role.bot) {
                try {
                  createMainFeedback100Questions(prevMessage, msg).then((m) {
                    m.messageId = msg.messageId;
                    setState(() {
                      feedbacks.add(m);
                    });
                  });
                } catch (e) {
                  throw e;
                }

                /*final profile = currentConvo!.realProfile;

            if(!profile!.isEmpty()) {
              createFeedbackFor2Messages(profile!, prevMessage, msg).then((ChatFeedback? feed){
                if(feed != null && currentConvo != null) {
                  setState(() {
                    currentConvo!.feedbacks.add(feed);
                  });
                  updateConversation(currentConvo!);
                }
              });
            }else{
              print("profile is empty");
            }
          }*/
              }
            }
          },
          givenFeedback: feedbacks.firstWhere(
              (f) => f.messageId == msg.messageId,
              orElse: () => ChatFeedback.empty())));
      if (messages.last.messageId != msg.messageId) {
        elements.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 12.0),
          child: const Center(
              child: const Icon(Icons.south, color: Colors.black, size: 28)),
        ));
      }
    }
    elements.add(const SizedBox(
      height: 100.0,
    ));
    return elements;
  }

  bool pdfAvailable = false;
  bool isVoice = true;

  File? pdfFile;
  List<String> questions = [];

  @override
  void initState() {
    super.initState();
    // check pdf
    /// load pdf data
    systemPdfFile().then((f) {
      setState(() {
        pdfFile = f;
        if (pdfFile != null) {
          pdfAvailable = true;
        }
      });
      if (pdfFile == null) {
        if (context.mounted) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: ((v) {
                return PdfDialog(
                    pdfFile: pdfFile,
                    updateFile: (f) {
                      setState(() {
                        pdfFile = f;
                      });
                    });
              }));
        }
      } else {
        startSession();
      }
    });
  }

  ChatSession? session;
  void startSession() async {
    session = createInterroChat();
    List newQ = await loadQuestions(session!, pdfFile!, true);

    setState(() {
      questions.addAll(newQ.map((x) => x.toString()));
    });
    nextQuestion();
  }

  int currentQuestion = 0;
  void nextQuestion() {
    print("nextQuestion");
    int nextQuestion = currentQuestion + 1;
    if (questions.length <= nextQuestion) {
      setState(() {
        currentQuestion = nextQuestion;
      });
      return;
    }
    ChatMessage msg = ChatMessage({
      "role": "bot",
      "content": questions[nextQuestion],
      "created_at": Timestamp.now()
    }, messages.length);
    msg.loadingState = 2;
    setState(() {
      messages.add(msg);
      currentQuestion = nextQuestion;
    });
  }

  void sendAnswer(String text) {
    ChatMessage msg = ChatMessage(
        {"role": "user", "content": text, "created_at": Timestamp.now()},
        messages.length);
    msg.loadingState = 2;
    setState(() {
      messages.add(msg);
    });
    nextQuestion();
  }

  void loadMore() async {
    List newQ = await loadQuestions(session!, pdfFile!, false);

    /// bool isDone = questions.length == currentQuestion;
    setState(() {
      questions.addAll(newQ.map((x) => x.toString()));
    });
    nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(children: [
              Positioned(
                  top: 130,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.bottom -
                      150 -
                      MediaQuery.of(context).padding.top,
                  child: Flex(direction: Axis.vertical, children: [
                    Container(
                        height: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.bottom -
                            150 -
                            MediaQuery.of(context).padding.top,
                        child: SingleChildScrollView(
                            child: Flex(
                                direction: Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: buildChatMessages()))),
                  ])),
              ChatTopBarInterro(
                  leaveChat: () {
                    Navigator.pop(context);
                  },
                  liveInfo: () {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: ((v) {
                          return PdfDialog(
                              pdfFile: pdfFile,
                              updateFile: (f) {
                                setState(() {
                                  pdfFile = f;
                                });
                              });
                        }));

                    /// open pdf viewer
                  },
                  isOnline: pdfAvailable,
                  selectInput: (x) {
                    setState(() {
                      isVoice = x == "Voice";
                    });
                  },
                  isVoice: isVoice,
                  title: "Resumé Questions"),
              Positioned(
                left: 0,
                right: 0,
                bottom: 64,
                height: MediaQuery.of(context).size.height / 12 * 7,
                child: Stack(children: [
                  Positioned(
                    bottom: 65,
                    left: 0,
                    right: 0,
                    child: Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24.0),
                                  color: Colors.grey.shade300),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 7.0, horizontal: 16.0),
                                child: Text(
                                    currentQuestion >= questions.length - 1
                                        ? "Load more?"
                                        : "Skip question",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16)),
                              )),
                          onTap: () {
                            if (currentQuestion >= questions.length - 1) {
                              loadMore();
                              return;
                            }
                            nextQuestion();
                          },
                        )
                      ],
                    ),
                  ),
                  GeneralInputBar(
                    isVoice: isVoice,
                    sendText: (text) {
                      if (currentQuestion > questions.length - 1) {
                        return;
                      }
                      sendAnswer(text);
                    },
                    sendAudio: (data) {
                      if (currentQuestion > questions.length - 1) {
                        return;
                      }
                      sendAnswer(data);
                    },
                  )
                ]),
              ),
            ])));
  }
}

class PdfDialog extends StatefulWidget {
  final File? pdfFile;
  final Function updateFile;

  const PdfDialog({super.key, required this.pdfFile, required this.updateFile});

  @override
  State<PdfDialog> createState() => _PdfDialogState();
}

class _PdfDialogState extends State<PdfDialog> {
  dynamic pages;
  bool isReady = false;

  int dStatus = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Stack(children: [
        AnimatedContainer(
            duration: const Duration(milliseconds: 333),
            height: widget.pdfFile == null ? 180 : 550,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
            child: Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flex(
                  direction: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your CV",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.pdfFile == null
                          ? "You do not have uploaded any PDF file."
                          : "You have uploaded the following file:",
                      style:
                          const TextStyle(color: Colors.black, fontSize: 14.0),
                    ),
                  ],
                ),
                widget.pdfFile == null
                    ? Container(
                        margin: const EdgeInsets.only(top: 32.0),
                        child: GestureDetector(
                            onTap: () async {
                              if (dStatus == 1) {
                                return;
                              }
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                      allowMultiple: false,
                                      type: FileType.custom,
                                      allowedExtensions: ["pdf"]);

                              if (result != null) {
                                File file = File(result.files.single.path!);
                                setState(() {
                                  dStatus = 1;
                                });
                                uploadFileToStorage(file).then((x) {
                                  setState(() {
                                    dStatus = 2;
                                  });
                                  widget.updateFile(file);
                                }).catchError((err) {
                                  print(err);
                                  setState(() {
                                    dStatus = 3;
                                  });
                                });
                              } else {}
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 1.0),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6.0, horizontal: 29.0),
                              child: Center(
                                  child: Text(
                                dStatus == 0
                                    ? "Upload your resumé"
                                    : (dStatus == 1
                                        ? "Uploading..."
                                        : (dStatus == 2
                                            ? ("File was uploaded")
                                            : (dStatus == -1
                                                ? ""
                                                : "Upload failed. Try again."))),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              )),
                            )),
                      )
                    : Container(
                        margin: const EdgeInsets.only(top: 12.0),
                        height: 360,
                        width: 180,
                        child: PDFView(
                          filePath: widget.pdfFile!.path,
                          enableSwipe: false,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: false,
                          pageSnap: false,
                          onRender: (_pages) {
                            setState(() {
                              pages = _pages;
                              isReady = true;
                            });
                          },
                          onError: (error) {
                            print(error.toString());
                          },
                        ),
                      ),
                widget.pdfFile == null
                    ? Container()
                    : GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: EdgeInsets.only(top: 24),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.0),
                              color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(
                              vertical: 6.0, horizontal: 32.0),
                          child: Center(
                              child: Text(
                            "Cancel",
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 16),
                          )),
                        ))
              ],
            )),
        Positioned(
            top: 12.0,
            right: 12.0,
            child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Icon(Icons.close, color: Colors.black)))
      ]),
    );
  }
}
