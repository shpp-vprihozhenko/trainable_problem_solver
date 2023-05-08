import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String idEkz = '';

class Solution {
  int id = -1;
  String question = '', answer='';
  int nestYes = -1, nestNo = -1;

  Solution(this.id, this.question, this.answer, this.nestYes, this.nestNo);

  @override
  String toString() {
    return 'riddle id $id q $question a $answer yes $nestYes no $nestNo';
  }
}

class Problem {
  int id = -1;
  String name = '';
  List <Solution> solutions = [];
  int startId = 0;

  Problem(this.id, this.name);

  @override
  String toString() {
    return 'Problem: $name Solutions: $solutions';
  }
}

List <Problem> problems = [];

glSaveLocally(String key, String data) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(key, data);
}

glRemoveProblemLocally(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove(key);
}

glRestoreLocally(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var s = prefs.getString(key);
  return s ?? '';
}

glRestoreAllProblems() async {
  printD('glRestoreAllProblems');
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Set<String> keys = prefs.getKeys();
  problems = [];
  int counter = 0;
  for (var key in keys) {
    printD('got key $key');

    String solsS = await glRestoreLocally(key);
    //printD('got data solsS $solsS');

    if (!solsS.contains('question')) {
      printD('skip key $key');
      continue;
    }

    Problem p = Problem(counter, key);
    List <Solution> solutions = [];
    var solsO = jsonDecode(solsS);
    solsO.forEach((vSol){
      solutions.add(Solution(vSol["id"], vSol["question"], vSol["answer"], vSol["nestYes"], vSol["nestNo"]));
    });
    p.solutions = solutions;
    if (solutions.length > 1) {
      p.startId = 2;
    }
    problems.add(p);
    counter++;
  }
  printD('glRestoreAllProblems got ${problems.length}');
}

printD(text) {
  if (kDebugMode) {
    print(text);
  }
}

glShowAlertPage(context, String msg) async {
  await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SelectableText(msg, textAlign: TextAlign.center,),
        );
      }
  );
}

glPrepareSolutionsToSave(List <Solution> solutions) {
  List <Map<String, dynamic>> toSave = [];
  for (var solution in solutions) {
    toSave.add({
      "id": solution.id,
      "question": solution.question,
      "answer": solution.answer,
      "nestYes": solution.nestYes,
      "nestNo": solution.nestNo
    });
  }
  return jsonEncode(toSave);
}

glSaveNewSolutions(String problemName, List <Solution> solutions) async {
  await glSaveLocally(problemName, glPrepareSolutionsToSave(solutions));
  printD('saved');
}
