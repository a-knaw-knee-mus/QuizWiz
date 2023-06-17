import 'package:flutter/material.dart';
import 'package:flutter_quizzer/schema/question.dart';
import 'package:flutter_quizzer/schema/quiz.dart';
import 'package:flutter_quizzer/screens/quiz_dialog_screen.dart';
import 'package:flutter_quizzer/screens/questions_screen.dart';
import 'package:flutter_quizzer/types/form_types.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  final quizBox = Hive.box<Quiz>('quizBox');

  void saveQuiz(
    String quizName,
    String quizDesc, {
    String? quizId,
    DateTime? ogCreatedAt,
  }) {
    String uuid;
    DateTime createdAt = DateTime.now();

    if (quizId == null) {
      uuid = const Uuid().v1();
    } else {
      uuid = quizId;
    }

    if (ogCreatedAt != null) {
      createdAt = ogCreatedAt;
    }

    setState(() {
      quizBox.put(
        uuid,
        Quiz(
          name: quizName,
          description: quizDesc,
          createdAt: createdAt,
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  void deleteQuiz(String quizId) {
    setState(() {
      quizBox.delete(quizId);
      final questionBox = Hive.box<Question>('questionBox');
      for (String key in questionBox.keys) {
        if (questionBox.get(key)!.quizId == quizId) {
          questionBox.delete(key);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Quiz deleted!',
        ),
        duration: Duration(
          milliseconds: 1500,
        ),
        showCloseIcon: true,
        backgroundColor: Colors.red,
      ),
    );
  }

  void showQuizDialog(FormType dialogType, {String? quizId, Quiz? quiz}) {
    showDialog(
      context: context,
      builder: (context) {
        return QuizDialog(
          saveQuiz: saveQuiz,
          context: context,
          formType: dialogType,
          quiz: quiz,
          quizId: quizId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Quizzes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('New Quiz'),
        icon: const Icon(Icons.add),
        onPressed: () {
          showQuizDialog(FormType.create);
        },
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      body: ListView.builder(
        itemCount: quizBox.length,
        itemBuilder: (context, index) {
          final quizId = quizBox.keyAt(index)!;
          final quiz = quizBox.getAt(index)!;

          return Padding(
            padding: const EdgeInsets.only(top: 20.0, right: 20.0, left: 20.0),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const StretchMotion(),
                extentRatio: 0.3,
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      deleteQuiz(quizId);
                    },
                    icon: Icons.delete,
                    backgroundColor: Colors.red.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      showQuizDialog(
                        FormType.edit,
                        quiz: quiz,
                        quizId: quizId,
                      );
                    },
                    icon: Icons.edit,
                    backgroundColor: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (BuildContext context) {
                        return QuizScreen(quizId: quizId);
                      }),
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  tileColor: Colors.purpleAccent,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded),
                  title: Text(quiz.name),
                  subtitle: Text(
                      '${quiz.description} - ${quiz.createdAt} - ${quiz.updatedAt}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
