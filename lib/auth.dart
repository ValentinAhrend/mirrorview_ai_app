import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SignInPage extends StatelessWidget {
  final FirebaseApp firebaseApp;

  SignInPage({super.key, required this.firebaseApp});

  final myController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    /// building a nice looking UI that includes the main logo, the possiblity to sign in with Google
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
            child: AuthElement(
          firebaseApp: firebaseApp,
        )),
      ),
    );
  }
}

class AuthElement extends StatefulWidget {
  final FirebaseApp firebaseApp;
  const AuthElement({super.key, required this.firebaseApp});

  @override
  State<AuthElement> createState() => _AuthElementState();
}

class _AuthElementState extends State<AuthElement> {
  /// 0 -> sign in
  /// 1 -> create user
  /// 2 -> forgot password
  int currentState = 0;

  Widget? getRealElements() {
    if (currentState == 0) {
      return Flex(
        direction: Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/logo400x128.svg',
            semanticsLabel: 'MirrorView Logo',
            width: 350.0,
          ),
          SvgPicture.asset(
            'assets/des300x40.svg',
            semanticsLabel: 'Master your interview',
            width: 300.0,
          ),
          Container(
            height: 32.0,
          ),
          SignInElements(
            app: widget.firebaseApp,
            forgotPassword: () {
              setState(() {
                currentState = 2;
              });
            },
            createUser: () {
              setState(() {
                currentState = 1;
              });
            },
          )
        ],
      );
    }
    if (currentState == 2) {
      return Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/logo400x128.svg',
                  semanticsLabel: 'MirrorView Logo',
                  width: 100.0,
                ),
                SvgPicture.asset(
                  'assets/des300x40.svg',
                  semanticsLabel: 'Master your interview',
                  width: 120.0,
                )
              ],
            ),
            const Spacer(),
            const Text(
              "Forgot your password",
              style: TextStyle(color: Colors.black, fontSize: 24.0),
            ),
            const Text(
              "We will send you reset link to your email address.",
              style: TextStyle(color: Colors.grey, fontSize: 16.0),
            ),
            ForgotPWD(
              goToSignIn: () {
                setState(() {
                  currentState = 0;
                });
              },
            ),
            const Spacer()
          ]);
    }
    if (currentState == 1) {
      return Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/logo400x128.svg',
                  semanticsLabel: 'MirrorView Logo',
                  width: 100.0,
                ),
                SvgPicture.asset(
                  'assets/des300x40.svg',
                  semanticsLabel: 'Master your interview',
                  width: 120.0,
                )
              ],
            ),
            const Spacer(),
            const Text(
              "Create new account",
              style: TextStyle(color: Colors.black, fontSize: 24.0),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 4.0),
              child: Center(
                child: RichText(
                    text: TextSpan(
                        text: "By creating your account you agree to our ",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16.0),
                        children: [
                      TextSpan(
                          text: "Terms of service",
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16.0,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.grey),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              final Uri url =
                                  Uri.parse('https://mirrorview-ai.web.app/terms');
                              launchUrl(url);
                            }),
                      const TextSpan(
                        text: ".",
                        style: TextStyle(color: Colors.grey, fontSize: 16.0),
                      )
                    ])),
              ),
            ),
            CreateUser(goToSignIn: () {
              setState(() {
                currentState = 0;
              });
            }),
            const Spacer()
          ]);
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Container(
          height: 550.0,
          width: 400.0,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
          decoration: kIsWeb
              ? BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600, width: 1.0),
                  borderRadius: BorderRadius.circular(12.0))
              : const BoxDecoration(),
          child: getRealElements()),
    );
  }
}

class CreateUser extends StatefulWidget {
  final Function goToSignIn;
  const CreateUser({super.key, required this.goToSignIn});

  @override
  State<CreateUser> createState() => _CreateUserState();
}

class _CreateUserState extends State<CreateUser> {
  final emailController = TextEditingController();
  final pwdController = TextEditingController();
  final pwdController2 = TextEditingController();

  bool textIsObscured2 = true;
  bool textIsObscured = true;
  String errorText = "";

  bool isLoading = false;
  bool isSuccess = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    emailController.dispose();
    pwdController.dispose();
    pwdController2.dispose();

    super.dispose();
  }

  void createUser(email, pwd, pwd2) async {
    setState(() {
      errorText = "";
      isLoading = true;
    });
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    if (!emailValid) {
      setState(() {
        errorText = "The entered email address is malformatted.";
        isLoading = false;
      });
      return;
    }
    if (pwd != pwd2) {
      setState(() {
        textIsObscured = false;
        textIsObscured2 = false;
        errorText = "Plase enter your new password twice.";
        isLoading = false;
      });
      return;
    }
    final bool validPwd = pwd.length > 7;
    if (!validPwd) {
      setState(() {
        errorText =
            "The entered password has to be at least 8 characters long.";
        isLoading = false;
      });
      return;
    }
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pwd);
      setState(() {
        isLoading = false;
        isSuccess = true;
      });
      return;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          errorText = "The email address already belongs to another account.";
          isLoading = false;
        });
        return;
      }
      if (e.code == 'invalid-email') {
        setState(() {
          errorText = "The entered email adress is not valid.";
          isLoading = false;
        });
        return;
      }
      if (e.code == 'weak-password') {
        setState(() {
          errorText =
              "Your password is not strong enough. Please choose a stronger password.";
          isLoading = false;
        });
        return;
      }
      setState(() {
        errorText = "Something went wrong. Please try later again.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: TextFormField(
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      const BorderSide(color: Colors.black, width: 1.0)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade300, width: 1.0)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade600, width: 1.0)),
              labelText: "Email Address",
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 16.0),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: TextFormField(
            obscureText: textIsObscured,
            controller: pwdController,
            decoration: InputDecoration(
              suffixIcon: GestureDetector(
                child: Icon(
                    textIsObscured ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onTap: () => {
                  setState(() {
                    textIsObscured = !textIsObscured;
                  })
                },
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      const BorderSide(color: Colors.black, width: 1.0)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade300, width: 1.0)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade600, width: 1.0)),
              labelText: "Password",
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 16.0),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(bottom: errorText.isEmpty ? 32.0 : 12.0),
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: TextFormField(
            obscureText: textIsObscured2,
            controller: pwdController2,
            decoration: InputDecoration(
              suffixIcon: GestureDetector(
                child: Icon(
                    textIsObscured2 ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onTap: () => {
                  setState(() {
                    textIsObscured2 = !textIsObscured2;
                  })
                },
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      const BorderSide(color: Colors.black, width: 1.0)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade300, width: 1.0)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade600, width: 1.0)),
              labelText: "Confirm Password",
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 16.0),
            ),
          ),
        ),
        Container(
          width: 300.0,
          margin: errorText.isEmpty
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 18.0),
          child: errorText.isEmpty
              ? Container()
              : Text(
                  errorText,
                  style: const TextStyle(color: Colors.red, fontSize: 14.0),
                ),
        ),
        GestureDetector(
          onTap: () {
            if (isLoading) {
              return;
            }
            setState(() {
              isLoading = true;
              isSuccess = false;
            });
            createUser(
                emailController.text, pwdController.text, pwdController2.text);
          },
          child: Container(
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
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
            child: Center(
              child: Text(
                isSuccess
                    ? ("Success!")
                    : (isLoading ? "Loading..." : "Create new account"),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            widget.goToSignIn();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
            child: const Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Go back to Sign In",
                  style: TextStyle(color: Colors.grey, fontSize: 16.0),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}

class SignInElements extends StatefulWidget {
  final FirebaseApp app;
  final Function forgotPassword;
  final Function createUser;
  const SignInElements(
      {super.key,
      required this.app,
      required this.forgotPassword,
      required this.createUser});

  @override
  State<SignInElements> createState() => _SignInElementsState();
}

class _SignInElementsState extends State<SignInElements> {
  final emailController = TextEditingController();
  final pwdController = TextEditingController();

  bool textIsObscured = true;
  String errorText = "";

  bool isLoading = false;
  bool isSuccess = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    emailController.dispose();
    pwdController.dispose();

    super.dispose();
  }

  void trySignIn(String email, String pwd) async {
    setState(() {
      errorText = "";
    });
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    if (!emailValid) {
      setState(() {
        errorText = "The entered email address is malformatted.";
        isLoading = false;
      });
      return;
    }
    final bool validPwd = pwd.length > 7;
    if (!validPwd) {
      setState(() {
        errorText =
            "The entered password has to be at least 8 characters long.";
        isLoading = false;
      });
      return;
    }
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pwd);
      setState(() {
        isLoading = false;
        isSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        setState(() {
          isLoading = false;
          errorText = "User with given credentials was not found.";
        });
      } else if (e.code == 'wrong-password') {
        setState(() {
          isLoading = false;
          errorText = "The given password is incorrect.";
        });
      } else {
        setState(() {
          isLoading = false;
          errorText = "Something went wrong. Try later again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: TextFormField(
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      const BorderSide(color: Colors.black, width: 1.0)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade300, width: 1.0)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade600, width: 1.0)),
              labelText: "Email Address",
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 16.0),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: TextFormField(
            obscureText: textIsObscured,
            controller: pwdController,
            decoration: InputDecoration(
              suffixIcon: GestureDetector(
                child: Icon(
                    textIsObscured ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onTap: () => {
                  setState(() {
                    textIsObscured = !textIsObscured;
                  })
                },
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      const BorderSide(color: Colors.black, width: 1.0)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade300, width: 1.0)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade600, width: 1.0)),
              labelText: "Password",
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 16.0),
            ),
          ),
        ),
        GestureDetector(
            onTap: () {
              widget.forgotPassword();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
              margin: EdgeInsets.only(bottom: errorText.isEmpty ? 32.0 : 12.0),
              child: const Center(
                child: Text(
                  "Forgot Password",
                  style: TextStyle(color: Colors.black, fontSize: 16.0),
                ),
              ),
            )),
        Container(
          width: 300.0,
          margin: errorText.isEmpty
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 18.0),
          child: errorText.isEmpty
              ? Container()
              : Text(
                  errorText,
                  style: const TextStyle(color: Colors.red, fontSize: 14.0),
                ),
        ),
        GestureDetector(
          onTap: () {
            if (isLoading) {
              return;
            }
            setState(() {
              isLoading = true;
            });
            trySignIn(emailController.text, pwdController.text);
          },
          child: Container(
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
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
            child: Center(
              child: Text(
                isSuccess
                    ? ("Success!")
                    : (isLoading ? "Loading..." : "Sign In"),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            widget.createUser();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
            child: const Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Create new account",
                  style: TextStyle(color: Colors.grey, fontSize: 16.0),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}

class ForgotPWD extends StatefulWidget {
  final Function goToSignIn;
  const ForgotPWD({super.key, required this.goToSignIn});

  @override
  State<ForgotPWD> createState() => _ForgotPWDState();
}

class _ForgotPWDState extends State<ForgotPWD> {
  final emailController = TextEditingController();

  String errorText = "";

  bool isLoading = false;
  bool isSuccess = false;

  void resetPwd(email) async {
    setState(() {
      errorText = "";
    });
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    if (!emailValid) {
      setState(() {
        errorText = "The entered email address is malformatted.";
        isLoading = false;
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        isLoading = false;
        isSuccess = true;
        //widget.goToSignIn();
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        setState(() {
          errorText = "The entered email address is malformatted.";
          isLoading = false;
        });
        return;
      }
      if (e.code == 'user-not-found') {
        setState(() {
          errorText = "No user was found with this email adress.";
          isLoading = false;
        });
        return;
      }
      setState(() {
        errorText = "Something went wrong: ${e.code}. Please try later again.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          margin: EdgeInsets.only(
              bottom: errorText.isEmpty ? 20.0 : 12.0, top: 16.0),
          child: TextFormField(
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      const BorderSide(color: Colors.black, width: 1.0)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade300, width: 1.0)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      BorderSide(color: Colors.red.shade600, width: 1.0)),
              labelText: "Email Address",
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 16.0),
            ),
          ),
        ),
        Container(
          padding: errorText.isEmpty
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
          child: Center(
              child: Text(
            errorText,
            style: const TextStyle(color: Colors.red, fontSize: 14.0),
          )),
        ),
        GestureDetector(
          onTap: () {
            if (isLoading) {
              return;
            }
            setState(() {
              isLoading = true;
            });
            resetPwd(emailController.text);
          },
          child: Container(
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
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
            child: Center(
              child: Text(
                isSuccess
                    ? ("Success!")
                    : (isLoading ? "Loading..." : "Reset your password"),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            widget.goToSignIn();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
            child: const Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Go back to Sign In",
                  style: TextStyle(color: Colors.grey, fontSize: 16.0),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}
