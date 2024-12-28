import 'package:firebase_auth/firebase_auth.dart';

/// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mirror_view/components.dart';
import 'package:mirror_view/functions.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  int usage = 0;

  @override
  void initState() {
    super.initState();

    /// load usage ....
    registerTokens(0).then((x) {
      setState(() {
        usage = x;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 32,
            child: GestureDetector(
                onTap: () {
                  /// Leave
                  ///

                  Navigator.pop(context);
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
          ),
          Positioned(
              top: MediaQuery.of(context).padding.top + 48,
              left: 0,
              right: 0,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Flex(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    direction: Axis.vertical,
                    children: [
                      const Flex(direction: Axis.horizontal, children: [
                        Text(
                          "Settings",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w600),
                        ),
                        Spacer()
                      ]),
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade700, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                            color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Flex(
                          direction: Axis.vertical,
                          children: [
                            Flex(
                              direction: Axis.vertical,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text("Your Usage",
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 18)),
                                Text("You have already used $usage tokens.",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                            Flex(
                              direction: Axis.horizontal,
                              children: [
                                SizedBox(
                                  width: 240,
                                  child: LinearProgressIndicator(
                                    value: usage / 1000000,
                                    color: Colors.black,
                                    backgroundColor: Colors.grey.shade300,
                                  ),
                                ),
                                const Text(
                                  " of 1mio.",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      GestureDetector(
                          onTap: () {
                            launchUrl(
                                Uri.parse("https://mirrorview-ai.web.app"));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade700, width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                                color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: const Flex(
                              direction: Axis.vertical,
                              children: [
                                Flex(
                                  direction: Axis.vertical,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Flex(
                                        direction: Axis.horizontal,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Open Webite",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18)),
                                          Icon(Icons.arrow_forward,
                                              color: Colors.black)
                                        ]),
                                    Text("mirrorview-ai.web.app",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                      GestureDetector(
                          onTap: () {
                            FirebaseAuth.instance.signOut();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade700, width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                                color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: const Flex(
                              direction: Axis.vertical,
                              children: [
                                Flex(
                                  direction: Axis.vertical,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Flex(
                                        direction: Axis.horizontal,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Log out",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18)),
                                          Icon(Icons.logout,
                                              color: Colors.black)
                                        ]),
                                    Text("Your data is saved.",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                          Flex(direction: Axis.vertical, crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                          
                          const FlexSpacer(height: 22.0),
                                        GestureDetector(
                                            onTap: () {},
                                            child: const Text("Privacy",
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                    decoration: TextDecoration
                                                        .underline))),
                                        const FlexSpacer(height: 24.0),
                                        GestureDetector(
                                            onTap: () {},
                                            child: const Text("Terms",
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                    decoration: TextDecoration
                                                        .underline))),
                                        const FlexSpacer(height: 24.0),
                                        GestureDetector(
                                            onTap: () {},
                                            child: const Text("FAQ",
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                    decoration: TextDecoration
                                                        .underline))),
                                                        ],)
                    ],
                  )))
        ]),
      ),
    );
  }
}
