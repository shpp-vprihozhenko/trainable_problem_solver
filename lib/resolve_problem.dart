import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:trainable_problem_solver/globals.dart';

class ResolveProblem extends StatefulWidget {
  final Problem problem;
  const ResolveProblem({Key? key, required this.problem}) : super(key: key);

  @override
  State<ResolveProblem> createState() => _ResolveProblemState();
}

class _ResolveProblemState extends State<ResolveProblem> {
  List <Solution> solutions = [];
  late Solution curSolution, prevSolution;
  String prevYesNo = '';

  @override
  void initState() {
    super.initState();
    solutions = widget.problem.solutions;
    curSolution = solutions[widget.problem.startId];
    printD(solutions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.problem.name),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            curSolution.question == ''?
              const Text('Probably problem', textScaleFactor: 1.2,)
            :
              const Text('Do you have', textScaleFactor: 1.2,)
            ,
            const SizedBox(height: 16,),
            curSolution.question == ''?
            Text('${curSolution.answer} ?', textScaleFactor: 1.25,)
                :
            Text('${curSolution.question}?', textScaleFactor: 1.25)
            ,
            const SizedBox(height: 30,),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[100]
                  ),
                  onPressed: _yes,
                  child: const Text('YES',
                    style: TextStyle(
                      color: Colors.blueAccent
                    ),)
                ),
                const SizedBox(width: 80,),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent[100]
                  ),
                  onPressed: _no,
                  child: const Text('NO')
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _yes() async {
    printD('yes');
    if (curSolution.question != '') {
      prevSolution = curSolution;
      int idx = solutions.indexWhere((element) => element.id == curSolution.nestYes);
      curSolution = solutions[idx];
      printD('prevSolution $prevSolution curSolution $curSolution');
      setState(() {});
      prevYesNo = 'yes';
    } else {
      Future.delayed(const Duration(seconds: 2), (){
        try {
          Navigator.pop(context);
        } catch (e) {}
      });
      await glShowAlertPage(context, 'Ok, problem solved!');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _no() async {
    printD('no');
    if (curSolution.question != '') {
      prevSolution = curSolution;
      int idx = solutions.indexWhere((element) => element.id == curSolution.nestNo);
      curSolution = solutions[idx];
      printD('prevSolution $prevSolution curSolution $curSolution');
      prevYesNo = 'no';
    } else {
      var result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => EnterNewNodeData(curSolution: curSolution,)),
      );
      if (result == null) {
        return;
      }
      Solution newAnswer = Solution(solutions.length, '', result["newAnswer"], -1, -1);
      solutions.add(newAnswer);
      Solution newQuestion = Solution(solutions.length, result["newQuestion"], '', newAnswer.id, curSolution.id);
      solutions.add(newQuestion);
      if (solutions.length > 3) {
        if (prevYesNo == 'yes') {
          prevSolution.nestYes = newQuestion.id;
        } else {
          prevSolution.nestNo = newQuestion.id;
        }
      }
      printD(solutions);

      widget.problem.solutions = solutions;
      if (solutions.length == 3) {
        widget.problem.startId = 2;
      }
      _saveNewSolutions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('saved'),
        ));
        Navigator.pop(context);
      }
    }
    setState(() {});
  }

  void _saveNewSolutions() async {
    await glSaveNewSolutions(widget.problem.name, solutions);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

}

class EnterNewNodeData extends StatefulWidget {
  final Solution curSolution;
  const EnterNewNodeData({Key? key, required this.curSolution}) : super(key: key);

  @override
  State<EnterNewNodeData> createState() => _EnterNewNodeDataState();
}

class _EnterNewNodeDataState extends State<EnterNewNodeData> {
  TextEditingController tecWho = TextEditingController();
  TextEditingController tecDiff = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Correct solution...'),),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sorry, I have not correct solution', textScaleFactor: 1.25,),
            const SizedBox(height: 16,),
            const Text('Write me please if you got it', textScaleFactor: 1.3,),
            Container(
              margin: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
              padding: const EdgeInsets.only(left: 16, right: 16,),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  border: Border.all()
              ),
              child: TextField(
                controller: tecWho,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12,),
            const Text('and why do you know it\'s not a', textScaleFactor: 1.25,),
            const SizedBox(height: 12,),
            Text('${widget.curSolution.answer} ?', textScaleFactor: 1.4,),
            const SizedBox(height: 12,),
            Container(
              margin: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
              padding: const EdgeInsets.only(left: 16, right: 16,),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  border: Border.all()
              ),
              child: TextField(
                controller: tecDiff,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30,),
            ElevatedButton(
                onPressed: (){
                  if (tecDiff.text.isEmpty) {
                    return;
                  }
                  if (tecWho.text.isEmpty) {
                    return;
                  }
                  Navigator.pop(context, {"newAnswer": tecWho.text, "newQuestion": tecDiff.text});
                },
                child: const Text('OK')
            )
          ],
        ),
      ),
    );
  }
}
