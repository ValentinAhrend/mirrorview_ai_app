import 'dart:convert';
import 'dart:io';

import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mirror_view/components.dart';
import 'package:mirror_view/dialogs.dart';
import 'package:mirror_view/feedbacks.dart';
import 'package:mirror_view/functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pcmtowave/pcmtowave.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

/// *
/// Data Structure...
/// Save Conversations with AI in Cloud Firestore
/// ----
/// One document for direct conversation json
/// One document for response analysis
/// ----
/// 
/// Realtime Database for Total Data Collection
/// ----
/// Total Data Variables (Conv, Words, Minutes Spoken)
/// Current App Version
/// Current Prompt Version
/// ----
/// 
/// Google Cloud Functions for safe interface:
/// (A) -> Conv Interaction
/// - Send audio to google cloud function (with conv_id)
/// - generate analysis (json) and next response (mp3 and text)
/// - register data in firebase
/// 
/// (B) -> Conv Start
/// - start new conversation with params
/// - generate new conv_id
/// - generate intro (mp3 and text)
/// 
/// (C) -> get all conversations
/// 
/// 


class CreateProfileDialog extends StatefulWidget {
  final Function setProfile;

  const CreateProfileDialog({super.key, required this.setProfile});

  @override
  State<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<CreateProfileDialog> {
  TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    editingController.addListener(() {
      final text = editingController.text;
      //print(text);
      Future.delayed(const Duration(milliseconds: 300)).then((r) {
        if (text != editingController.text) {
          return;
        }

        setState(() {
          errorText = "";
          validText = "";
        });

        /// getTitleAndDescription
        if (Uri.tryParse(editingController.text)?.hasAbsolutePath ?? false) {
          getTitleAndDescription(editingController.text).then((ls) {
            if (ls.length == 1) {
              setState(() {
                errorText = ls[0];
              });
            } else {
              setState(() {
                validText = ls.join("");
              });
            }
          });
        } else {
          setState(() {
            errorText = "This does not look like a website.";
          });
        }
      });
    });
  }

  @override
  void dispose() {
    editingController.dispose();
    setState(() {
      errorText = "";
      validText = "";
    });
    super.dispose();
  }

  /// 0 = overview
  /// 1 = create new
  /// 2 = use exsiting
  int currenState = 0;
  String errorText = "";
  String validText = "";
  int dataState = 0;

  int numberOfProfs = 0;

  InterviewProfile? profile;
  List<InterviewProfile>? psf;

  List<Widget> profieWidgets(List<InterviewProfile> ps) {
    if (psf != null) {
      ps = psf!;
    }
    List<Widget> elements = [];
    for (var element in ps) {
      //print(element.toJSON());
      elements.add(GestureDetector(
          onTap: () {
            setState(() {
              profile = element;
            });
            finishSetup();
          },
          child: SizedBox(
            height: 155,
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10.0, bottom: 16.0),
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200),
                  child: Flex(
                    direction: Axis.vertical,
                    children: [
                      Flex(
                        direction: Axis.horizontal,
                        children: [
                          const Spacer(),
                          Text(
                            "Interview at ${element.firmName}",
                            style: TextStyle(
                                color: Colors.grey.shade800, fontSize: 14.0),
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ].reversed.toList(),
                      ),
                      SizedBox(
                          height: 80,
                          child: Text(
                            (element.jobDescription.isEmpty
                                ? (element.roleExpectation.isEmpty
                                    ? (element.longestStringNotNull())
                                    : element.roleExpectation)
                                : element.jobDescription),
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 17.0,
                                fontWeight: FontWeight.w500,
                                overflow: TextOverflow.ellipsis),
                            maxLines: 3,
                          )),
                      Flex(
                        direction: Axis.horizontal,
                        children: [
                          const Spacer(),
                          Text(
                            "Created at ${element.createdAt.day}.${element.createdAt.month}.${element.createdAt.year}",
                            style: const TextStyle(
                                color: Colors.black, fontSize: 13.0),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                Positioned(
                    top: 0,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (element.profileId != null) {
                          deleteProfile(element.profileId!);
                        }
                        setState(() {
                          if (psf != null) {
                            psf!.removeWhere(
                                (x) => x.profileId == element.profileId);
                          }
                        });

                        /// reload all
                      },
                      child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1.0),
                            borderRadius: BorderRadius.circular(4.0),
                            color: Colors.grey.shade200,
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 2.0, horizontal: 4.0),
                          child: const Center(
                              child: Flex(
                            direction: Axis.horizontal,
                            children: [
                              Icon(Icons.close, size: 16.0),
                              HorizontalFlexSpacer(width: 4.0),
                              Text("Delete",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 12.0))
                            ],
                          ))),
                    ))
              ],
            ),
          )));

      /// elements.add(elements.last);
    }
    return elements;
  }

  double animatedHeightBasedOnProfs() {
    double x = 400 + numberOfProfs * 80;
    if (x > 750) {
      return 750;
    }
    return x;
  }

  void finishSetup() async {
    /// create a convo based on the profile
    widget.setProfile(profile);
    await Future.delayed(Duration(milliseconds: 500));
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Stack(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 333),
        height: currenState == 2 ? animatedHeightBasedOnProfs() : 400,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0), color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
        child: Flex(
          direction: Axis.vertical,
          children: [
            Flex(
              direction: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  currenState == 2 ? "Select " : "Create ",
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 23.0,
                      fontWeight: FontWeight.w600),
                ),
                GradientText("Interview Profile",
                    style: const TextStyle(
                        fontSize: 23.0, fontWeight: FontWeight.w600),
                    gradient: LinearGradient(colors: [
                      Colors.blue.shade400,
                      const Color.fromARGB(255, 152, 30, 233),
                    ]))
              ],
            ),
            const Text("Simulate an interview using real-time data.",
                style: TextStyle(color: Colors.black, fontSize: 16)),
            AnimatedContainer(
                duration: const Duration(milliseconds: 333),
                height: currenState == 2
                    ? animatedHeightBasedOnProfs() - 115
                    : 285.0,
                child: Stack(children: [
                  AnimatedOpacity(
                      duration: const Duration(milliseconds: 333),
                      opacity: currenState == 0 ? 1.0 : 0.0,
                      child: Flex(
                        direction: Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const FlexSpacer(height: 50.0),
                          GradientButton(
                            title: "New Custom Profile",
                            onClick: () {
                              setState(() {
                                currenState = 1;
                              });
                            },
                            gradient: const LinearGradient(
                                colors: [
                                  Color.fromRGBO(113, 80, 238, 1.0),
                                  Color.fromRGBO(46, 205, 240, 1.0)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: [-0.2, 1.2]),
                          ),
                          const FlexSpacer(height: 8.0),
                          GestureDetector(
                              onTap: () {
                                setState(() {
                                  currenState = 2;
                                  numberOfProfs = 0;
                                });
                              },
                              child: Container(
                                  width: 160.0,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24.0),
                                      color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5.0, horizontal: 12.0),
                                  child: const Center(
                                      child: const Text("Use exsisting one")))),
                          const FlexSpacer(height: 40.0),
                          const Divider(),
                          Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: const Text(
                                "In the process of creating or using interview profiles real-time data is used to gather information about your perspective. This app does not hold any liabilty for any textual resource or personal data fetched from input in the process of optimizing your experience.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11.0,
                                ),
                                textAlign: TextAlign.center,
                              ))
                        ].where((x) => currenState == 0).toList(),
                      )),
                  AnimatedOpacity(
                      duration: const Duration(milliseconds: 333),
                      opacity: currenState == 1 ? 1.0 : 0.0,
                      child: Flex(
                          direction: Axis.vertical,
                          children: [
                            const FlexSpacer(height: 20.0),
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  color: Colors.grey.shade200),
                              width: 320.0,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 18.0),
                              child: Flex(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                direction: Axis.vertical,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0, horizontal: 8.0),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade400,
                                            width: 1.0),
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(8.0)),
                                    height: 46.0,
                                    child: TextField(
                                        keyboardType: TextInputType.url,
                                        maxLines: 1,
                                        controller: editingController,
                                        decoration: InputDecoration(
                                            suffixIcon: GestureDetector(
                                                onTap: () async {
                                                  /// open current data
                                                  setState(() {
                                                    errorText = "";
                                                  });
                                                  final Uri url = Uri.parse(
                                                      editingController.text);
                                                  try {
                                                    if (!await launchUrl(url)) {
                                                      setState(() {
                                                        errorText =
                                                            "URL could not be launched.";
                                                      });
                                                    }
                                                  } catch (e) {
                                                    setState(() {
                                                      errorText =
                                                          "URL could not be launched.";
                                                    });
                                                  }
                                                },
                                                child: Icon(Icons.open_in_new,
                                                    color:
                                                        Colors.grey.shade700)),
                                            border: InputBorder.none,
                                            hintText: "https://my.job.com",
                                            hintStyle: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 17.0)),
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 17.0)),
                                  ),
                                  FlexSpacer(
                                      height:
                                          errorText.isEmpty && validText.isEmpty
                                              ? 0
                                              : 4),
                                  Flex(
                                      direction: Axis.horizontal,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      clipBehavior: Clip.hardEdge,
                                      children: [
                                        SizedBox(
                                            width: 280,
                                            child: Text(
                                              errorText.isEmpty
                                                  ? validText
                                                  : errorText,
                                              style: TextStyle(
                                                  color: errorText.isEmpty
                                                      ? Colors.black
                                                      : Colors.red,
                                                  fontSize: 14.0),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                            )),
                                      ]
                                          .where((x) =>
                                              validText.isNotEmpty ||
                                              errorText.isNotEmpty)
                                          .toList()),
                                  const FlexSpacer(height: 4),
                                  const Text(
                                    "Enter a link to the job, you are applying to. The site should include information about the specific position. If there is no such webpage, enter the data manually.",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14.0),
                                    maxLines: 6,
                                  )
                                ],
                              ),
                            ),
                            FlexSpacer(
                                height:
                                    validText.isNotEmpty || errorText.isNotEmpty
                                        ? 14
                                        : 36),
                            Container(
                                child: Flex(
                              direction: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                    onTap: () {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) async {
                                        showDialog(
                                            barrierDismissible: false,
                                            barrierColor: Colors.transparent,
                                            context: context,
                                            builder: (c) {
                                              return EnterData(
                                                  isGenerated: false,
                                                  saveProfile: (profile2) {
                                                    setState(() {
                                                      profile = profile2;
                                                    });
                                                    finishSetup();
                                                  },
                                                  currentProfile: profile);
                                            });
                                      });
                                    },
                                    child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            color: Colors.grey.shade300),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6.0, horizontal: 14.0),
                                        child: const Center(
                                            child: Text(
                                          "Enter manually",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500),
                                        )))),
                                GestureDetector(
                                    onTap: () {
                                      if (dataState == 1) {
                                        return;
                                      }
                                      setState(() {
                                        dataState = 1;
                                        errorText = "";
                                      });

                                      /// open new dialog to fetch text from web
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (c) {
                                            return WebAnalysisDialog(
                                              url: editingController.text,
                                              success: (text) async {
                                                /// create InterViewProfile from text with gemini
                                                //print(text.length);
                                                final iv =
                                                    await InterviewProfile
                                                        .createFromWeb(text);
                                                //print(json.encode(iv.toJSON()));
                                                setState(() {
                                                  profile = iv;
                                                  dataState = 0;
                                                });

                                                if (profile != null) {
                                                  /// open dialog
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                          (_) async {
                                                    showDialog(
                                                        barrierDismissible:
                                                            false,
                                                        barrierColor:
                                                            Colors.transparent,
                                                        context: context,
                                                        builder: (c) {
                                                          return EnterData(
                                                              isGenerated: true,
                                                              saveProfile:
                                                                  (profile2) {
                                                                setState(() {
                                                                  profile =
                                                                      profile2;
                                                                });
                                                                finishSetup();
                                                              },
                                                              currentProfile:
                                                                  profile!);
                                                        });
                                                  });
                                                }
                                              },
                                              error: () {
                                                setState(() {
                                                  validText = "";
                                                  errorText =
                                                      "Website could not be analyzed.";
                                                });
                                              },
                                            );
                                          });
                                    },
                                    child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            color: Colors.grey.shade700),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6.0, horizontal: 14.0),
                                        child: Center(
                                            child: Text(
                                          dataState == 1
                                              ? "Loading..."
                                              : (dataState == 2
                                                  ? "Summarizing"
                                                  : "Gather data"),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500),
                                        ))))
                              ],
                            )),
                            const FlexSpacer(height: 18),
                            GestureDetector(
                                onTap: () {
                                  setState(() {
                                    currenState = 0;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2.0, horizontal: 32.0),
                                  child: const Center(
                                      child: Text(
                                    "Go back",
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16.0,
                                        decoration: TextDecoration.underline),
                                  )),
                                ))
                          ].where((x) => currenState == 1).toList())),
                  AnimatedOpacity(
                      opacity: currenState == 2 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 333),
                      child: Stack(
                        children: [
                          SizedBox(
                              height: currenState == 2
                                  ? animatedHeightBasedOnProfs() - 120
                                  : 0,
                              child: SingleChildScrollView(
                                child: Flex(
                                  direction: Axis.vertical,
                                  children: [
                                    const FlexSpacer(height: 12.0),
                                    FutureBuilder(
                                        future: loadMyProfiles(),
                                        builder:
                                            ((context, AsyncSnapshot snapshot) {
                                          if (snapshot.hasData) {
                                            if (numberOfProfs !=
                                                snapshot.data.length) {
                                              SchedulerBinding.instance
                                                  .addPostFrameCallback(
                                                      (_) => setState(() {
                                                            numberOfProfs =
                                                                snapshot.data
                                                                    .length;
                                                            psf = snapshot.data;
                                                          }));
                                            }
                                            if (snapshot.data.length == 0) {
                                              return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 18,
                                                      horizontal: 12),
                                                  child: const Center(
                                                      child: Text(
                                                          "You haven't created any profiles",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize:
                                                                  14.0))));
                                            }
                                            return Flex(
                                                direction: Axis.vertical,
                                                children: profieWidgets(
                                                    snapshot.data));
                                          }
                                          if (snapshot.hasError) {
                                            return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 18,
                                                        horizontal: 12),
                                                child: const Center(
                                                    child: Text(
                                                        "Something went wrong",
                                                        style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 14.0))));
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 18, horizontal: 12),
                                            child: const Center(
                                                child:
                                                    const CircularProgressIndicator()),
                                          );
                                        })),
                                    const FlexSpacer(height: 48.0),
                                  ].where((x) => currenState == 2).toList(),
                                ),
                              )),
                          Positioned(
                              bottom: 0,
                              height: 48.0,
                              left: 0,
                              right: 0,
                              child: Container(
                                  color: Colors.white,
                                  child: Flex(
                                    direction: Axis.vertical,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 24.0),
                                        child: Divider(),
                                      ),
                                      const FlexSpacer(height: 8.0),
                                      GestureDetector(
                                        child: const Text(
                                          "Go back",
                                          style: TextStyle(
                                              color: Colors.grey,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontSize: 16),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            currenState = 0;
                                          });
                                        },
                                      )
                                    ],
                                  )))
                        ],
                      ))
                ]))
          ],
        ),
      ),
      Positioned(
          top: 12.0,
          right: 12.0,
          child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Icon(Icons.close, color: Colors.black)))
    ]));
  }
}


class SimulateInterview extends StatefulWidget {
  const SimulateInterview({super.key});

  @override
  State<SimulateInterview> createState() => _SimulateInterviewState();
}

class _SimulateInterviewState extends State<SimulateInterview> {
  bool isOnline = false;
  bool isVoice = true;

  Map<String, dynamic> conversationData = {
    "title": "New Interview",
    "profile": {}
  };

  Conversation? currentConvo;
  InterviewProfile? profile;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    /// check if interview profile is loaded?
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (conversationData["profile"].keys.length == 0) {
        createNewProfile();
      }
    });
  }

  @override
  void dispose() {
    if (currentConvo != null) {
      currentConvo!.dispose();
    }

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void createNewProfile() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return CreateProfileDialog(
            setProfile: (InterviewProfile p) {
              setState(() {
                isLoading = true;
                profile = p;
              });

              /// create conversation with
              //print("Load c");
              Conversation.createFromProfile(p).then((x) {
                //print("Get c");
                setState(() {
                  isLoading = false;
                  currentConvo = x;
                  isOnline = true;
                });

                currentConvo!.addMessageListener((Message m) {
                  setState(() {});
                });
                currentConvo!.chatSettingListener = (() {
                  return isVoice;
                });
                if (kDebugMode) {
                  print("Start Interview");
                }
                currentConvo!.startInterview();
              }).catchError((err) {
                throw err;
              });
            },
          );
        });
  }

  /// audio vars
  int currentPlayer = -1;

  List<Widget> buildChatMessages() {
    if (currentConvo == null) {
      return [];
    }
    List<Widget> elements = [];
    elements.add(const SizedBox(
      height: 20.0,
    ));
    for (var msg in currentConvo!.messages) {
      elements.add(MessageView(
          chatMessage: msg as ChatMessage,
          currentPlayer: currentPlayer,
          requestCurrentPlayer: () {
            setState(() {
              currentPlayer = msg.messageId;
            });
          },
          getPrevious: () {
            final index = msg.messageId;
            return currentConvo!.messages[index - 1];
          },
          requestFeedback: (ChatMessage msg) {
            if (kDebugMode) {
              print("feedback");
            }

            /// load feedback
            /// get above messages
            final index = msg.messageId;
            if (index > 0) {
              final prevMessage = currentConvo!.messages[index - 1];
              if (prevMessage.role == Role.bot) {
                final profile = currentConvo!.realProfile;

                if (!profile!.isEmpty()) {
                  createFeedbackFor2Messages(profile, prevMessage, msg)
                      .then((ChatFeedback? feed) {
                    if (feed != null && currentConvo != null) {
                      setState(() {
                        currentConvo!.feedbacks.add(feed);
                      });
                      updateConversation(currentConvo!);
                    }
                  });
                } else {
                  if (kDebugMode) {
                    print("profile is empty");
                  }
                }
              }
            }
          },
          givenFeedback: currentConvo!.feedbacks.firstWhere(
              (f) => f.messageId == msg.messageId,
              orElse: () => ChatFeedback.empty())));
      if (currentConvo!.messages.last.messageId != msg.messageId) {
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
        body: Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ChatTopBar(
              saveConvo: () {
                if (currentConvo == null) {
                  return;
                }
                final Future f = currentConvo!.endInterview();

                f.then((x) async {
                  await Future.delayed(const Duration(milliseconds: 2000));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                });

                showDialog(
                    context: context,
                    builder: (v) {
                      return LoadingDialog(
                        loadingFuture: f,
                      );
                    },
                    barrierDismissible: false);
              },
              isImportant: () {
                return currentConvo != null &&
                    currentConvo!.messages
                            .where((x) => x.role == Role.user)
                            .toList()
                            .length >
                        1;
              },
              leaveChat: () {
                Navigator.of(context).pop();
              },
              liveInfo: () {
                showDialog(
                    context: context,
                    builder: ((c) {
                      return FinishDialog(
                          confirm: () {},
                          cancel: () {
                            Navigator.pop(context);
                          },
                          saveConvo: () {
                            if (currentConvo == null) {
                              return;
                            }
                            final Future f = currentConvo!.endInterview();

                            f.then((x) async {
                              await Future.delayed(
                                  const Duration(milliseconds: 2000));
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FeedbackPage2(
                                            title: profile == null
                                                ? "New Interview2"
                                                : (profile!.firmName.isNotEmpty
                                                    ? "Interview at ${profile!.firmName}"
                                                    : "New Interview3"),
                                            mainFeed: currentConvo!.feedbacks
                                                    .firstWhere((x) =>
                                                        x.messageId == -1)
                                                as MainFeedback,
                                            messages: currentConvo!.messages,
                                            feedbacks: currentConvo!.feedbacks,
                                          )));
                            }).catchError((e) {
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            });

                            showDialog(
                                context: context,
                                builder: (v) {
                                  return LoadingDialog(
                                    loadingFuture: f,
                                  );
                                },
                                barrierDismissible: false);
                          },
                          isIm: currentConvo != null &&
                              currentConvo!.messages
                                      .where((x) => x.role == Role.user)
                                      .toList()
                                      .length >
                                  1);
                    }));
              },
              isOnline: isOnline,
              selectInput: (input) {
                setState(() {
                  isVoice = input == "Voice";
                });
              },
              isVoice: isVoice,
              title: profile == null
                  ? "New Interview2"
                  : (profile!.firmName.isNotEmpty
                      ? "Interview at ${profile!.firmName}"
                      : "New Interview3"),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height -
                  100.0 -
                  MediaQuery.of(context).padding.bottom -
                  MediaQuery.of(context).padding.top,
              child: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: isLoading ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 333),
                    child: Container(
                        height: isLoading
                            ? MediaQuery.of(context).size.height -
                                300.0 -
                                MediaQuery.of(context).padding.bottom -
                                MediaQuery.of(context).padding.top
                            : 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Center(
                            child: Text(
                                isLoading ? "Loading conversation..." : "",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 16.0)))),
                  ),
                  Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: currentConvo != null &&
                              currentConvo!.messageListener != null
                          ? Container(
                              child: SingleChildScrollView(
                                  child: Flex(
                                      direction: Axis.vertical,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: buildChatMessages())))
                          : Container()),
                  GeneralInputBar(
                    isVoice: isVoice,
                    sendText: (text) {
                      if (currentConvo != null) {
                        currentConvo!.sendMessage(text).then((b) {});
                      }
                    },
                    sendAudio: (data) {
                      if (currentConvo != null) {
                        currentConvo!.sendMessage(data).then((b) {});
                      }
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class GeneralInputBar extends StatelessWidget {
  final bool isVoice;
  final Function sendText;
  final Function sendAudio;
  const GeneralInputBar(
      {super.key,
      required this.isVoice,
      required this.sendAudio,
      required this.sendText});

  @override
  Widget build(BuildContext context) {
    if (isVoice) {
      return AudioInputBar(sendAudio: sendAudio);
    } else {
      return ChatInputBar(sendText: sendText);
    }
  }
}

class AudioInputBar extends StatefulWidget {
  final Function sendAudio;
  const AudioInputBar({super.key, required this.sendAudio});

  @override
  State<AudioInputBar> createState() => _AudioInputBarState();
}

class _AudioInputBarState extends State<AudioInputBar> {
  bool isRecording = false;
  bool isPaused = false;
  bool isLoading = false;

  List<Color> colors = [
    Colors.grey.shade300,
    Colors.grey.shade300,
    Colors.grey.shade300
  ];
  final Color focusColor = Colors.grey.shade100;
  void runAnimation() {
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (isRecording || isPaused) {
        t.cancel();
      }
      Timer.periodic(const Duration(milliseconds: 100), (t2) {
        setState(() {
          var currentIndex = colors.indexOf(focusColor);
          if (currentIndex + 1 >= colors.length) {
            setState(() {
              colors = [
                Colors.grey.shade300,
                Colors.grey.shade300,
                Colors.grey.shade300
              ];
            });
            t2.cancel();
            return;
          }
          currentIndex = currentIndex + 1;
          List<Color> nextColors = [];
          for (var i = 0; i < colors.length; i++) {
            nextColors
                .add(currentIndex == i ? focusColor : Colors.grey.shade300);
          }
          setState(() {
            colors = nextColors;
          });
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    runAnimation();
    initRecord();
    setState(() {
      isLoading = false;
    });
  }

  String doubleDigitNumber(String numString) {
    if (numString.length == 1) {
      return numString.padLeft(2, "0");
    }
    return numString;
  }

  Widget whileRecording() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Stack(alignment: Alignment.center, children: [
          Flex(
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  "${(DateTime.fromMillisecondsSinceEpoch((recordTime * 1000).toInt()).minute.toString())}:${doubleDigitNumber((DateTime.fromMillisecondsSinceEpoch((recordTime * 1000).toInt()).second).toString())}",
                  style: const TextStyle(color: Colors.black, fontSize: 18.0)),
              const Spacer(),
              Flex(
                direction: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            color: Colors.grey.shade700),
                        child: const SizedBox(
                            height: 18,
                            width: 18,
                            child: Icon(Icons.pause, color: Colors.white))),
                    onTap: () async {
                      if (isLoading) {
                        return;
                      }
                      record.pause();
                    },
                  ),
                  const HorizontalFlexSpacer(width: 12.0),
                  GestureDetector(
                    child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            color: Colors.grey.shade700),
                        child: const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                Icon(Icons.north_east, color: Colors.white))),
                    onTap: () {
                      if (isLoading) {
                        return;
                      }
                      record.stop();
                      setState(() {
                        isLoading = true;
                      });
                      Timer.periodic(const Duration(milliseconds: 100), (c) {
                        if (checkStatus()) {
                          c.cancel();
                          String finalText = mergeTexts(textSegments);
                          widget.sendAudio(finalText);
                        }
                      });
                    },
                  )
                ],
              )
            ],
          ),
          const Center(
              child: Text("Recording...",
                  style: TextStyle(fontSize: 20.0, color: Colors.black)))
        ]));
  }

  Widget whilePaused() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Stack(alignment: Alignment.center, children: [
          Flex(
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  "${(DateTime.fromMillisecondsSinceEpoch((recordTime * 1000).toInt()).minute.toString())}:${doubleDigitNumber((DateTime.fromMillisecondsSinceEpoch((recordTime * 1000).toInt()).second).toString())}",
                  style: const TextStyle(color: Colors.black, fontSize: 18.0)),
              const Spacer(),
              Flex(
                direction: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            color: Colors.grey.shade700),
                        child: const SizedBox(
                            height: 12,
                            width: 12,
                            child: Icon(Icons.delete, color: Colors.white))),
                    onTap: () async {
                      if (isLoading) {
                        return;
                      }

                      /// delete current audio
                      setState(() {
                        textSegments = {};
                        segments = 0;
                        recordTime = 0;
                        finished = 0;
                        isLoading = false;
                        isRecording = false;
                        isPaused = false;
                      });
                      record.cancel();
                      runAnimation();
                    },
                  ),
                  const HorizontalFlexSpacer(width: 12.0),
                  GestureDetector(
                    child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            color: Colors.grey.shade700),
                        child: const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                Icon(Icons.north_east, color: Colors.white))),
                    onTap: () {
                      if (isLoading) {
                        return;
                      }
                      record.stop();
                      setState(() {
                        isLoading = true;
                      });
                      Timer.periodic(const Duration(milliseconds: 100), (c) {
                        if (checkStatus()) {
                          c.cancel();
                          String finalText = mergeTexts(textSegments);
                          widget.sendAudio(finalText);
                        }
                      });
                    },
                  )
                ],
              )
            ],
          ),
          Center(
              child: GestureDetector(
                  onTap: () {
                    record.resume();
                  },
                  child: const Text("Click to Continue",
                      style: TextStyle(fontSize: 20.0, color: Colors.black))))
        ]));
  }

  final record = AudioRecorder();

  double recordTime = 0;

  int segments = 0;
  int finished = 0;
  Map<double, String> textSegments = {};

  AmplitudePreview? amplitudePreview;

  void preProcessAudio(
      List<Uint8List> data, double time, Function? onFinished) async {
    if (data.isEmpty) {
      return;
    }
    setState(() {
      isLoading = true;
    });

    /// pcm to wav
    List<int> bytesSink = [];
    for (var i = 0; i < data.length; i++) {
      bytesSink.addAll(data[i].toList());
    }
    Uint8List realData =
        Pcmtowave.pcmToWav(Uint8List.fromList(bytesSink), 44100, 2);

    setState(() {
      segments = segments + 1;
    });
    final text = await transcribeWithGemini(realData);
    textSegments[time] = text;
    if (onFinished != null) {
      onFinished();
    }
  }

  bool checkStatus() {
    if (segments == textSegments.keys.length && textSegments.keys.isNotEmpty) {
      /// finished loading...
      /// prepare text data for combination
      /// String finalText = mergeTexts(textSegments);
      /// widget.sendAudio(finalText);
      setState(() {
        isLoading = false;
      });
      return true;
    }
    return false;
  }

  void initRecord() {
    record.onStateChanged().forEach((RecordState state) {
      if (RecordState.pause == state) {
        setState(() {
          isPaused = true;
          isRecording = false;
        });
      }
      if (RecordState.stop == state) {
        setState(() {
          isPaused = false;
          isRecording = false;
        });
      }
      if (RecordState.record == state) {
        setState(() {
          isPaused = false;
          isRecording = true;
        });
      }
    });
  }

  void continueRecording() async {
    if (await record.hasPermission()) {
      setState(() {
        isRecording = true;
        isPaused = false;
      });
      await listenToStream();
    }
    ;
  }

  Future<void> listenToStream() async {
    final stream = await record
        .startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));
    int status = 0;
    List<Uint8List> audioLists = [];
    List<Uint8List> audioLists2 = [];

    await stream.forEach((ul) {
      /// print(audioLists.length);
      /// print(audioLists2.length);
      (status == 0 || status == 1 ? audioLists : audioLists2).add(ul);

      /// check if MAX_TIME is done
      final totalBytes = (status == 0 || status == 1 ? audioLists : audioLists2)
          .map((x) => x.lengthInBytes)
          .reduce((a, b) => a + b);
      final totalSamples =
          totalBytes / Uint8List.bytesPerElement / 2; // 2 = num channels
      final totalSeconds = totalSamples / 44100 / 2; // 44100 = sample Rate
      /// print(totalSeconds);
      setState(() {
        recordTime +=
            ul.lengthInBytes / Uint8List.bytesPerElement / 2 / 44100 / 2;
      });
      if (totalSeconds >= 50.0 && (status == 0 || status == 1)) {
        /// send current audio data to gemini (pre-processing)
        status = 1;

        /// preProcessAudio(audioLists);
        /// audioLists = []
        /// audioLists2.add(ul);

        /// try to find the perfect moment to cut the audio
        record.getAmplitude().then((amp) {
          amplitudePreview ??=
              AmplitudePreview(amp.max, const Duration(seconds: 8));
          if (amplitudePreview != null) {
            if (amplitudePreview!.dataPoints.length >
                amplitudePreview!.sampleLength) {
              if (amplitudePreview!.evaluateBreakpoint(
                  amplitudePreview!
                      .dataPoints[amplitudePreview!.dataPoints.length - 3],
                  amp.current)) {
                preProcessAudio(audioLists, recordTime, null);
                audioLists = [];
                audioLists2.add(ul);
                status = 2;
                amplitudePreview = null;
                return;
              }
            }
            amplitudePreview!.add(amp.current);
          }
        });

        return;
      }

      if (totalSeconds >= 65.0 && status == 1) {
        /// if no breakpoint is found...
        status = 2;
        preProcessAudio(audioLists, recordTime, null);
        audioLists = [];
        audioLists2.add(ul);
        amplitudePreview = null;

        /// recordTime = recordTime + totalSeconds;
        return;
      }
      if (totalSeconds >= 55.0 && (status == 2 || status == 3)) {
        status = 3;
        record.getAmplitude().then((amp) {
          amplitudePreview ??=
              AmplitudePreview(amp.max, const Duration(seconds: 8));
          if (amplitudePreview != null) {
            if (amplitudePreview!.dataPoints.length >
                amplitudePreview!.sampleLength) {
              if (amplitudePreview!.evaluateBreakpoint(
                  amplitudePreview!
                      .dataPoints[amplitudePreview!.dataPoints.length - 3],
                  amp.current)) {
                preProcessAudio(audioLists2, recordTime, null);
                audioLists2 = [];
                audioLists.add(ul);
                status = 0;
                amplitudePreview = null;
                return;
              }
            }
            amplitudePreview!.add(amp.current);
          }
        });
        return;
      }
      if (totalSeconds >= 65.0 && status == 3) {
        status = 0;
        preProcessAudio(audioLists2, recordTime, null);
        audioLists2 = [];
        audioLists.add(ul);
        amplitudePreview = null;

        /// recordTime = recordTime + totalSeconds;
      }
    });

    /// stream is finished (part)
    if (recordTime == 0.0) {
      return;
    }
    if (audioLists.length > audioLists2.length) {
      preProcessAudio(audioLists, recordTime, () => {checkStatus()});
    } else {
      preProcessAudio(audioLists2, recordTime, () => {checkStatus()});
    }
  }

  void startRecording() async {
    if (await record.hasPermission()) {
      setState(() {
        isRecording = true;
        isPaused = false;
        textSegments = {};
        segments = 0;
        recordTime = 0;
      });
      await listenToStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
        duration: const Duration(milliseconds: 333),
        bottom: isLoading ? 2 : 0,
        height: isLoading ? 56 : 52,
        child: Stack(alignment: Alignment.topCenter, children: [
          Positioned(
              bottom: 0,
              height: 52,
              width: MediaQuery.of(context).size.width - 72,
              child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(24.0)),
                  child: AnimateGradient(
                      duration: const Duration(milliseconds: 333),
                      primaryColors: const [
                        Color.fromRGBO(113, 80, 238, 0.5),
                        Color.fromARGB(126, 42, 47, 49)
                      ],
                      secondaryColors: [
                        const Color.fromRGBO(113, 80, 238, 0.5),
                        const Color.fromRGBO(46, 205, 240, 0.5)
                      ].reversed.toList(),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.0)),
                      )))),
          Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade700, width: 1.0),
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: const [
                  BoxShadow(
                      color: Color.fromARGB(40, 0, 0, 0),
                      offset: Offset(0, 2),
                      spreadRadius: 2.0,
                      blurRadius: 4.0)
                ],
                color: Colors.white,
              ),
              height: 52.0,
              margin: const EdgeInsets.only(left: 36.0, right: 36.0),
              width: MediaQuery.of(context).size.width - 72,
              child: (!isRecording && !isPaused)
                  ? GestureDetector(
                      onTap: () {
                        if (isLoading) {
                          return;
                        }
                        startRecording();
                      },
                      child: Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flex(
                            direction: Axis.horizontal,
                            children: [
                              Icon(
                                Icons.arrow_forward_ios,
                                color: colors[0],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: colors[1],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: colors[2],
                              )
                            ],
                          ),
                          Text(isLoading ? "Loading..." : "Tap to record",
                              style: TextStyle(
                                  color: Colors.grey.shade700, fontSize: 22)),
                          Flex(
                            direction: Axis.horizontal,
                            children: [
                              Icon(
                                Icons.arrow_back_ios,
                                color: colors[2],
                              ),
                              Icon(
                                Icons.arrow_back_ios,
                                color: colors[1],
                              ),
                              Icon(
                                Icons.arrow_back_ios,
                                color: colors[0],
                              )
                            ],
                          ),
                        ],
                      ))
                  : (isRecording ? whileRecording() : whilePaused()))
        ]));
  }
}

class ChatInputBar extends StatefulWidget {
  final Function sendText;

  const ChatInputBar({super.key, required this.sendText});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool selected = false;
  String currentEnteredText = "";
  FocusNode mainTextFocusNode = FocusNode();
  TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    editingController.addListener(() {
      setState(() {
        currentEnteredText = editingController.text;
      });
    });
  }

  @override
  void dispose() {
    editingController.dispose();
    super.dispose();
  }

  int lines(BuildContext context) {
    final span = TextSpan(
        text: currentEnteredText, style: const TextStyle(fontSize: 17.0));
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout(
        maxWidth: MediaQuery.of(context).size.width - 72 - 32 - 12 - 30 - 20);
    return tp.computeLineMetrics().length;
  }

  int negNull(int i) {
    if (i < 0) {
      return 0;
    }
    if (i > 10) {
      return 10;
    }
    return i;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: selected ? MediaQuery.of(context).viewInsets.bottom + 10.0 : 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.grey.shade700),
            boxShadow: const [
              BoxShadow(
                  color: Color.fromARGB(40, 0, 0, 0),
                  offset: Offset(0, 2),
                  spreadRadius: 2.0,
                  blurRadius: 4.0)
            ],
            color: Colors.white,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 36.0),
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
          child: Flex(
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                  width: MediaQuery.of(context).size.width - 72 - 32 - 12 - 30,
                  height: 40 + negNull(lines(context) - 1) * 25,
                  child: Focus(
                      onFocusChange: (f) {
                        if (f) {
                          setState(() {
                            selected = true;
                          });
                        }
                      },
                      child: Expanded(
                          child: TextField(
                              expands: true,
                              maxLines: null,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Type...",
                                  hintStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 17.0),
                                  labelStyle: const TextStyle(
                                      color: Colors.black, fontSize: 17.0)),
                              controller: editingController,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 17.0))))),
              const Spacer(),
              const HorizontalFlexSpacer(width: 12.0),
              SizedBox(
                height: 28,
                width: 28,
                child: Flex(direction: Axis.vertical, children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Stack(
                      children: [
                        AnimatedOpacity(
                            duration: const Duration(milliseconds: 333),
                            opacity: currentEnteredText.isNotEmpty ? 0.0 : 1.0,
                            child: GestureDetector(
                                onTap: () {
                                  if (editingController.text.isEmpty) {
                                    return;
                                  }
                                  mainTextFocusNode.unfocus();
                                  widget.sendText(editingController.text);
                                  editingController.clear();
                                  editingController.text = "";
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(24)),
                                  height: 28,
                                  width: 28,
                                  child: const Center(
                                    child: Icon(
                                      Icons.north_east,
                                      color: Colors.white,
                                    ),
                                  ),
                                ))),
                        AnimatedOpacity(
                            duration: const Duration(milliseconds: 333),
                            opacity: currentEnteredText.isEmpty ? 0.0 : 1.0,
                            child: GestureDetector(
                                onTap: () {
                                  if (editingController.text.isEmpty) {
                                    return;
                                  }
                                  mainTextFocusNode.unfocus();
                                  widget.sendText(editingController.text);
                                  editingController.clear();
                                  editingController.text = "";
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(24)),
                                  height: 28,
                                  width: 28,
                                  child: const Center(
                                    child: Icon(
                                      Icons.north_east,
                                      color: Colors.white,
                                    ),
                                  ),
                                ))),
                      ],
                    ),
                  ),
                  const Spacer()
                ]),
              )
            ],
          ),
        ));
  }
}

class ChatTopBar extends StatelessWidget {
  final Function leaveChat;
  final Function liveInfo;
  final Function selectInput;
  final Function isImportant;
  final bool isOnline;
  final bool isVoice;
  final Function saveConvo;
  final String title;

  const ChatTopBar(
      {super.key,
      required this.leaveChat,
      required this.liveInfo,
      required this.isOnline,
      required this.selectInput,
      required this.isVoice,
      required this.title,
      required this.isImportant,
      required this.saveConvo});

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
                        ///

                        showDialog(
                            context: context,
                            builder: ((builder) {
                              return AreYouSure(
                                confirm: () {
                                  Navigator.pop(context);
                                  leaveChat();
                                },
                                cancel: () {
                                  Navigator.pop(context);
                                },
                                saveConvo: () {
                                  saveConvo();
                                },
                                important: isImportant(),
                              );
                            }));
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
                child: Container(
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
                ))))
          ]))
    ]);
  }
}

class WebAnalysisDialog extends StatefulWidget {
  const WebAnalysisDialog(
      {super.key,
      required this.url,
      required this.success,
      required this.error});

  final String url;
  final Function success;
  final Function error;

  @override
  State<WebAnalysisDialog> createState() => _WebAnalysisDialogState();
}

class _WebAnalysisDialogState extends State<WebAnalysisDialog> {
  HeadlessInAppWebView? headlessWebView;

  @override
  void initState() {
    super.initState();

    headlessWebView = new HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(widget.url))),
      onWebViewCreated: (controller) {},
      onConsoleMessage: (controller, consoleMessage) {},
      onLoadStart: (controller, url) async {},
      onLoadStop: (controller, url) async {
        /// inject
        Future.delayed(const Duration(milliseconds: 1000)).then((t) async {
          var value = await controller.evaluateJavascript(
              source: "document.body.innerText;");
          widget.success(value);
          headlessWebView!.dispose();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
        });
      },
    );
    headlessWebView!.run();
  }

  @override
  void dispose() {
    headlessWebView!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Container(color: Colors.transparent, width: 300.0, height: 400.0),
    );
  }
}

class EnterData extends StatefulWidget {
  final isGenerated;
  final InterviewProfile? currentProfile;
  final Function saveProfile;
  const EnterData(
      {super.key,
      required this.isGenerated,
      required this.currentProfile,
      required this.saveProfile});

  @override
  State<EnterData> createState() => _EnterDataState();
}

class _EnterDataState extends State<EnterData> {
  List<List<dynamic>> dataElements = [];

  Map<String, TextEditingController> controllers = {};

  late InterviewProfile myProfile = InterviewProfile.empty();

  @override
  void initState() {
    super.initState();

    /// enter data from profile directly
    Future.delayed(const Duration(milliseconds: 333)).then((res) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    });

    for (var obj in datakeys) {
      controllers[obj["key"].toString()] = TextEditingController();
    }
    if (widget.currentProfile != null) {
      widget.currentProfile!.toTextualJSON().forEach((key, value) {
        controllers[key]!.text = value.toString();
      });
      myProfile = widget.currentProfile!;
    } else {
      myProfile = InterviewProfile.empty();
    }

    setState(() {
      dataElements = [
        ["Company Name", "The name of the company.", 1],
        ["Company Description", "An overview of the company's mission.", 3],
        ["Job Description", "A summary of the job position", 3],
        ["Qualifications", "The required skills, experience, and education", 3],
        ["Role Expectations", "The responsibilities of the role", 2],
        ["Salary Expectation", "The salary range or expected compensation", 1]
      ];
    });
  }

  void removeData(String key) {
    setState(() {
      dataElements = dataElements.where((x) => x[0] != key).toList();
    });
  }

  void addData(String key, String hint, int lines) {
    setState(() {
      dataElements.insert(0, [key, hint, lines]);
    });
  }

  bool showTextFields = true;
  int loadingState = 0;

  List<Widget> getAllDataWidgets() {
    List<Widget> elements = [];
    for (var data in dataElements) {
      elements.add(const FlexSpacer(height: 4.0));
      elements.add(Container(
          child: Stack(children: [
        Container(
            margin: const EdgeInsets.only(top: 8.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade500, width: 1.0)),
            padding:
                const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
            width: 320,
            child: Stack(children: [
              TextField(
                controller: controllers[data[0]],
                maxLines: data[2],
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: data[0],
                    hintStyle: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey)),
                style: const TextStyle(fontSize: 14.0, color: Colors.black),
              ),
            ])),
        Positioned(
            top: 0,
            right: 8,
            child: GestureDetector(
                onTap: () {
                  /// remove this data type
                  removeData(data[0]);
                },
                child: Container(
                  height: 20,
                  width: 80.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border.all(color: Colors.grey.shade600, width: 1.0),
                      borderRadius: BorderRadius.circular(4.0)),
                  child: const Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.close,
                        size: 20.0,
                      ),
                      Text(
                        "Dismiss",
                        style: TextStyle(fontSize: 12.0),
                      )
                    ],
                  ),
                )))
      ])));
      elements.add(
        Container(
            padding: const EdgeInsets.only(left: 10.0),
            child: Flex(direction: Axis.horizontal, children: [
              Text(
                data[1],
                style: const TextStyle(color: Colors.grey, fontSize: 13.0),
                textAlign: TextAlign.start,
              ),
              const Spacer()
            ])),
      );
    }
    return elements;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Stack(children: [
      Container(
        height: 750,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.only(
            top: 18.0, left: 16.0, right: 16.0, bottom: 0.0),
        child: Flex(
          direction: Axis.vertical,
          children: [
            Flex(
              direction: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.isGenerated ? "Check " : "Enter ",
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 23.0,
                      fontWeight: FontWeight.w600),
                ),
                GradientText("Profile Data",
                    style: const TextStyle(
                        fontSize: 23.0, fontWeight: FontWeight.w600),
                    gradient: LinearGradient(colors: [
                      Colors.blue.shade400,
                      const Color.fromARGB(255, 152, 30, 233),
                    ]))
              ],
            ),
            const Text(
                "This data represents information about the upcoming interview.",
                style: TextStyle(color: Colors.black, fontSize: 16)),
            const FlexSpacer(height: 12.0),
            AddDataSegmentButton(
              changeState: (b) {
                setState(() {
                  showTextFields = b;
                });
              },
              addDataSegment: (ls) {
                addData(ls[0], ls[1], ls[2]);
              },
              currentKeys: dataElements.map((o) => o[0]).toList(),
            ),
            const FlexSpacer(height: 12.0),
            SizedBox(
              height: showTextFields
                  ? 750 - MediaQuery.of(context).viewInsets.bottom - 18 - 218
                  : 0,
              child: SingleChildScrollView(
                  child: Flex(
                direction: Axis.vertical,
                children:
                    getAllDataWidgets().where((x) => showTextFields).toList(),
              )),
            )
          ],
        ),
      ),
      Positioned(
        bottom: 0.0,
        height: 64.0,
        left: 0,
        right: 0,
        child: showTextFields
            ? Container(
                height: 64.0,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24.0),
                      bottomRight: Radius.circular(24.0)),
                ),
                child: Container(
                  height: 48.0,
                  padding: const EdgeInsets.only(
                      bottom: 12.0, left: 16.0, right: 16.0),
                  width: MediaQuery.of(context).size.width - 32,
                  child: Flex(
                    direction: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.shade700, width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5.0, horizontal: 12.0),
                              child: const Center(
                                  child: Text(
                                "Cancel",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              )))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: const Text(
                          "or",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                      GestureDetector(
                          onTap: () async {
                            if (loadingState == 1) {
                              return;
                            }
                            setState(() {
                              loadingState = 1;
                            });

                            if (myProfile.isEmpty()) {
                              /// hallucinate profile
                              /// only load not save
                              myProfile =
                                  await InterviewProfile.hallucinateProfile(
                                      datakeys
                                          .where((o) => dataElements
                                              .any((x) => x[0] == o["key"]))
                                          .toList());
                              setState(() {
                                loadingState = 0;
                              });
                              setState(() {
                                myProfile.toJSON().forEach((key, value) {
                                  final textKey = datakeys
                                      .firstWhere((o) => o["k"] == key)["key"];
                                  controllers[textKey]!.text = value.toString();
                                });
                              });
                              return;
                            } else {
                              /// Save profile
                              setState(() {
                                loadingState = 2;
                              });
                              File f = File(
                                  "${(await getApplicationDocumentsDirectory()).path}/x.txt");
                              f.createSync();
                              f.writeAsStringSync(
                                  json.encode(myProfile.toJSON()));

                              myProfile =
                                  await createProfileInFirestore(myProfile);
                              Navigator.pop(context);
                              widget.saveProfile(myProfile);
                            }
                          },
                          child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.shade700, width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: Colors.white),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5.0, horizontal: 12.0),
                              child: Center(
                                  child: Text(
                                loadingState == 0
                                    ? (myProfile.isEmpty()
                                        ? "Create Random"
                                        : "Save Profile")
                                    : (loadingState == 1
                                        ? "Hallucinating..."
                                        : "Loading..."),
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              )))),
                    ],
                  ),
                ),
              )
            : Container(),
      ),
      Positioned(
          top: 12.0,
          right: 12.0,
          child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Icon(Icons.close, color: Colors.black)))
    ]));
  }
}

class AddDataSegmentButton extends StatefulWidget {
  const AddDataSegmentButton(
      {super.key,
      required this.addDataSegment,
      required this.currentKeys,
      required this.changeState});
  final List currentKeys;
  final Function changeState;
  final Function addDataSegment;

  @override
  State<AddDataSegmentButton> createState() => _AddDataSegmentButtonState();
}

final datakeys = [
  {
    "key": "Additional Notes",
    "description": "Notes important for the upcoming interview",
    "text_field_lines": 4,
    "k": "additional_notes"
  },
  {
    "key": "Interviewer's Name",
    "description": "Name of the interviewer",
    "text_field_lines": 1,
    "k": "interviewer_name"
  },
  {
    "key": "Interviewer's Persona",
    "description": "Personality or demeanor of the interviewer",
    "text_field_lines": 2,
    "k": "interviewer_persona"
  },
  {
    "key": "Interviewer's Age",
    "description": "Estimated age of the interviewer",
    "text_field_lines": 1,
    "k": "interviewer_age"
  },
  {
    "key": "Interviewer's Speech Complexity",
    "description": "Complexity of the interviewer's speech",
    "text_field_lines": 1,
    "k": "interviewer_speech_complexity"
  },
  {
    "key": "Interviewer's Smalltalk Ability",
    "description": "Interviewer's ability to engage in small talk",
    "text_field_lines": 1,
    "k": "interviewer_smalltalk_ability"
  },
  {
    "key": "Interviewer's Attitude",
    "description": "Overall attitude of the interviewer",
    "text_field_lines": 2,
    "k": "interviewer_attitude"
  },
  {
    "key": "Company Name",
    "description": "The name of the company.",
    "text_field_lines": 1,
    "k": "company_name"
  },
  {
    "key": "Company Description",
    "description": "An overview of the company's mission.",
    "text_field_lines": 3,
    "k": "company_description"
  },
  {
    "key": "Job Description",
    "description": "A summary of the job position",
    "text_field_lines": 3,
    "k": "job_description"
  },
  {
    "key": "Qualifications",
    "description": "The required skills, experience, and education",
    "text_field_lines": 3,
    "k": "needed_qualification"
  },
  {
    "key": "Role Expectations",
    "description": "The responsibilities of the role",
    "text_field_lines": 2,
    "k": "role_expectation"
  },
  {
    "key": "Salary Expectation",
    "description": "The salary range or expected compensation",
    "text_field_lines": 1,
    "k": "expected_salary"
  }
];

class _AddDataSegmentButtonState extends State<AddDataSegmentButton> {
  int dataStatus = 0;
  bool openOptions = false;
  String selectedDataKey = "";

  @override
  void initState() {
    super.initState();
    var possible =
        datakeys.where((o) => !widget.currentKeys.contains(o["key"]!)).toList();
    setState(() {
      selectedDataKey = possible.first["key"].toString();
      dataStatus = 0;
    });
  }

  List<dynamic> mapToList(Map<String, dynamic> data) {
    return data.values.toList();
  }

  List<Widget> getAllPossibleDataOptions() {
    List<Widget> elements = [];
    var possible =
        datakeys.where((o) => !widget.currentKeys.contains(o["key"]!)).toList();
    elements.add(Container(
      child: const Divider(),
    ));
    for (var element in possible) {
      elements.add(GestureDetector(
        onTap: () {
          setState(() {
            selectedDataKey = element["key"].toString();
            openOptions = false;
            widget.changeState(true);
          });
        },
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            height: 56.0,
            child: Flex(direction: Axis.horizontal, children: [
              Flex(
                direction: Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    element["key"].toString(),
                    style: const TextStyle(color: Colors.black, fontSize: 16.0),
                  ),
                  Text(
                    element["description"].toString(),
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12.0,
                        overflow: TextOverflow.ellipsis),
                  )
                ],
              ),
              const Spacer()
            ])),
      ));
      if (possible.last != element) {
        elements.add(Container(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: const Divider(),
        ));
      }
    }
    return elements;
  }

  @override
  Widget build(BuildContext context) {
    var possible =
        datakeys.where((o) => !widget.currentKeys.contains(o["key"]!)).toList();
    if (!possible.map((o) => o["key"]!).contains(selectedDataKey)) {
      setState(() {
        selectedDataKey = possible.first["key"].toString();
      });
    }
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade500, width: 1.0),
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Stack(children: [
          AnimatedOpacity(
              opacity: dataStatus == 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 333),
              child: GestureDetector(
                  onTap: () {
                    setState(() {
                      dataStatus = 1;
                    });
                  },
                  child: Flex(
                    direction: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        color: Colors.black,
                      ),
                      const Text(
                        "Add new data segment",
                        style: TextStyle(color: Colors.black, fontSize: 16.0),
                      )
                    ].where((xx) => dataStatus == 0).toList(),
                  ))),
          AnimatedOpacity(
              opacity: dataStatus == 1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 333),
              child: Stack(children: [
                Container(
                    color: Colors.white,
                    child: Flex(
                        direction: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                              onTap: () {
                                if (openOptions) {
                                  widget.changeState(true);
                                  setState(() {
                                    openOptions = false;
                                  });
                                } else {
                                  widget.changeState(false);
                                  setState(() {
                                    openOptions = true;
                                  });
                                }
                              },
                              child: SizedBox(
                                width: 180.0,
                                child: Text(selectedDataKey,
                                    style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontSize: 14.0,
                                        decorationStyle:
                                            TextDecorationStyle.dotted,
                                        decorationColor: Colors.grey,
                                        color: Colors.grey,
                                        overflow: TextOverflow.ellipsis)),
                              )),
                          GestureDetector(
                              onTap: () {
                                setState(() {
                                  dataStatus = 0;
                                  openOptions = false;
                                  widget.changeState(true);
                                  widget.addDataSegment(mapToList(
                                      datakeys.firstWhere(
                                          (x) => x["key"] == selectedDataKey)));
                                });
                              },
                              child: Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 3.0, horizontal: 9.0),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius:
                                          BorderRadius.circular(16.0)),
                                  child: const Flex(
                                    direction: Axis.horizontal,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Append",
                                        style: TextStyle(fontSize: 14.0),
                                      ),
                                      HorizontalFlexSpacer(width: 8.0),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.black,
                                        size: 16.0,
                                      )
                                    ],
                                  ))),
                        ].where((x) => dataStatus == 1).toList())),
                AnimatedOpacity(
                    opacity: openOptions ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 333),
                    child: Container(
                      margin: EdgeInsets.only(top: openOptions ? 36.0 : 0),
                      height: openOptions
                          ? 750 -
                              MediaQuery.of(context).viewInsets.bottom -
                              18 -
                              171
                          : 0,
                      child: SingleChildScrollView(
                          child: Flex(
                              direction: Axis.vertical,
                              children: getAllPossibleDataOptions()
                                  .where((x) => openOptions)
                                  .toList())),
                    )),
              ])),
        ]));
  }
}
