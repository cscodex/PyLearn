import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

# 1. State Variables
state_old = """  int loopCycles = 0;
  List<String> consoleOutput = [];"""
state_new = """  int loopCycles = 0;
  List<String> consoleOutput = [];
  bool _isWaitingForInput = false;
  String _inputVariableName = '';
  import 'dart:async'; // Need completer if not already imported
  Completer<double?>? _inputCompleter;
  final FocusNode _consoleInputFocusNode = FocusNode();
  final TextEditingController _consoleInputController = TextEditingController();"""

# Remove import if inside class by doing it properly at the top of file
content = content.replace("import 'dart:convert';", "import 'dart:convert';\nimport 'dart:async';")
state_new = """  int loopCycles = 0;
  List<String> consoleOutput = [];
  bool _isWaitingForInput = false;
  String _inputVariableName = '';
  Completer<double?>? _inputCompleter;
  final FocusNode _consoleInputFocusNode = FocusNode();
  final TextEditingController _consoleInputController = TextEditingController();"""
content = content.replace(state_old, state_new)

# 2. _promptInput implementation
prompt_old = """  Future<double?> _promptInput(String varName) async {
     final controller = TextEditingController();
     final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
           return AlertDialog(
              backgroundColor: const Color(0xFF2C2C3E),
              title: Text('Input $varName', style: const TextStyle(color: Colors.white)),
              content: TextField(
                 controller: controller,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 style: const TextStyle(color: Colors.white),
                 decoration: const InputDecoration(
                    hintText: 'Enter a number',
                    hintStyle: TextStyle(color: Colors.white54),
                 ),
              ),
              actions: [
                 FilledButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    child: const Text('Submit'),
                 )
              ],
           );
        }
     );
     if (result != null && result.isNotEmpty) {
        return double.tryParse(result);
     }
     return 0.0;
  }"""
prompt_new = """  Future<double?> _promptInput(String varName) async {
     setState(() {
        _isWaitingForInput = true;
        _inputVariableName = varName;
        _inputCompleter = Completer<double?>();
        _consoleInputController.clear();
        consoleOutput.add("> Waiting for input: $varName");
     });
     _scrollToConsoleBottom();
     WidgetsBinding.instance.addPostFrameCallback((_) {
        _consoleInputFocusNode.requestFocus();
     });
     return _inputCompleter!.future;
  }"""
content = content.replace(prompt_old, prompt_new)

# 3. Add to Console UI
ui_old = """        // Output Console
        if (consoleOutput.isNotEmpty) ...[
          const Divider(color: Colors.white24),
          const Text('Console Output', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            flex: 1,
            child: ListView.builder(
              controller: _consoleScrollController,
              itemCount: consoleOutput.length,
              itemBuilder: (context, index) {
                return Text(consoleOutput[index], style: const TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 12));
              },
            ),
          ),
        ]
      ],
    );"""
ui_new = """        // Output Console
        if (consoleOutput.isNotEmpty || _isWaitingForInput) ...[
          const Divider(color: Colors.white24),
          const Text('Console Output', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _consoleScrollController,
                    itemCount: consoleOutput.length,
                    itemBuilder: (context, index) {
                      return Text(consoleOutput[index], style: const TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 12));
                    },
                  ),
                ),
                if (_isWaitingForInput)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Text('$_inputVariableName: ', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
                        Expanded(
                          child: SizedBox(
                            height: 24,
                            child: TextField(
                              controller: _consoleInputController,
                              focusNode: _consoleInputFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.only(bottom: 8),
                                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                              ),
                              onSubmitted: (val) {
                                double? parsed = double.tryParse(val);
                                if (parsed != null) {
                                   setState(() {
                                      _isWaitingForInput = false;
                                      // replace the "waiting for input" line with the actual input
                                      if (consoleOutput.isNotEmpty && consoleOutput.last.startsWith("> Waiting for input:")) {
                                         consoleOutput[consoleOutput.length - 1] = "> Entered $_inputVariableName = $parsed";
                                      }
                                   });
                                   _inputCompleter?.complete(parsed);
                                } else {
                                   setState(() => consoleOutput.add("> Error: Invalid number"));
                                   _scrollToConsoleBottom();
                                   _consoleInputFocusNode.requestFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ]
      ],
    );"""
content = content.replace(ui_old, ui_new)

# Add focusnode disposal
dispose_old = """  void dispose() {
    _edgeAnimController?.dispose();
    _codeScrollController.dispose();
    _consoleScrollController.dispose();
    super.dispose();
  }"""
dispose_new = """  void dispose() {
    _edgeAnimController?.dispose();
    _codeScrollController.dispose();
    _consoleScrollController.dispose();
    _consoleInputFocusNode.dispose();
    _consoleInputController.dispose();
    super.dispose();
  }"""
content = content.replace(dispose_old, dispose_new)

# Fix run state reset
reset_old = """          loopCycles = 0;
        });"""
reset_new = """          loopCycles = 0;
          _isWaitingForInput = false;
        });"""
content = content.replace(reset_old, reset_new)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
