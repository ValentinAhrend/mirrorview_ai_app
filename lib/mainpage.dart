import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mirror_view/components.dart';
import 'package:mirror_view/cv_analysis.dart';
import 'package:mirror_view/functions.dart';
import 'package:mirror_view/general_questions.dart';
import 'package:mirror_view/setting.dart';
import 'package:mirror_view/simulate_interview.dart';
import 'package:mirror_view/store_and_profile.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool welcomeOpacity = false;
  bool topBarOpacity = false;
  bool mainPageVisible = false;
  bool loaderVisible = false;

  bool isLoading = false;

  int dialogPos = 0;

  var currentColors = [
    Colors.cyan,
    const Color.fromRGBO(66, 167, 239, 1.0),
    const Color.fromRGBO(85, 131, 239, 1.0)
  ];

  ScrollController mainController = ScrollController();

  void checkCurrentAppState() async {
    /// checking if an introduction is needed and changing state values
    if (await introNeeded()) {
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          welcomeOpacity = true;
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          mainPageVisible = true;
          topBarOpacity = true;
        });
      });
    }
  }

  void startLoadingAnimation() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!isLoading) {
        timer.cancel();
      }

      /// change positions of colors
      List<Color> nextColors = [];
      for (var i = 0; i < currentColors.length; i++) {
        if (i == 0) {
          nextColors.add(currentColors[i]);
          continue;
        }
        nextColors.insert(i - 1, currentColors[i]);
      }
      setState(() {
        currentColors = nextColors;
      });
    });
  }

  void startLoading() {
    if (isLoading) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    //print("startLoading");
    startLoadingAnimation();
    fetchUserAccount().then((data) async {
      /// wait (cool animation)
      ///
      await Future.delayed(const Duration(milliseconds: 2500));

      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    checkCurrentAppState();
    mainController.addListener(() {
      //print(mainController.offset);
      if (mainController.offset < -50) {
        if (!loaderVisible) {
          startLoading();
          setState(() {
            loaderVisible = true;
            isLoading = true;
          });
        }
      } else {
        if (loaderVisible) {
          setState(() {
            loaderVisible = false;
          });
        }
      }
    });

    /// fetch user data
    startLoading();
  }

  @override
  void dispose() {
    mainController.dispose();
    setState(() {
      isLoading = false;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            child: mainPageVisible
                ? Flex(
                    direction: Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedOpacity(
                          opacity: topBarOpacity ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 333),
                          child: Container(
                              decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [
                                        Color.fromRGBO(113, 80, 238, 0.7),
                                        Color.fromRGBO(46, 205, 240, 0.7)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      stops: [-0.2, 1.2]),
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(12.0),
                                      bottomRight: Radius.circular(12.0))),
                              child: Flex(direction: Axis.vertical, children: [
                                Container(
                                  height: 64,
                                ),
                                Flex(
                                  direction: Axis.horizontal,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context, _createSettingsRoute());
                                        },
                                        child: Icon(
                                          Icons.settings,
                                          color: Colors.black,
                                        )),
                                    SvgPicture.asset(
                                      'assets/logo400x128.svg',
                                      semanticsLabel: 'MirrorView Logo',
                                      width: 150.0,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) =>
                                                        const InfoDialog())
                                            .then((x) => {finishIntro()});
                                      },
                                      child: Container(
                                          child: const Icon(
                                        Icons.info_outline,
                                        color: Colors.black,
                                      )),
                                    )
                                  ],
                                ),
                                Container(
                                  height: 16,
                                ),
                              ]))),
                      Container(
                          child: Stack(children: [
                        Positioned(
                            top: 20.0,
                            left: 0.0,
                            right: 0.0,
                            child: Center(
                              child: SizedBox(
                                  width: 300.0,
                                  height: 50.0,
                                  child: AnimatedOpacity(
                                      opacity: loaderVisible ? 1.0 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 333),
                                      child: const Center(
                                          child: Text("Loading...")))),
                            )),
                        SizedBox(
                            height: getSafeHeight(context) - 16,
                            child: SingleChildScrollView(
                                controller: mainController,
                                scrollDirection: Axis.vertical,
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Container(
                                    padding: const EdgeInsets.only(
                                        top: 32.0, left: 20.0, right: 20.0),
                                    child: Flex(
                                      direction: Axis.vertical,
                                      children: [
                                        InterestingButton(
                                            title: 'Simulate Interview',
                                            des:
                                                'Speak to an AI interviewer with personal data and specific knowledge.',
                                            mainColor: currentColors[0],
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const SimulateInterview()));
                                            }),
                                        const FlexSpacer(height: 12.0),
                                        InterestingButton(
                                            title: 'General Questions',
                                            des:
                                                'Answer the 100 most common open questions in interviews.',
                                            mainColor: currentColors[1],
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const GeneralQuestionsPage()));
                                            }),
                                        const FlexSpacer(height: 12.0),
                                        InterestingButton(
                                            title: 'Resumé Interrogation',
                                            des:
                                                'Respond to questions about your resume.',
                                            mainColor: currentColors[2],
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const Interro()));
                                            }),
                                        const FlexSpacer(height: 24.0),
                                        const SizedBox(
                                          width: 253.0,
                                          child: Center(
                                            child: Divider(),
                                          ),
                                        ),
                                        const FlexSpacer(height: 24.0),
                                        CoolButton(
                                            onClick: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const Store()));
                                            },
                                            title: "Conversations & Feedbacks"),
                                        const FlexSpacer(height: 18.0),
                                        CoolButton(
                                            onClick: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const ProfilePage()));
                                            },
                                            title: "Profile & Data"),
                                        
                                      ],
                                    ))))
                      ]))
                    ],
                  )
                : Center(
                    child: AnimatedOpacity(
                        opacity: welcomeOpacity ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 333),
                        child: Flex(
                          direction: Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Welcome to",
                              style: TextStyle(
                                  color: Colors.black, fontSize: 24.0),
                            ),
                            SvgPicture.asset(
                              'assets/logo400x128.svg',
                              semanticsLabel: 'MirrorView Logo',
                              width: 350.0,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  welcomeOpacity = false;
                                  mainPageVisible = true;
                                });
                                Future.delayed(const Duration(milliseconds: 50),
                                    () {
                                  setState(() {
                                    topBarOpacity = true;
                                  });
                                });
                                Future.delayed(
                                    const Duration(milliseconds: 500), () {
                                  showDialog(
                                          context: context,
                                          builder: ((BuildContext context) =>
                                              const InfoDialog()))
                                      .then((x) => {finishIntro()});
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(top: 40.0),
                                width: 300.0,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    gradient: const LinearGradient(
                                        colors: [
                                          Color.fromRGBO(113, 80, 238, 1.0),
                                          Color.fromRGBO(46, 205, 240, 1.0)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        stops: [-0.2, 1.2])),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 32.0),
                                child: const Center(
                                  child: Text(
                                    "Continue",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ),
          ),
        ));
  }
}

Route _createSettingsRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const Settings(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}