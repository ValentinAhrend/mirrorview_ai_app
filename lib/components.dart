import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mirror_view/feedbacks.dart';

import 'functions.dart' as f;


const WELCOME_TEXTS = [
  {
    "title": "Master your interview",
    "des":
        "The goal of this app is to prepare yourself for difficult interview questions."
  },
  {
    "title": "Introduce yourself",
    "des":
        "To optimize your experience, MirrorView AI can use your resume and entered data to create an almost real interview."
  },
  {
    "title": "Get feedback",
    "des":
        "You can get feedback on every answer and will get feedback at the end of each interview"
  },
  {"title": "Let's start", "des": ""}
];

class InfoDialog extends StatefulWidget {
  const InfoDialog({super.key});

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  int dialogPos = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Colors.white,
            ),
            child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 13.0, horizontal: 20.0),
                child: Stack(children: [
                  AnimatedOpacity(
                      opacity: dialogPos != 3 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 333),
                      child: Flex(
                        direction: Axis.vertical,
                        children: [
                          Flex(
                            direction: Axis.horizontal,
                            children: [
                              Text(
                                WELCOME_TEXTS[dialogPos]["title"]!,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: (WELCOME_TEXTS[dialogPos]["des"]!
                                            .isEmpty
                                        ? 39
                                        : 23),
                                    decoration: TextDecoration.underline,
                                    decorationStyle: TextDecorationStyle.dotted,
                                    fontWeight: (WELCOME_TEXTS[dialogPos]
                                                ["des"]!
                                            .isEmpty
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                              ),
                              const Spacer(),
                            ],
                          ),
                          Text(
                            WELCOME_TEXTS[dialogPos]["des"]!,
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 16.0),
                          ),
                          const Spacer(),
                          Container(
                              margin: const EdgeInsets.only(bottom: 6.0),
                              child: Flex(
                                direction: Axis.horizontal,
                                children: [
                                  Text(
                                    "${dialogPos + 1}/${WELCOME_TEXTS.length}",
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 16.0),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      if (dialogPos + 1 ==
                                          WELCOME_TEXTS.length) {
                                        Navigator.of(context).pop();
                                        return;
                                      }
                                      setState(() {
                                        dialogPos = dialogPos + 1;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0, horizontal: 12.0),
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black, width: 1.0),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          gradient: const LinearGradient(
                                              colors: [
                                                Color.fromRGBO(
                                                    113, 80, 238, 1.0),
                                                Color.fromRGBO(
                                                    46, 205, 240, 1.0)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              stops: [-0.2, 1.2])),
                                      child: const Center(
                                        child: Text(
                                          "Next",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              )),
                        ].where((x) => dialogPos != 3).toList(),
                      )),
                  AnimatedOpacity(
                    opacity: dialogPos == 3 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 333),
                    child: Center(
                      child: Flex(
                        direction: Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            child: Text(
                              "Continue to MirrorView AI",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 23.0),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                            width: 220.0,
                          ),
                          const FlexSpacer(height: 8.0),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                dialogPos = 0;
                              });
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 120.0,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 12.0),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black, width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                  gradient: const LinearGradient(
                                      colors: [
                                        Color.fromRGBO(113, 80, 238, 1.0),
                                        Color.fromRGBO(46, 205, 240, 1.0)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      stops: [-0.2, 1.2])),
                              child: const Center(
                                child: Text(
                                  "Let's go",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ]))));
  }
}

class DataButton extends StatelessWidget {
  final String mainTitle;
  final String des;
  final Function onTap;
  final Color mainColor;
  final DateTime createdAt;
  final int index;

  const DataButton({
    super.key,
    required this.mainTitle,
    required this.des,
    required this.onTap,
    required this.mainColor,
    required this.createdAt,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          onTap();
        },
        child: Container(
            width: 340.0,
            height: 122.0,
            child: Stack(alignment: Alignment.topRight, children: [
              Positioned(
                top: 6.0,
                right: 5.0,
                left: 5.0,
                height: 114.0,
                child: Container(
                  width: 330,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.0),
                      borderRadius: BorderRadius.circular(14.0),
                      color: mainColor),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.0),
                  borderRadius: BorderRadius.circular(14.0),
                  color: Colors.white,
                ),
                width: 340.0,
                height: 114.0,
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Flex(
                  direction: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flex(
                      direction: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "#$index",
                          style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0),
                        ),
                        Text(
                          "${createdAt.day}.${createdAt.month}.${createdAt.year}",
                          style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0),
                        ),
                      ],
                    ),
                    Text(
                      mainTitle,
                      maxLines: 2,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 19.0),
                    ),
                    Text(
                      des,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.normal,
                          fontSize: 12.0),
                    )
                  ],
                ),
              ),
            ])));
  }
}

class InterestingButton extends StatelessWidget {
  final String title;
  final String des;
  final Function onTap;
  final Color mainColor;

  const InterestingButton(
      {super.key,
      required this.title,
      required this.des,
      required this.onTap,
      required this.mainColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          onTap();
        },
        child: Container(
            width: 348.0,
            height: 88.0,
            child: Stack(alignment: Alignment.topRight, children: [
              Positioned(
                top: 5.0,
                right: 5.0,
                width: 340.0,
                height: 80.0,
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.0),
                      borderRadius: BorderRadius.circular(14.0),
                      color: mainColor),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.0),
                  borderRadius: BorderRadius.circular(14.0),
                  color: Colors.white,
                ),
                width: 340.0,
                height: 80.0,
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Flex(
                  direction: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flex(
                      direction: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                        )
                      ],
                    ),
                    Text(
                      des,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.normal,
                          fontSize: 12.0),
                    )
                  ],
                ),
              ),
            ])));
  }
}

class FlexSpacer extends StatelessWidget {
  final double height;
  const FlexSpacer({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, width: 1.0);
  }
}

class HorizontalFlexSpacer extends StatelessWidget {
  final double width;
  const HorizontalFlexSpacer({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: 1.0);
  }
}

class TypeWriter extends StatefulWidget {
  final Duration duration;
  final String text;
  final Function? onClick;
  final TextStyle style;

  const TypeWriter(
      {super.key,
      this.onClick,
      required this.duration,
      required this.text,
      required this.style});
  @override
  State<TypeWriter> createState() => _TypeWriterState();
}

class _TypeWriterState extends State<TypeWriter> {
  bool running = true;
  String text = "";

  @override
  void initState() {
    Timer.periodic(
        Duration(
            milliseconds: widget.duration.inMilliseconds ~/ widget.text.length),
        (f) {
      if (!running) {
        f.cancel();
      }
      setState(() {
        text = widget.text.substring(0, text.length + 1);
        if (text.length == widget.text.length) {
          f.cancel();
        }
      });
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TypeWriter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      setState(() {
        text = "";
        running = true;
      });

      Timer.periodic(
          Duration(
              milliseconds:
                  widget.duration.inMilliseconds ~/ widget.text.length), (f) {
        if (!running) {
          f.cancel();
        }
        setState(() {
          text = widget.text.substring(0, text.length + 1);
          if (text.length == widget.text.length) {
            f.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    setState(() {
      running = false;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 200.0,
        height: 32.0,
        child: Center(
            child: Text(
          text,
          style: widget.style,
          overflow: TextOverflow.ellipsis,
        )));
  }
}

class TypeWriter2 extends StatefulWidget {
  final Duration duration;
  final String text;
  final Function? onClick;
  final TextStyle style;

  const TypeWriter2(
      {super.key,
      this.onClick,
      required this.duration,
      required this.text,
      required this.style});
  @override
  State<TypeWriter2> createState() => _TypeWriter2State();
}

class _TypeWriter2State extends State<TypeWriter2> {
  bool running = true;
  String text = "";

  @override
  void initState() {
    if (widget.duration == Duration.zero) {
      setState(() {
        text = widget.text;
      });
      return;
    }
    Timer.periodic(
        Duration(
            milliseconds: widget.duration.inMilliseconds ~/ widget.text.length),
        (f) {
      if (!running) {
        f.cancel();
      }
      setState(() {
        text = widget.text.substring(0, text.length + 1);
        if (text.length == widget.text.length) {
          f.cancel();
        }
      });
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TypeWriter2 oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      setState(() {
        text = "";
        running = true;
      });

      if (widget.duration == Duration.zero) {
        setState(() {
          text = widget.text;
        });
        return;
      }

      Timer.periodic(
          Duration(
              milliseconds:
                  widget.duration.inMilliseconds ~/ widget.text.length), (f) {
        if (!running) {
          f.cancel();
        }
        setState(() {
          text = widget.text.substring(0, text.length + 1);
          if (text.length == widget.text.length) {
            f.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    setState(() {
      running = false;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: widget.style,
      overflow: TextOverflow.ellipsis,
      maxLines: 100,
      textAlign: TextAlign.start,
    );
  }
}

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    required this.gradient,
    this.style,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

class GradientButton extends StatelessWidget {
  final LinearGradient gradient;
  final String title;
  final Function onClick;
  const GradientButton(
      {super.key,
      required this.gradient,
      required this.title,
      required this.onClick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          onClick();
        },
        child: Container(
          width: 260.0,
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0), gradient: gradient),
          height: 48.0,
          child: Center(
              child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21.0),
                      color: Colors.white),
                  child: Center(
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 19.0,
                              fontWeight: FontWeight.w500))))),
        ));
  }
}

class MessageView extends StatefulWidget {
  final f.ChatMessage chatMessage;
  final int currentPlayer;
  final Function requestCurrentPlayer;
  final Function requestFeedback;
  final f.ChatFeedback? givenFeedback;
  final Function getPrevious;
  final bool? isSandbox;
  final Map? eData;

  const MessageView(
      {super.key,
      required this.chatMessage,
      required this.currentPlayer,
      required this.requestCurrentPlayer,
      required this.requestFeedback,
      this.givenFeedback,
      required this.getPrevious,
      this.isSandbox,
      this.eData});

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView> {
  Duration dt = const Duration(milliseconds: 0);
  int totalSeconds = 0;
  bool isPlaying = false;

  String addPadLeftNumeric(int second) {
    if (second.toString().length == 1) {
      return "0$second";
    } else {
      return second.toString();
    }
  }

  AudioPlayer? player;

  void playAudio() async {
    if (widget.chatMessage.audioFile == null) {
      return;
    }
    widget.requestCurrentPlayer();
    player = AudioPlayer();
    ;
    await player!.stop();
    player!.setSource(DeviceFileSource(widget.chatMessage.audioFile!.path));
    final duration = await player!.getDuration();
    setState(() {
      totalSeconds = duration!.inMilliseconds;
      isPlaying = true;
    });

    if (dt.inMilliseconds == duration?.inMilliseconds) {
      setState(() {
        dt = const Duration(milliseconds: 0);
      });
    }
    player!.seek(dt);
    player!.onPlayerComplete.map((d) {
      setState(() {
        isPlaying = false;
        dt = const Duration(microseconds: 0);
      });
      player!.seek(const Duration(milliseconds: 0));
    });
    player!.play(DeviceFileSource(widget.chatMessage.audioFile!.path));
    player!.eventStream.listen((c) {
      if (widget.currentPlayer != widget.chatMessage.messageId) {
        /// stop player
        player!.pause();
        setState(() {
          isPlaying = false;
        });
      }
      setState(() {
        if (c.position != null) {
          dt = c.position!;
        }
      });
    });
  }

  void setPos(double value) {
    if (player == null) {
      return;
    }
    player!.seek(Duration(milliseconds: value.toInt()));
  }

  void pauseAudio() {
    if (player == null) {
      return;
    }
    player!.pause();
    setState(() {
      isPlaying = false;
    });
  }

  int feedbackState = 0;
  void loadFeedback() async {
    setState(() {
      feedbackState = 1;
    });
    widget.requestFeedback(widget.chatMessage);
  }

  @override
  void dispose() {
    if (player != null) {
      player!.dispose();
    }

    if (isPlaying) {
      if (player != null) {
        player!.stop();
      }
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(MessageView old) {
    super.didUpdateWidget(old);

    if (widget.currentPlayer != widget.chatMessage.messageId) {
      if (player != null) {
        player!.pause();
      }
      setState(() {
        isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chatMessage.audioFile != null && player == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        player ??= AudioPlayer();
        player!.setSource(DeviceFileSource(widget.chatMessage.audioFile!.path));
        final duration = await player!.getDuration();
        setState(() {
          setState(() {
            totalSeconds = duration!.inMilliseconds;
          });
        });
        if (widget.isSandbox != null && widget.isSandbox!) {
          return;
        }
        playAudio();
      });
    }

    if (widget.chatMessage.role == f.Role.user) {
      return Stack(alignment: Alignment.topCenter, children: [
        feedbackState == 0
            ? Container()
            : Positioned(
                bottom: 0.0,
                height: 40.0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 333),
                    opacity: feedbackState == 0 ? 0.0 : 1.0,
                    child: GestureDetector(
                      child: Container(
                        margin: const EdgeInsets.only(left: 12.0, right: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8.0),
                              bottomRight: Radius.circular(8.0)),
                          border: Border.all(color: Colors.grey, width: 1.0),
                        ),
                        padding: const EdgeInsets.only(
                            top: 10.0, left: 12.0, right: 12.0, bottom: 4.0),
                        child: widget.givenFeedback == null ||
                                widget.givenFeedback!.isEmpty()
                            ? const Text("Loading feedback...")
                            : Flex(
                                direction: Axis.horizontal,
                                children: [
                                  Text(
                                      "Feedback (${widget.givenFeedback!.contentRating + widget.givenFeedback!.languageRating}/20)"),
                                  const Spacer(),
                                  const Text("See Details"),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.black,
                                  )
                                ],
                              ),
                      ),
                      onTap: () {
                        if (widget.givenFeedback is f.MainFeedback) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FeedbackPage2(
                                        messages: [
                                          widget.getPrevious(),
                                          widget.chatMessage
                                        ],
                                        mainFeed: widget.givenFeedback!
                                            as f.MainFeedback,
                                        feedbacks: [],
                                        title: "Answer Analysis",
                                      )));
                          return;
                        }

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FeedbackPage(
                                      msg1: widget.getPrevious(),
                                      msg2: widget.chatMessage,
                                      feed: widget.givenFeedback!,
                                    )));
                      },
                    ))),
        AnimatedContainer(
          duration: const Duration(milliseconds: 333),
          width: MediaQuery.of(context).size.width > 400 ? 360 : 300,
          margin: EdgeInsets.only(
              left: 12.0, right: 12.0, bottom: feedbackState == 0 ? 0.0 : 34.0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey, width: 1.0),
              color: Colors.grey.shade100),
          child: Flex(
            direction: Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypeWriter2(
                duration: widget.isSandbox != null && widget.isSandbox!
                    ? Duration.zero
                    : Duration(
                        seconds: widget.chatMessage.content.length ~/ 100),
                text: widget.chatMessage.content,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Container(
                height: 20.0,
                padding: const EdgeInsets.only(top: 2.0),
                child: Flex(
                  direction: Axis.horizontal,
                  children: [
                    Text(
                      "Answer #${(widget.chatMessage.messageId + 1) ~/ 2}",
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 14.0),
                    ),
                    const Spacer(),
                    GestureDetector(
                      child: const Text(
                        "Get Feedback",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.0,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.grey),
                      ),
                      onTap: () {
                        if (widget.isSandbox != null && widget.isSandbox!) {
                          return;
                        }
                        if (feedbackState == 0) {
                          loadFeedback();
                        }
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ]);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15.0),
      width: MediaQuery.of(context).size.width > 400 ? 375 : 300,
      padding: EdgeInsets.only(
          top: 3.0,
          left: 3.0,
          right: 3.0,
          bottom: widget.chatMessage.audioFile != null ? 3 : 3),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.0),
          border: Border.all(color: Colors.grey, width: 1.0),
          gradient: widget.eData == null
              ? const LinearGradient(
                  colors: [
                    Color.fromRGBO(113, 80, 238, 1.0),
                    Color.fromRGBO(46, 205, 240, 1.0)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [-0.2, 1.2])
              : null,
          color: widget.eData == null ? null : widget.eData!["color"]),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey, width: 1.0),
            color: Colors.white.withAlpha(250)),
        child: Flex(
          direction: Axis.vertical,
          children: [
            TypeWriter2(
                duration: widget.isSandbox != null && widget.isSandbox!
                    ? Duration.zero
                    : Duration(
                        seconds: widget.chatMessage.content.length ~/ 30),
                text: widget.chatMessage.content,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                )),
            SizedBox(
              height: widget.chatMessage.audioFile == null ? 18.0 : 72.0,
              child: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: widget.chatMessage.audioFile == null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 333),
                    child: Flex(
                      direction: Axis.horizontal,
                      children: [
                        SizedBox(
                          width: 248,
                          height: 18,
                          child: Text(
                            widget.eData == null
                                ? "Interviewer"
                                : widget.eData!["name"],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14.0),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Spacer(),
                        Text(
                            "Question #${(widget.chatMessage.messageId + 2) ~/ 2}",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14.0))
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                      opacity: widget.chatMessage.audioFile == null ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 333),
                      child: Flex(direction: Axis.vertical, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 4.0),
                          child: const Center(
                            child: const Divider(),
                          ),
                        ),
                        Flex(
                          direction: Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                                "${DateTime.fromMillisecondsSinceEpoch(dt.inMilliseconds).minute}:${addPadLeftNumeric(DateTime.fromMillisecondsSinceEpoch(dt.inMilliseconds).second)}"),
                            Slider(
                              divisions:
                                  totalSeconds == 0 ? 1 : totalSeconds ~/ 100,
                              value: (dt.inMilliseconds).toDouble(),
                              max: (totalSeconds).toDouble(),
                              onChanged: (x) {
                                setState(() {
                                  dt = Duration(milliseconds: (x).toInt());
                                  if (player != null) {
                                    player!.pause();
                                  }
                                  isPlaying = false;
                                });
                              },
                              thumbColor: Colors.black,
                              activeColor: Colors.black,
                            ),
                            GestureDetector(
                                onTap: () {
                                  if (!isPlaying) {
                                    playAudio();
                                  } else {
                                    pauseAudio();
                                  }
                                },
                                child: Icon(
                                  !isPlaying ? Icons.play_arrow : Icons.pause,
                                  color: Colors.black,
                                ))
                          ],
                        ),
                      ]))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CoolButton extends StatefulWidget {
  final Function onClick;
  final String title;

  const CoolButton({super.key, required this.onClick, required this.title});

  @override
  State<CoolButton> createState() => _CoolButtonState();
}

class _CoolButtonState extends State<CoolButton> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 348.0,
        child: GestureDetector(
            onTap: () {
              widget.onClick();
            },
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(15.0),
              dashPattern: [0.1],
              padding: EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    //padding: const EdgeInsets.all(3.0),
                    child: Stack(children: [
                      Center(
                        child: AnimatedContainer(
                            duration: Duration(milliseconds: 233),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(0.0),
                                color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 12.0),
                            child: Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 17.0),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.black,
                                  size: 16.0,
                                )
                              ],
                            )),
                      )
                    ])),
              ),
            )));
  }
}
