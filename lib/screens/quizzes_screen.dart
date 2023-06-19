import 'package:flutter/material.dart';
import 'package:flutter_quizzer/schema/question.dart';
import 'package:flutter_quizzer/schema/quiz.dart';
import 'package:flutter_quizzer/screens/quiz_dialog_screen.dart';
import 'package:flutter_quizzer/util/form_types.dart';
import 'package:flutter_quizzer/util/sort_quiz.dart';
import 'package:flutter_quizzer/widgets/quizzes/quiz_sort_dropdown.dart';
import 'package:flutter_quizzer/widgets/quizzes/quiz_tile.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  final quizBox = Hive.box<Quiz>('quizBox');
  QuizSortType sortType = QuizSortType.nameAsc;

  void saveNewQuiz(
    String name,
    String desc,
  ) {
    setState(() {
      quizBox.put(
        const Uuid().v1(),
        Quiz(
          name: name,
          description: desc,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  void editQuiz(
    String name,
    String desc,
    String quizId,
    DateTime ogCreatedAt,
  ) {
    setState(() {
      quizBox.put(
        quizId,
        Quiz(
          name: name,
          description: desc,
          createdAt: ogCreatedAt,
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  void deleteQuiz(String quizId) {
    setState(() {
      quizBox.delete(quizId);
      // cascade delete
      final questionBox = Hive.box<Question>('questionBox');
      for (String key in questionBox.keys) {
        if (questionBox.get(key)!.quizId == quizId) {
          questionBox.delete(key);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Quiz deleted!',
          style: GoogleFonts.jost(),
        ),
        duration: const Duration(
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
          context: context,
          saveNewQuiz: saveNewQuiz,
          editQuiz: editQuiz,
          formType: dialogType,
          quizId: quizId,
          quiz: quiz,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quizzer!',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: QuizSortDropdown(
                sortType: sortType,
                onChanged: (QuizSortType newSortType) {
                  setState(() {
                    sortType = newSortType;
                  });
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text(
          'New Quiz',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        icon: const Icon(Icons.add),
        onPressed: () {
          showQuizDialog(FormType.create);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: ValueListenableBuilder(
          valueListenable: Hive.box<Quiz>('quizBox').listenable(),
          builder: (context, quizzes, _) {
            final List sortedIds = sortType.sortQuizIds(quizzes);
            return ListView.builder(
              itemCount: sortedIds.length,
              itemBuilder: (context, index) {
                final quizId = sortedIds[index];
                final quiz = quizzes.get(quizId)!;
                final questionBox = Hive.box<Question>('questionBox');
                int quizSize = questionBox.values.where((question) {
                  return question.quizId == quizId;
                }).length;

                void modifyCount(int change) {
                  setState(() {
                    quizSize += change;
                  });
                }

                return Padding(
                  padding: const EdgeInsets.only(
                    top: 20.0,
                    right: 60.0,
                  ),
                  child: Slidable(
                    startActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.3,
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            deleteQuiz(quizId);
                          },
                          icon: Icons.delete,
                          backgroundColor: Colors.red,
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
                        ),
                      ],
                    ),
                    child: QuizTile(
                      quiz: quiz,
                      quizId: quizId,
                      modifyCount: modifyCount,
                      quizSize: quizSize,
                    ),
                  ),
                );
              },
            );
          }),
    );
  }
}
