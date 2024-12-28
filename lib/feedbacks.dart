import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mirror_view/functions.dart';

import 'components.dart';

class ChatTopBar3 extends StatelessWidget {
  final Function leaveChat;

  final ChatFeedback feed;

  final String title;

  const ChatTopBar3(
      {super.key,
      required this.leaveChat,
      required this.feed,
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
                        child: TypeWriter2(
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w500),
                          duration: const Duration(seconds: 1),
                          text: title,
                        ),
                      ),
                      SizedBox(
                          width: 102,
                          child: Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                    onTap: () {
                                      /// Leave
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        color: Colors.grey.shade300,
                                      ),
                                      height: 40.0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0, horizontal: 10.0),
                                      child: Center(
                                          child: Flex(
                                        direction: Axis.horizontal,
                                        children: [
                                          Text(
                                            nearestAgo(DateTime.now()
                                                .difference(feed.createdAt)),
                                            style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.normal),
                                          )
                                        ],
                                      )),
                                    ))
                              ]))
                    ])),
          ]))
    ]);
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage(
      {super.key, required this.msg1, required this.msg2, required this.feed});

  final ChatMessage msg1;
  final ChatMessage msg2;

  final ChatFeedback feed;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  @override
  Widget build(BuildContext context) {
    print(widget.feed);

    return PopScope(
        canPop: false,
        child: Scaffold(
          body: Stack(
            children: [
              ChatScreen(
                  messages: [widget.msg1, widget.msg2], feed: widget.feed),
              ChatTopBar3(
                  leaveChat: () {
                    Navigator.of(context).pop();
                  },
                  feed: widget.feed,
                  title: "Feedback"),
              FeedbackDrawer(feed: widget.feed)
            ],
          ),
        ));
  }
}

class FeedbackPage2 extends StatefulWidget {
  const FeedbackPage2(
      {super.key,
      required this.messages,
      required this.feedbacks,
      required this.mainFeed,
      required this.title,
      this.c,
      this.setMain});
  final Conversation? c;
  final List<Message> messages;
  final List<ChatFeedback> feedbacks;
  final MainFeedback mainFeed;
  final String title;

  final Function? setMain;

  @override
  State<FeedbackPage2> createState() => _FeedbackPage2State();
}

class FeedbackView extends StatelessWidget {
  const FeedbackView(
      {super.key,
      required this.main,
      required this.title,
      required this.isFeed});
  final bool isFeed;
  final MainFeedback main;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: 140,
        left: 0,
        right: 0,
        height: isFeed ? (MediaQuery.of(context).size.height / 12 * 7 - 92) : 0,
        child: Container(
            padding: const EdgeInsets.only(top: 120.0, bottom: 20.0),
            height: isFeed ? (MediaQuery.of(context).size.height / 12 * 7) : 0,
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: isFeed
                    ? Container(
                        padding: const EdgeInsets.only(
                            top: 32.0, left: 18.0, right: 18.0),
                        child: Flex(
                            direction: Axis.vertical,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(title,
                                  style: const TextStyle(
                                      fontSize: 32, color: Colors.black)),
                              Text(main.overview,
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.black)),
                              const Divider(),
                              Flex(
                                  direction: Axis.vertical,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Additional Critique (${main.otherRating}/10)",
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                    const FlexSpacer(height: 2.0),
                                    Text(
                                      main.otherAnalysis,
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 16.0),
                                    ),
                                  ]),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 8.0),
                                child: Divider(),
                              ),
                              Flex(
                                direction: Axis.vertical,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Additional Advice",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                  const FlexSpacer(height: 2.0),
                                  Text(
                                    main.otherAdvice,
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 16.0),
                                  )
                                ],
                              )
                            ]))
                    : Container())));
  }
}

class _FeedbackPage2State extends State<FeedbackPage2> {
  bool isFeed = true;
  bool isMax = false;

  @override
  void initState() {
    super.initState();
    if (widget.mainFeed.isEmpty()) {
      setState(() {
        isMax = true;
        isFeed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          body: Stack(
            children: [
              AnimatedOpacity(
                  opacity: isFeed ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 333),
                  child: ChatScreen2(
                    messages: widget.messages,
                    feed: widget.feedbacks,
                    isFeed: isFeed,
                    isMax: isMax,
                  )),
              AnimatedOpacity(
                  opacity: isFeed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 333),
                  child: FeedbackView(
                      main: widget.mainFeed,
                      title: widget.title,
                      isFeed: isFeed)),
              ChatTopBar4(
                leaveChat: () {
                  Navigator.of(context).pop();
                },
                mainFeed: widget.mainFeed,
                title: "Main Feedback",
                isFeed: isFeed,
                selectView: (b) {
                  if (isMax) {
                    return;
                  }
                  setState(() {
                    isFeed = b;
                  });
                },
              ),
              FeedbackDrawer(
                feed: widget.mainFeed,
                isMax: isMax,
                isDisabled:
                    widget.messages.where((x) => x.role == Role.user).length <
                        2,
                setMain: (x) {
                  widget.setMain!(x);
                },
                c: widget.c,
              )
            ],
          ),
        ));
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.messages, required this.feed});

  final List<ChatMessage> messages;
  final ChatFeedback feed;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int currentPlayer = -1;

  List<Widget> buildChatMessages(List<ChatMessage> messages) {
    List<Widget> elements = [];
    elements.add(const SizedBox(
      height: 40.0,
    ));
    for (var msg in messages) {
      elements.add(MessageView(
          isSandbox: true,
          chatMessage: msg,
          currentPlayer: currentPlayer,
          requestCurrentPlayer: () {
            setState(() {
              currentPlayer = msg.messageId;
            });
          },
          getPrevious: () {
            final index = msg.messageId;
            return messages[index - 1];
          },
          requestFeedback: (ChatMessage msg) {},
          givenFeedback:
              msg.role == Role.user ? widget.feed : ChatFeedback.empty()));
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
    return Positioned(
        top: 92,
        left: 0,
        right: 0,
        height: (MediaQuery.of(context).size.height / 12 * 7 - 92),
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Flex(
                direction: Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: buildChatMessages(widget.messages))));
  }
}

class ChatScreen2 extends StatefulWidget {
  const ChatScreen2(
      {super.key,
      required this.messages,
      required this.feed,
      required this.isFeed,
      this.isMax});

  final List<Message> messages;
  final List<ChatFeedback> feed;
  final bool isFeed;

  final bool? isMax;

  @override
  State<ChatScreen2> createState() => _ChatScreen2State();
}

class _ChatScreen2State extends State<ChatScreen2> {
  int currentPlayer = -1;
  List<Widget> buildChatMessages(List<Message> messages) {
    if (widget.isFeed) {
      return [];
    }
    List<Widget> elements = [];
    elements.add(const SizedBox(
      height: 40.0,
    ));
    for (var msg in messages) {
      elements.add(MessageView(
          isSandbox: true,
          chatMessage: msg is ChatMessage ? msg : ChatMessage.fromMessage(msg),
          currentPlayer: currentPlayer,
          requestCurrentPlayer: () {
            setState(() {
              currentPlayer = msg.messageId;
            });
          },
          getPrevious: () {
            final index = msg.messageId;
            return messages[index - 1];
          },
          requestFeedback: (ChatMessage msg) {},
          givenFeedback: widget.feed.firstWhere(
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
    print(elements.length);
    return elements;
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    //var h = 300;
    return Positioned(
        top: 140,
        left: 0,
        right: 0,
        height: !widget.isFeed
            ? (widget.isMax != null && widget.isMax! == true
                ? h / 4 * 3
                : h / 12 * 7)
            : 0,
        child: Container(
            padding: const EdgeInsets.only(top: 120.0, bottom: 0.0),
            height: !widget.isFeed
                ? (widget.isMax != null && widget.isMax! == true
                    ? h / 4 * 3
                    : h / 12 * 7)
                : 0,
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Flex(
                    direction: Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: buildChatMessages(widget.messages)))));
  }
}

class FeedbackDrawer extends StatefulWidget {
  const FeedbackDrawer(
      {super.key,
      required this.feed,
      this.isMax,
      this.isDisabled,
      this.c,
      this.setMain});
  final Conversation? c;
  final ChatFeedback feed;
  final bool? isMax;
  final bool? isDisabled;
  final Function? setMain;

  @override
  State<FeedbackDrawer> createState() => _FeedbackDrawerState();
}

class _FeedbackDrawerState extends State<FeedbackDrawer> {
  bool isContent = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0.0,
      left: 0.0,
      right: 0.0,
      height: widget.isMax != null && widget.isMax! == true
          ? MediaQuery.of(context).size.height / 4
          : MediaQuery.of(context).size.height / 12 * 5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.0),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0), topRight: Radius.circular(12.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        child: widget.isMax != null && widget.isMax! == true
            ? Center(
                child: Flex(
                    mainAxisAlignment: MainAxisAlignment.center,
                    direction: Axis.vertical,
                    children: [
                      GestureDetector(
                          onTap: () async {
                            if (isLoading) {
                              return;
                            }
                            if (widget.isDisabled != null &&
                                widget.isDisabled!) {
                              return;
                            }
                            if (widget.c != null) {
                              setState(() {
                                isLoading = true;
                              });
                              MainFeedback f =
                                  await widget.c!.createMainFeedback();
                              if (f.isEmpty()) {
                                return;
                              }
                              widget.setMain!(f);
                              setState(() {
                                isLoading = false;
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                    color: Colors.black, width: 1.0)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Center(
                                child: Text(
                              isLoading ? "Loading..." : "Create Main Feedback",
                              style: TextStyle(
                                  color: widget.isDisabled != null &&
                                          widget.isDisabled! == true
                                      ? Colors.grey
                                      : Colors.black,
                                  fontSize: 18),
                            )),
                          )),
                      widget.isDisabled != null && widget.isDisabled == true
                          ? Container(
                              margin: const EdgeInsets.only(top: 6.0),
                              child: const Text(
                                "Cannot create main feedback. Interview is too short.",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 14),
                              ))
                          : Container(),
                      const SizedBox(
                        height: 80,
                      ),
                    ]),
              )
            : Flex(
                direction: Axis.vertical,
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flex(
                          direction: Axis.vertical,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isContent
                                  ? "Content Analysis"
                                  : "Language Analysis",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            const FlexSpacer(height: 3.0),
                            GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isContent = !isContent;
                                  });
                                },
                                child: Text(
                                  "Switch to ${isContent ? "Language Analysis" : "Content Analysis"}",
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      decoration: TextDecoration.underline,
                                      fontSize: 14.0),
                                ))
                          ],
                        ),
                        Flex(
                          direction: Axis.vertical,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isContent ? widget.feed.contentRating.toString() : widget.feed.languageRating.toString()}/10",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            const FlexSpacer(height: 3.0),
                            const Text(
                              "Rating",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14.0),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 12 * 5 - 100,
                    child: SingleChildScrollView(
                      child: Flex(
                        direction: Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flex(
                            direction: Axis.vertical,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                isContent
                                    ? "Content Critique"
                                    : "Language Critique",
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              const FlexSpacer(height: 2.0),
                              Text(
                                isContent
                                    ? widget.feed.contentAnalysis
                                    : widget.feed.languageAnalysis,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16.0),
                              )
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                            child: Divider(),
                          ),
                          Flex(
                            direction: Axis.vertical,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                isContent
                                    ? "Content Advice"
                                    : "Language Advice",
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              const FlexSpacer(height: 2.0),
                              Text(
                                isContent
                                    ? widget.feed.contentAdvice
                                    : widget.feed.languageAdvice,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16.0),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({
    super.key,
    required this.loadingFuture,
  });

  final Future loadingFuture;

  @override
  Widget build(BuildContext context) {
    //Navigator.pop(context);
    return Dialog(
        child: Container(
      height: 80,
      width: 300,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12.0)),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
      child: Center(
          child: FutureBuilder(
              future: loadingFuture,
              builder: (b, c) {
                if (c.hasData) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    Navigator.pop(context);
                  });
                  return const Text(
                    "Done",
                    style: TextStyle(color: Colors.grey, fontSize: 20),
                  );
                } else {
                  return const Text(
                    "Loading...",
                    style: TextStyle(color: Colors.grey, fontSize: 20),
                  );
                }
              })),
    ));
  }
}

class ChatTopBar4 extends StatelessWidget {
  final Function leaveChat;
  final Function selectView;

  final bool isFeed;

  final String title;

  final MainFeedback mainFeed;

  const ChatTopBar4(
      {super.key,
      required this.leaveChat,
      required this.isFeed,
      required this.selectView,
      required this.mainFeed,
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
                        child: TypeWriter2(
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w500),
                          duration: const Duration(seconds: 1),
                          text: title,
                        ),
                      ),
                      SizedBox(
                          width: 102,
                          child: Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                    onTap: () {
                                      /// Leave
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        color: Colors.grey.shade300,
                                      ),
                                      height: 40.0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0, horizontal: 10.0),
                                      child: Center(
                                          child: Flex(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        direction: Axis.horizontal,
                                        children: [
                                          Text(
                                            nearestAgo(DateTime.now()
                                                .difference(
                                                    mainFeed.createdAt)),
                                            style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.normal),
                                          )
                                        ],
                                      )),
                                    ))
                              ]))
                    ])),
            Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: GestureDetector(
                    onTap: () {
                      selectView(!isFeed);
                    },
                    child: Container(
                        child: Center(
                            child: Container(
                                width: 150.0,
                                height: 35,
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade700),
                                    borderRadius: BorderRadius.circular(24.0),
                                    color: Colors.white),
                                child: Center(
                                  child: Text(
                                    isFeed ? "Show Chat" : "See Feedback",
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ))))))
          ]))
    ]);
  }
}
