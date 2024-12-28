import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mirror_view/functions.dart';

import 'components.dart';
import 'dialogs.dart';
import 'feedbacks.dart';

class ChatTopBarGeneral extends StatelessWidget {
  final Function leaveChat;

  final String title;
  final String subtitle;

  const ChatTopBarGeneral(
      {super.key,
      required this.subtitle,
      required this.leaveChat,
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
          height: 75.0,
          child: Stack(children: [
            Container(
                padding: const EdgeInsets.only(
                    top: 13.0, left: 16.0, right: 16.0, bottom: 12.0),
                decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade700, width: 1.0)),
                  color: Colors.white,
                ),
                child: Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                          onTap: () {
                            /// Leave
                            leaveChat();
                          },
                          child: Container(
                            width: 102,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                              color: Colors.grey.shade300,
                            ),
                            height: 40.0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 10.0),
                            child: Center(
                                child:
                                    Flex(direction: Axis.horizontal, children: [
                              Icon(
                                Icons.arrow_back_ios,
                                color: Colors.grey.shade700,
                                size: 18,
                              ),
                              const HorizontalFlexSpacer(width: 4.0),
                              Text(
                                "Go Back",
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.bold),
                              ),
                            ])),
                          )),
                      SizedBox(
                          height: 75.0,
                          child: Flex(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            direction: Axis.vertical,
                            children: [
                              subtitle.isNotEmpty
                                  ? Container()
                                  : const Spacer(),
                              TypeWriter2(
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500),
                                duration: const Duration(seconds: 1),
                                text: title,
                              ),
                              subtitle.isNotEmpty
                                  ? TypeWriter2(
                                      style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w500),
                                      duration: const Duration(seconds: 1),
                                      text: subtitle,
                                    )
                                  : const Spacer(),
                            ],
                          )),
                      const SizedBox(
                          width: 102,
                          child: Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: []))
                    ])),
          ]))
    ]);
  }
}

class Store extends StatefulWidget {
  const Store({super.key});

  @override
  State<Store> createState() => _StoreState();
}

class _StoreState extends State<Store> {
  List<Conversation> allConvs = [];
  bool empty = true;

  List<Widget> getListData(List<Conversation> data) {
    List<Widget> w = [];
    data.sort((a, b) {
      return a.createdAt == null
          ? 1
          : (b.createdAt == null ? -1 : a.createdAt!.compareTo(b.createdAt!));
    });
    for (var d in data.reversed) {
      if (d.realProfile == null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 5000))
              .then((check_again) {
            setState(() {});
          });
        });
        continue;
      }
      w.add(DataButton(
          mainTitle: "Interview at ${d.realProfile!.firmName}",
          des: d.realProfile!.jobDescription,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FeedbackPage2(
                          messages: d.messages,
                          setMain: (x) {
                            setState(() {
                              allConvs[allConvs.indexOf(d)].feedbacks.add(x);
                            });
                          },
                          feedbacks: d.feedbacks,
                          mainFeed: d.feedbacks.any((x) => x is MainFeedback)
                              ? d.feedbacks.firstWhere((x) => x is MainFeedback)
                                  as MainFeedback
                              : MainFeedback.empty(),
                          c: d,
                          title: d.realProfile == null
                              ? "Interview"
                              : (d.realProfile!.firmName.isNotEmpty
                                  ? "Interview at ${d.realProfile!.firmName}"
                                  : "Interview"),
                        )));
          },
          mainColor: Colors.grey.shade300,
          createdAt: d.createdAt!,
          index: data.length - data.indexOf(d)));
      w.add(const SizedBox(
        height: 12.0,
      ));
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          body: Stack(
            children: [
              ChatTopBarGeneral(
                  leaveChat: () {
                    print("leave");
                    Navigator.of(context).pop();
                  },
                  title: "Conversations",
                  subtitle: "& Feedbacks"),
              FutureBuilder(
                  future: loadAllConversations(),
                  builder: (cx, fu) {
                    if (fu.hasError) {
                      print(fu.error);
                      return const Positioned(
                        top: 75,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            "Something went wrong.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      );
                    }
                    if (fu.hasData) {
                      /// save data in state
                      if (empty) {
                        SchedulerBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            allConvs = fu.data!;
                            empty = false;
                          });
                        });
                      }
                      if (fu.data!.isEmpty) {
                        return const Positioned(
                          top: 75,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              "No conversations found.",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        );
                      }
                      return Positioned(
                          top: 120,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                              child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0, vertical: 20.0),
                              child: Flex(
                                direction: Axis.vertical,
                                children: getListData(allConvs),
                              ),
                            ),
                          )));
                    } else {
                      return const Positioned(
                        top: 75,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            "Loading conversations...",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      );
                    }
                  })
            ],
          ),
        ));
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = false;
  bool isCleared = false;

  bool isLoading2 = false;
  bool isCleared2 = false;

  int dStatus = 0;

  @override
  void initState() {
    super.initState();

    checkIfCVIsThere();
  }

  void checkIfCVIsThere() {
    cvAlreadyUploaded().then((v) {
      if (v) {
        setState(() {
          dStatus = -1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
            body: Stack(children: [
          ChatTopBarGeneral(
            leaveChat: () {
              print("leave");
              Navigator.of(context).pop();
            },
            title: "Profile & Data",
            subtitle: '',
          ),
          Positioned(
              top: 120,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 20.0),
                  child: Flex(
                      direction: Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Upload your resumé (or CV)",
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0),
                        ),
                        Text(
                          "You can upload your resumé for a more realistic and personal experience. MirrorView AI will use this information in the Interview Simulation as well as in the Resumé Interrogation. You can only upload PDF-files.",
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 14.0),
                        ),
                        const FlexSpacer(height: 8.0),
                        GestureDetector(
                            onTap: (() async {
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
                                }).catchError((err) {
                                  setState(() {
                                    dStatus = 3;
                                  });
                                });
                              } else {}
                            }),
                            child: const Text(
                              "Upload as a PDF",
                              style: TextStyle(
                                  color: Colors.black,
                                  decoration: TextDecoration.underline,
                                  fontSize: 15.0),
                            )),
                        const FlexSpacer(height: 8.0),
                        Text(
                          dStatus == 0
                              ? ""
                              : (dStatus == 1
                                  ? "(File is uploading)"
                                  : (dStatus == 2
                                      ? ("(File was successfully uploaded)")
                                      : (dStatus == -1
                                          ? "(You already uploaded your CV)"
                                          : "(Upload failed)"))),
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 14.0),
                        )
                      ]),
                ),
              ))),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1.0),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0)),
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 20.0),
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Data Privacy",
                      style: TextStyle(color: Colors.black, fontSize: 24),
                    ),
                    Text(
                      "This app saves conversations, feedbacks as well as your resume in its cloud. Your data is stored privately and secure.",
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 15),
                    ),
                    Flex(
                        direction: Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const FlexSpacer(height: 12.0),
                          GestureDetector(
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  border:
                                      Border.all(color: Colors.grey.shade700),
                                  color: Colors.grey.shade200),
                              width: 280,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.00, horizontal: 32.0),
                              child: Center(
                                child: Text(
                                  isCleared
                                      ? "All Data Cleared"
                                      : (isLoading
                                          ? "Loading..."
                                          : "Delete all Data"),
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 18.0),
                                ),
                              ),
                            ),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: ((b) {
                                    return ConfirmDialog(
                                      actionDes:
                                          "Your data cannot be recovered.",
                                      actionTitle: "Delete Data",
                                      cancel: () {
                                        Navigator.pop(context);
                                      },
                                      confirm: () {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        deleletAllData().then((x) {
                                          setState(() {
                                            isLoading = false;
                                            isCleared = true;
                                          });
                                          Navigator.pop(context);
                                        });
                                      },
                                    );
                                  }));
                            },
                          ),
                          const FlexSpacer(height: 12.0),
                          GestureDetector(
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  border:
                                      Border.all(color: Colors.grey.shade700),
                                  color: Colors.grey.shade200),
                              width: 280,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.00, horizontal: 32.0),
                              child: Center(
                                child: Text(
                                  isCleared2
                                      ? "Signing out"
                                      : (isLoading2
                                          ? "Loading..."
                                          : "Delete Data & Profile"),
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 18.0),
                                ),
                              ),
                            ),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: ((b) {
                                    return ConfirmDialog(
                                      actionDes:
                                          "Your data cannot be recovered. You have to sign in again.",
                                      actionTitle: "Delete Account",
                                      cancel: () {
                                        Navigator.pop(context);
                                      },
                                      confirm: () {
                                        setState(() {
                                          isLoading2 = false;
                                        });
                                        deletDataAndProfile().then((x) {
                                          setState(() {
                                            isLoading2 = false;
                                            isCleared2 = true;
                                          });
                                          Navigator.pop(context);
                                        });
                                      },
                                    );
                                  }));
                            },
                          )
                        ])
                  ],
                ),
              ))
        ])));
  }
}
