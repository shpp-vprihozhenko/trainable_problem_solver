import 'package:flutter/material.dart';
import 'package:trainable_problem_solver/globals.dart';

class ShowProblemTree extends StatefulWidget {
  final Problem problem;
  const ShowProblemTree({Key? key, required this.problem}) : super(key: key);


  @override
  State<ShowProblemTree> createState() => _ShowProblemTreeState();
}

class PositionedSolution {
  Solution solution = Solution(-1, '', '', -1, -1);
  Offset pos = const Offset(0, 0);
  bool isAnswer = false;
  String direction = '';

  PositionedSolution(this.solution, this.pos, this.isAnswer, this.direction);

  @override
  String toString() {
    return 'sol id ${solution.id} ${solution.question}/${solution.answer} pos $pos yes|no ${solution.nestYes}/${solution.nestNo}';
  }
}

class _ShowProblemTreeState extends State<ShowProblemTree> {
  double fieldWidth=0, fieldHeight=0;
  List <PositionedSolution> posSolutions = [];
  double xOffset = 99999999, yOffset = 60;

  @override
  void initState() {
    super.initState();
    _fillPosSolutions();
  }

  @override
  Widget build(BuildContext context) {
    AppBar appB = AppBar(title: GestureDetector(
      onTap: _fillPosSolutions,
      child: const Text('Solutions tree')),
    );
    Size size = MediaQuery.of(context).size;
    fieldWidth = size.width;
    if (xOffset == 99999999) {
      xOffset = fieldWidth/2;
    }
    fieldHeight = size.height - MediaQuery.of(context).padding.top - appB.preferredSize.height;
    return Scaffold(
      appBar: appB,
      body: GestureDetector(
        onPanUpdate: (d) {
          xOffset+=d.delta.dx;
          yOffset+=d.delta.dy;
          setState(() {});
        },
        child: Container(
          width: fieldWidth, height: fieldHeight,
          color: Colors.greenAccent[100],
          child: Stack(
            children: fieldObjectsWL(),
          ),
        ),
      ),
    );
  }

  List <Widget> fieldObjectsWL() {
    List <Widget> wl = [];
    for (var element in posSolutions) {
      wl.add(Positioned(
        left: element.pos.dx+xOffset, top: element.pos.dy+yOffset,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(35)),
            color: element.solution.question.isEmpty? Colors.greenAccent : Colors.yellowAccent,
          ),
          width: 70, height: 70,
          child: Center(
            child: Text(element.solution.question + element.solution.answer, textAlign: TextAlign.center,)
          ),
        ),
      ));
      if (element.solution.nestYes > -1) {
        PositionedSolution yPS = _findPosSolBySolId(element.solution.nestYes);
        Offset nextYesPos = yPS.pos;
        double width = element.pos.dx - nextYesPos.dx - 35;
        double height = nextYesPos.dy - element.pos.dy - 35;
        wl.add(
            Positioned(
              left: nextYesPos.dx + xOffset + 35, top: element.pos.dy + yOffset + 35,
              child: Container(
                width: width, height: height,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.blueAccent, width: 3), left: BorderSide(color: Colors.blueAccent, width: 3))
                ),
              ),
            )
        );
      }
      if (element.solution.nestNo > -1) {
        PositionedSolution nPS = _findPosSolBySolId(element.solution.nestNo);
        Offset nextNoPos = nPS.pos;
        double width = nextNoPos.dx - element.pos.dx - 35;
        double height = nextNoPos.dy - element.pos.dy - 35;
        wl.add(
            Positioned(
              left: element.pos.dx + xOffset + 70, top: element.pos.dy + yOffset + 35,
              child: Container(
                width: width, height: height,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.blueAccent, width: 3),
                      right: BorderSide(color: Colors.blueAccent, width: 3))
                ),
              ),
            )
        );
      }
    }
    return wl;
  }

  _fillPosSolutions() {
    posSolutions = [];
    List <Solution> solutions = widget.problem.solutions;
    if (solutions.length < 3) {
      posSolutions.add(PositionedSolution(solutions[0], const Offset(0,0), true, ''));
      setState(() {});
      return;
    }
    posSolutions.add(PositionedSolution(solutions[2], const Offset(0,0), false, ''));
    _addPosSolForNests(posSolutions[0]);

    printD('got posSolutions $posSolutions');
    setState(() {});
  }

  void _addPosSolForNests(PositionedSolution parentPosSolution) {
    printD('_addPosSolForNests $parentPosSolution');
    double y = parentPosSolution.pos.dy + 100;
    double shift = 60;
    if (y < 200) {
      shift += 100;
    }
    printD('shift $shift');
    if (parentPosSolution.solution.nestYes != -1) {
      Solution yesSol = _findSolById(parentPosSolution.solution.nestYes);
      double x = parentPosSolution.pos.dx - shift ;
      PositionedSolution p = PositionedSolution(yesSol, Offset(x,y), yesSol.question.isEmpty, 'yes');
      posSolutions.add(p);
      printD('added yes p $p');
      if (yesSol.question.isNotEmpty) {
        _addPosSolForNests(posSolutions[posSolutions.length-1]);
      }
    }
    if (parentPosSolution.solution.nestNo != -1) {
      Solution noSol = _findSolById(parentPosSolution.solution.nestNo);
      double x = parentPosSolution.pos.dx + shift;
      PositionedSolution p = PositionedSolution(noSol, Offset(x,y), noSol.question == '', 'no');
      posSolutions.add(p);
      printD('added no sol p $p');
      if (noSol.question.isNotEmpty) {
        _addPosSolForNests(posSolutions[posSolutions.length-1]);
      }
    }
  }

  Solution _findSolById(int id) {
    int idx = widget.problem.solutions.indexWhere((solution) => solution.id == id);
    return widget.problem.solutions[idx];
  }

  PositionedSolution _findPosSolBySolId(int id) {
    int idx = posSolutions.indexWhere((posSol) => posSol.solution.id == id);
    return posSolutions[idx];
  }

}
