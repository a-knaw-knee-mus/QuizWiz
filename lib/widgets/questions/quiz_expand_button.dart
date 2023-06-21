import 'package:flutter/material.dart';
import 'package:flutter_quizzer/main.dart';
import 'package:flutter_quizzer/util/color_types.dart';
import 'package:provider/provider.dart';

class QuizExpandButton extends StatelessWidget {
  final Widget card;

  const QuizExpandButton({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    MaterialColor themeColor =
        context.watch<ColorProvider>().color.getColorSwatch();

    return Stack(
      children: <Widget>[
        card,
        Container(
          alignment: Alignment.bottomRight,
          padding: const EdgeInsets.only(bottom: 6, right: 12),
          child: IconButton(
            iconSize: 30,
            onPressed: () => print('clicked'),
            icon: Icon(
              Icons.fullscreen_rounded,
              color: themeColor[800],
            ),
          ),
        ),
      ],
    );
  }
}
