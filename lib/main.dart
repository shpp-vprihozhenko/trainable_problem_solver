import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trainable_problem_solver/about.dart';
import 'globals.dart';
import 'resolve_problem.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'show_problem_tree.dart';

/*
icon
publish
 */

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Expert System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Mobile Expert System'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLocal = true;
  bool isFetching = false;
  TextEditingController tecFind = TextEditingController();
  String filterString = '';

  late FirebaseFirestore db;

  @override
  void initState() {
    super.initState();
    _startFirebase();
    if (problems.isEmpty) {
      _fillLocalProblems();
    }
    _defineIdEkz();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(widget.title)),
            IconButton(
              icon: Container(
                width: 32, height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.purpleAccent,
                    borderRadius: BorderRadius.all(Radius.circular(16))
                  ),
                  child: const Center(child: Text('?'))
              ),
              onPressed: (){
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const About()),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const SizedBox(height: 8,),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: (){
                      isLocal = true;
                      setState(() {});
                      _fillLocalProblems();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(23)),
                          color: isLocal? Colors.green[100] : Colors.white,
                          border: Border.all(color: Colors.grey)
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLocal? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            ),
                            const SizedBox(width: 12,),
                            const Text('Local',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12,),
                Expanded(
                  child: GestureDetector(
                    onTap: (){
                      isLocal = false;
                      setState(() {});
                      _getSharedProblems();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(23)),
                          color: isLocal? Colors.white : Colors.green[100],
                          border: Border.all(color: Colors.grey)
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              !isLocal? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            ),
                            const SizedBox(width: 12,),
                            const Text('Shared',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Text('Problems list',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(width: 32,),
                  Expanded(
                    child: Container(
                      //padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: const BorderRadius.all(Radius.circular(16))
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tecFind,
                              onChanged: (String s) {
                                _filterProblemList(s);
                              },
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isCollapsed: true,
                              ),
                            ),
                          ),
                          const Icon(Icons.search),
                        ],
                      ),
                  )),
                ],
              ),
            ),
            isFetching?
              const CircularProgressIndicator()
            :
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: const BorderRadius.all(Radius.circular(24))
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: problemsWL(),
                    ),
                  ),
                ),
              )
            ,
          ],
        ),
      ),
      floatingActionButton:
        isLocal?
          FloatingActionButton(
            onPressed: _addNewProblem,
            child: const Icon(Icons.add),
          )
        :
          null
        ,
    );
  }

  void _fillLocalProblems() async {
    isFetching = true;
    setState(() {});
    await glRestoreAllProblems();
    isFetching = false;
    if (problems.isEmpty) {
      _fillStartLocalProblem();
    }
    setState(() {});
  }

  void _addNewProblem() async {
    var result = await Navigator.push(context,
      MaterialPageRoute(builder: (context) => const AddNewProblem()),
    );
    if (result == null) {
      return;
    }
    printD('got result $result');
    List <Solution> solutions = [
      Solution(0, '', result["solution"], -1, -1)
    ];
    await glSaveNewSolutions(result["name"], solutions);
    Problem p = Problem(problems.length, result["name"]);
    p.solutions = solutions;
    problems.add(p);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  void _filterProblemList(String s) {
    filterString = s.trim().toLowerCase();
    setState(() {});
  }

  List <Widget> problemsWL() {
    List <Widget> wl = [];
    for (int idx=0; idx<problems.length; idx++) {
      Problem problem = problems[idx];
      if (filterString != '') {
        List <String> filterWords = filterString.split(' ');
        bool isSkip = false;
        for (int j=0; j<filterWords.length; j++) {
          if (!problem.name.toLowerCase().contains(filterWords[j])) {
            isSkip = true;
            break;
          }
        }
        if (isSkip) {
          continue;
        }
      }
      wl.add(GestureDetector(
        onTap: () async {
          var result = await Navigator.push(context,
            MaterialPageRoute(builder: (context) => ResolveProblem(problem: problem, isLocal: isLocal,)),
          );
          setState(() {});
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          color: idx%2==0? Colors.white : Colors.grey[100],
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(problem.name,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5,),
                    Text('depth: ${problem.solutions.length}',
                      style: const TextStyle(
                        color: Colors.green
                      ),
                    ),
                  ],
                )
              ),
              isLocal?
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: (){
                        _showTree(problem);
                      },
                      icon: const Icon(Icons.account_tree_outlined),
                    ),
                    IconButton(
                      onPressed: (){
                        _editProblem(problem);
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: (){
                        _delProblem(problem);
                      },
                      icon: const Icon(Icons.delete),
                    ),
                    IconButton(
                      onPressed: (){
                        _shareProblemWithSolution(problem);
                      },
                      icon: const Icon(Icons.share),
              ),
                  ],
                )
              :
                IconButton(
                    onPressed: (){
                      _saveLocally(problem);
                    },
                    icon: const Icon(Icons.download_rounded))
              ,
            ],
          ),
        ),
      ));
    }
    return wl;
  }

  void _startFirebase() async {
    printD('firebase start');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    printD('firebase started');

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      printD("Signed in with temporary account.");
      //printD('userCredential $userCredential');
      db = FirebaseFirestore.instance;
      printD('got DB of FB');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "operation-not-allowed":
          printD("Anonymous auth hasn't been enabled for this project.");
          break;
        default:
          printD("Unknown error.");
      }
    }
  }

  void _defineIdEkz() async {
    idEkz = await glRestoreLocally('idEkz');
    printD('restored idEkz $idEkz');
    if (idEkz == '') {
      _generateIdEkz();
      await glSaveLocally('idEkz', idEkz);
      printD('saved idEkz $idEkz');
    }
  }

  _generateIdEkz(){
    var rng = Random();
    String p1 = rng.nextDouble().toString().substring(2);
    int ms = DateTime.now().millisecondsSinceEpoch;
    idEkz = ms.toString()+p1;
  }

  void _shareProblemWithSolution(Problem problem) async {
    TextEditingController tecNick = TextEditingController();
    var nick = await showDialog(
        context: context,
        builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your nick please'),
              const SizedBox(height: 24,),
              TextField(
                controller: tecNick,
                decoration: const InputDecoration(
                  labelText: 'Your nick'
                ),
              ),
              const SizedBox(height: 24,),
              ElevatedButton(
                  onPressed: (){
                    Navigator.pop(context, tecNick.text);
                  },
                  child: const Text('OK')
              )
            ],
          ),
        );
    });
    if (nick == null) {
      return;
    }
    String nameToSave = '${problem.name} by $nick #@% $idEkz';
    printD('save $nameToSave');
    var data = {
      "dt": DateTime.now(),
      "solutions": glPrepareSolutionsToSave(problem.solutions)
    };

    await db.collection("problems").doc(nameToSave).set(data, SetOptions(merge: true));
    printD('saved to fb');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared')));
    }
  }

  void _getSharedProblems() async {
    problems = [];
    isFetching = true;
    setState(() {});
    var data = await db.collection("problems").get();
    for (var doc in data.docs) {
      printD("${doc.id} => ${doc.data()}");
      var docData = doc.data();
      String solsS = docData["solutions"] ?? '';
      if (solsS.isEmpty) {
        continue;
      }
      Problem p = Problem(problems.length, doc.id.split('#@%')[0]);
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
    }
    printD('got problems list from db ${problems.length}');
    isFetching = false;
    setState(() {});
  }

  void _saveLocally(Problem problem) async {
    await glSaveNewSolutions(problem.name, problem.solutions);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Local')));
    }
  }

  void _editProblem(Problem problem) async {
    TextEditingController tecName = TextEditingController();
    tecName.text = problem.name;
    var newName = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter new name please'),
                const SizedBox(height: 24,),
                TextField(
                  controller: tecName,
                  decoration: const InputDecoration(
                      labelText: 'new name...'
                  ),
                ),
                const SizedBox(height: 24,),
                ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context, tecName.text);
                    },
                    child: const Text('OK')
                )
              ],
            ),
          );
        });
    if (newName == null) {
      return;
    }
    String oldName = problem.name;
    problem.name = newName;
    setState(() {});
    await glSaveNewSolutions(problem.name, problem.solutions);
    glRemoveProblemLocally(oldName);
  }

  void _delProblem(Problem problem) async {
    var result = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Are you sure to remove'),
                const SizedBox(height: 24,),
                Text(problem.name,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18
                  ),
                ),
                const SizedBox(height: 24,),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                        onPressed: (){
                          Navigator.pop(context, 'yes');
                        },
                        child: const Text('yes')
                    ),
                    const SizedBox(width: 40,),
                    ElevatedButton(
                        onPressed: (){
                          Navigator.pop(context);
                        },
                        child: const Text('no')
                    ),
                  ],
                ),
              ],
            ),
          );
        });
    if (result == null) {
      return;
    }
    printD('remove ${problem.name}');
    await glRemoveProblemLocally(problem.name);
    int idx = problems.indexWhere((element) => element.name == problem.name);
    problems.removeAt(idx);
    setState(() {});
  }

  void _showTree(Problem problem) async {
    var result = await Navigator.push(context,
      MaterialPageRoute(builder: (context) => ShowProblemTree(problem: problem,)),
    );
  }

  void _fillStartLocalProblem() {
    var solsS = '[{"id":0,"question":"","answer":"broken cable","nestYes":-1,"nestNo":-1},{"id":1,"question":"","answer":"broken video","nestYes":-1,"nestNo":-1},{"id":2,"question":"computer beeps","answer":"","nestYes":4,"nestNo":0},{"id":3,"question":"","answer":"broken memory","nestYes":-1,"nestNo":-1},{"id":4,"question":"computer has 6 long beeps ","answer":"","nestYes":3,"nestNo":6},{"id":5,"question":"","answer":"broken MB","nestYes":-1,"nestNo":-1},{"id":6,"question":"beeps number = 4","answer":"","nestYes":5,"nestNo":1}]';
    var solsO = jsonDecode(solsS);
    Problem p = Problem(0, 'example of broken computer problem');
    List <Solution> solutions = [];
    for (var vSol in solsO) {
      solutions.add(Solution(vSol["id"], vSol["question"], vSol["answer"], vSol["nestYes"], vSol["nestNo"]));
    }
    p.solutions = solutions;
    p.startId = 2;
    problems.add(p);
    setState(() {});
  }

}

class AddNewProblem extends StatefulWidget {
  const AddNewProblem({Key? key}) : super(key: key);

  @override
  State<AddNewProblem> createState() => _AddNewProblemState();
}

class _AddNewProblemState extends State<AddNewProblem> {
  TextEditingController tecName = TextEditingController();
  TextEditingController tecSolution = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(title: const Text('Add solved problem'),),
      body: Center(
        child: Container(
          width: size.width * 0.7,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            border: Border.all(color: Colors.grey),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Describe solved problem'),
              const SizedBox(height: 12,),
              TextField(
                controller: tecName,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24,),
              const Text('and what solution you have found?'),
              const SizedBox(height: 12,),
              TextField(
                controller: tecSolution,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32,),
              ElevatedButton(
                  onPressed: (){
                    if (tecSolution.text.isEmpty) { return; }
                    if (tecName.text.isEmpty) { return; }
                    var result = {
                      "name": tecName.text,
                      "solution": tecSolution.text
                    };
                    Navigator.pop(context, result);
                  },
                  child: const Text('OK')
              ),
            ],
          ),
        ),
      ),
    );
  }
}

