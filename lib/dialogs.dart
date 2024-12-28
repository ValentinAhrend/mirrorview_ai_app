import 'package:flutter/material.dart';
import 'package:mirror_view/components.dart';

class AreYouSure extends StatefulWidget {
  const AreYouSure(
      {super.key,
      required this.confirm,
      required this.cancel,
      required this.saveConvo,
      required this.important});

  final Function confirm;
  final Function cancel;

  final bool important;
  final Function saveConvo;

  @override
  State<AreYouSure> createState() => _AreYouSureState();
}

class _AreYouSureState extends State<AreYouSure> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: widget.important ? 180 : 140,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Are you sure?",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700),
            ),
            const Text(
              "You will not be able to continue this interview.",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.0,
              ),
            ),
            FlexSpacer(height: widget.important ? 20 : 18),
            Flex(
                direction: Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () {
                      widget.saveConvo();
                    },
                    child: widget.important
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: Colors.white,
                              border:
                                  Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: const Center(
                              child: Text(
                                "Exit & Create interview feedback",
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16),
                              ),
                            ),
                          )
                        : Container(),
                  ),
                  const FlexSpacer(height: 8),
                  Container(
                      margin: const EdgeInsets.only(bottom: 4.0),
                      child: Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                widget.cancel();
                              },
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Colors.grey.shade300),
                                child: Center(
                                  child: Text(
                                    "Continue",
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                widget.confirm();
                              },
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Colors.grey.shade700),
                                child: const Center(
                                  child: const Text(
                                    "Stop Interview",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ]))
                ])
          ],
        ),
      ),
    );
  }
}

class ConfirmDialog extends StatefulWidget {
  const ConfirmDialog(
      {super.key,
      required this.confirm,
      required this.cancel,
      required this.actionTitle,
      required this.actionDes});

  final Function confirm;
  final Function cancel;

  final String actionTitle;
  final String actionDes;

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 140,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Are you sure?",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              widget.actionDes,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14.0,
              ),
            ),
            const FlexSpacer(
              height: 18,
            ),
            Flex(
                direction: Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                      margin: const EdgeInsets.only(bottom: 4.0),
                      child: Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                widget.cancel();
                              },
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Colors.grey.shade300),
                                child: Center(
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                widget.confirm();
                              },
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Colors.grey.shade700),
                                child: Center(
                                  child: Text(
                                    widget.actionTitle,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ]))
                ])
          ],
        ),
      ),
    );
  }
}

class FinishDialog extends StatefulWidget {
  const FinishDialog(
      {super.key,
      required this.confirm,
      required this.cancel,
      required this.saveConvo,
      required this.isIm});

  final Function confirm;
  final Function cancel;

  final Function saveConvo;
  final bool isIm;

  @override
  State<FinishDialog> createState() => _FinishDialogState();
}

class _FinishDialogState extends State<FinishDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [
                    Color.fromRGBO(113, 80, 238, 1.0),
                    Color.fromRGBO(46, 205, 240, 1.0)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [-0.2, 1.2]),
              borderRadius: BorderRadius.circular(15.0)),
          child: Container(
            height: widget.isIm ? 170 : 180,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.0),
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.white),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  "Your interview is live.",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  "This conversation is saved.${widget.isIm ? "" : " After some messages you'll have the possiblity to receive a general feedback."}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14.0,
                  ),
                ),
                const FlexSpacer(height: 20),
                Flex(
                    direction: Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      widget.isIm
                          ? GestureDetector(
                              onTap: () {
                                widget.saveConvo();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: Colors.white,
                                  border: Border.all(
                                      color: Colors.grey, width: 1.5),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Save & Create interview feedback",
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 16),
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                      const FlexSpacer(height: 8),
                      GestureDetector(
                        onTap: () {
                          /// cwidget.saveConvo();
                          widget.cancel();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 16.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: Colors.grey.shade300),
                          child: Center(
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                  color: Colors.grey.shade700, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ])
              ],
            ),
          )),
    );
  }
}
