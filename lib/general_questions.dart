import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mirror_view/functions.dart';

import 'components.dart';
import 'simulate_interview.dart';

class ChatTopBar2 extends StatelessWidget {
  final Function leaveChat;
  final Function liveInfo;
  final Function selectInput;

  final bool isOnline;
  final bool isVoice;

  final String title;

  final bool inSelection;

  final int selected;

  const ChatTopBar2(
      {super.key,
      required this.leaveChat,
      required this.liveInfo,
      required this.isOnline,
      required this.selectInput,
      required this.isVoice,
      required this.selected,
      required this.inSelection,
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
                child: inSelection
                    ? GestureDetector(
                        onTap: () {},
                        child: Container(
                            child: Center(
                                child: Container(
                                    width: 150.0,
                                    height: 35,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade700),
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                        color: Colors.white),
                                    child: Center(
                                      child: Text(
                                        "$selected selected",
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    )))))
                    : Center(
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      borderRadius:
                                          BorderRadius.circular(24.0)),
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

class GeneralQuestionsPage extends StatefulWidget {
  const GeneralQuestionsPage({super.key});

  @override
  State<GeneralQuestionsPage> createState() => _GeneralQuestionsPageState();
}

class _GeneralQuestionsPageState extends State<GeneralQuestionsPage> {
  int loadState = 0;
  bool isOnline = false;
  bool isVoice = true;

  bool inSelection = true;
  List<List> selectedQuestionsWithCategory = [];

  @override
  void initState() {
    super.initState();

    checkQuestions().then((x) {
      loadState = 1;
    }).catchError((y) {
      setState(() {
        loadState = 2;
      });
    });
  }

  List<Widget> getQuestionListUI(Map<int, String> data, String cat, Color c) {
    List<Widget> elements = [];
    data.forEach((k, v) {
      bool isSelected = selectedQuestionsWithCategory.any((x) => x[1] == v);

      elements.add(GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedQuestionsWithCategory.removeWhere((x) => x[1] == v);
            } else {
              selectedQuestionsWithCategory.add([cat, v, c]);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Flex(
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "#$k",
                style:
                    TextStyle(color: isSelected ? Colors.black : Colors.grey),
              ),
              const HorizontalFlexSpacer(width: 12.0),
              SizedBox(
                width: 270,
                child: Text(
                  v,
                  style: TextStyle(
                      color: Colors.black,
                      decoration: isSelected
                          ? TextDecoration.underline
                          : TextDecoration.none),
                  maxLines: 2,
                ),
              )
            ],
          ),
        ),
      ));
    });
    return elements;
  }

  List<Color> colors = [
    const Color(0xFF00FFFF), // Cyan
    const Color(0xFF40E0D0), // Turquoise
    const Color(0xFF48D1CC), // Medium Turquoise
    const Color(0xFF00BFFF), // Deep Sky Blue
    const Color(0xFF1E90FF), // Dodger Blue
    const Color(0xFF4169E1), // Royal Blue
    const Color(0xFF4682B4), // Steel Blue
    const Color(0xFF5F9EA0), // Cadet Blue
    const Color(0xFF6A5ACD), // Slate Blue
    const Color(0xFF8A2BE2) // Blue Violet
  ];

  List<Widget> getQuestionsUI(Map<String, dynamic> data) {
    List<Widget> list = [];
    int totalIndex = 0;
    data.forEach((k, v) {
      Map<int, String> data2 = {};
      for (var vv in v) {
        totalIndex += 1;
        data2[totalIndex] = vv;
      }
      list.add(Container(
        margin: const EdgeInsets.only(bottom: 24.0),
        child: Stack(
          children: [
            Positioned(
              top: 0.0,
              left: 5.0,
              right: 5.0,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colors[(totalIndex ~/ data.keys.length) - 1],
                    border: Border.all(color: Colors.black, width: 1.0)),
                height: 100.0,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 5.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1.0)),
              child: Flex(
                direction: Axis.vertical,
                children: [
                  GestureDetector(
                      onTap: () {
                        if (selectedQuestionsWithCategory
                                .where((x) => x[0] == k)
                                .length ==
                            v.length) {
                          /// all selected
                          setState(() {
                            selectedQuestionsWithCategory
                                .removeWhere((x) => x[0] == k);
                          });
                        } else {
                          setState(() {
                            selectedQuestionsWithCategory
                                .removeWhere((x) => x[0] == k);
                            v.map((x) => [k, x]).toList().forEach((x) {});
                            v.forEach((vv) {
                              selectedQuestionsWithCategory.add([
                                k.toString(),
                                vv.toString(),
                                colors[((totalIndex) ~/ data.keys.length) - 1]
                              ]);
                            });
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0)),
                            color: Colors.grey.shade200,
                            border: const Border(
                                bottom: BorderSide(
                                    color: Colors.black, width: 1.0))),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 18.0),
                        child: Flex(
                          direction: Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 300,
                                child: Text(k,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold))),
                            const Text(
                              "Click on question to select. Tap here to select category",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13.0),
                            )
                          ],
                        ),
                      )),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12.0),
                            bottomRight: Radius.circular(12.0)),
                        color: colors[((totalIndex) ~/ data.keys.length) - 1]
                            .withAlpha(50)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Flex(
                        direction: Axis.vertical,
                        children: getQuestionListUI(data2, k,
                            colors[((totalIndex) ~/ data.keys.length) - 1])),
                  )
                ],
              ),
            ),
          ],
        ),
      ));
    });
    return list;
  }

  List<ChatMessage> messages = [];
  List<ChatFeedback> feedbacks = [];

  int currentQuestion = -1;

  void nextQuestion() {
    print("nextQuestion");
    int nextQuestion = currentQuestion + 1;
    if (selectedQuestionsWithCategory.length <= nextQuestion) {
      setState(() {
        currentQuestion = nextQuestion;
      });
      return;
    }
    ChatMessage msg = ChatMessage({
      "role": "bot",
      "content": selectedQuestionsWithCategory[nextQuestion][1],
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

  List<Widget> buildChatMessages() {
    List<Widget> elements = [];
    elements.add(const SizedBox(
      height: 20.0,
    ));
    print(messages);
    for (var msg in messages) {
      elements.add(MessageView(
          eData: msg.role == Role.bot
              ? {
                  "name": selectedQuestionsWithCategory
                      .firstWhere((x) => x[1] == msg.content)[0],
                  "color": selectedQuestionsWithCategory
                      .firstWhere((x) => x[1] == msg.content)[2]
                }
              : null,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(children: [
              inSelection
                  ? Positioned(
                      top: 130,
                      left: 0,
                      right: 0,
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          79,
                      child: Container(
                          height: MediaQuery.of(context).size.height -
                              MediaQuery.of(context).padding.top -
                              MediaQuery.of(context).padding.bottom -
                              79,
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: FutureBuilder(
                              future: getQuestions(),
                              builder: ((cx, fu) {
                                if (fu.hasError) {
                                  print(fu.error);
                                  return const Flex(
                                    direction: Axis.vertical,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Something went wrong.",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                      )
                                    ],
                                  );
                                }
                                if (fu.hasData) {
                                  return SingleChildScrollView(
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                          top: 24.0, bottom: 10.0),
                                      child: Flex(
                                        direction: Axis.vertical,
                                        children: getQuestionsUI(fu.data!),
                                      ),
                                    ),
                                  );
                                } else {
                                  return const Flex(
                                    direction: Axis.vertical,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Loading questions...",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                      )
                                    ],
                                  );
                                }
                              }))),
                    )
                  : Positioned(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: buildChatMessages()))),
                      ])),
              inSelection
                  ? Container()
                  : Positioned(
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
                                        borderRadius:
                                            BorderRadius.circular(24.0),
                                        color: Colors.grey.shade300),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 7.0, horizontal: 16.0),
                                      child: Text(
                                          currentQuestion >=
                                                  selectedQuestionsWithCategory
                                                          .length -
                                                      1
                                              ? "Last question"
                                              : "Skip question",
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16)),
                                    )),
                                onTap: () {
                                  if (currentQuestion >=
                                      selectedQuestionsWithCategory.length) {
                                    Navigator.pop(context);
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
                            if (currentQuestion >
                                selectedQuestionsWithCategory.length) {
                              return;
                            }
                            sendAnswer(text);
                            // nextQuestion();
                          },
                          sendAudio: (data) {
                            if (currentQuestion >
                                selectedQuestionsWithCategory.length) {
                              return;
                            }
                            sendAnswer(data);
                            // nextQuestion();
                          },
                        )
                      ]),
                    ),
              ChatTopBar2(
                leaveChat: () {
                  Navigator.of(context).pop();
                },
                selected: selectedQuestionsWithCategory.length,
                inSelection: inSelection,
                liveInfo: () {},
                isOnline: isOnline,
                selectInput: (input) {
                  setState(() {
                    isVoice = input == "Voice";
                  });
                },
                isVoice: isVoice,
                title: inSelection
                    ? "100 Questions"
                    : ("${selectedQuestionsWithCategory.length} Questions"),
              ),
              inSelection
                  ? Positioned(
                      bottom: 84.0,
                      right: 12.0,
                      child: GestureDetector(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 18.0),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.shade700, width: 1.0),
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    offset: const Offset(0, 2),
                                    blurRadius: 5.0,
                                    spreadRadius: 10.0)
                              ]),
                          child: const Flex(
                            direction: Axis.horizontal,
                            children: [
                              Text(
                                "Answer questions",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              HorizontalFlexSpacer(width: 4.0),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.black,
                                size: 16,
                              )
                            ],
                          ),
                        ),
                        onTap: () {
                          if (selectedQuestionsWithCategory.isEmpty) {
                            return;
                          }
                          setState(() {
                            inSelection = false;
                          });

                          nextQuestion();
                        },
                      ),
                    )
                  : Container()
            ])));
  }
}
