import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

# 1. Add controllers and scroll methods
controllers_code = """
  final ScrollController _codeScrollController = ScrollController();
  final ScrollController _consoleScrollController = ScrollController();

  @override
  void dispose() {
    _codeScrollController.dispose();
    _consoleScrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine() {
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if (!_codeScrollController.hasClients) return;
       int index = staticPseudocode.indexWhere((p) => p['nodeId'] == runningNodeId);
       if (index != -1) {
         double target = index * 35.0;
         _codeScrollController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
       }
     });
  }

  void _scrollToConsoleBottom() {
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if (!_consoleScrollController.hasClients) return;
       _consoleScrollController.animateTo(
         _consoleScrollController.position.maxScrollExtent + 50,
         duration: const Duration(milliseconds: 300),
         curve: Curves.easeOut,
       );
     });
  }

  void _undo() {"""

content = content.replace("  void _undo() {", controllers_code)

# 2. Add scroll controller to static pseudocode listview
old_listview1 = """        Expanded(
          flex: 3,
          child: ListView.builder(
            itemCount: staticPseudocode.length,"""

new_listview1 = """        Expanded(
          flex: 3,
          child: ListView.builder(
            controller: _codeScrollController,
            itemCount: staticPseudocode.length,"""
content = content.replace(old_listview1, new_listview1)

# 3. Add scroll controller to console listview
old_listview2 = """          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: consoleOutput.length,"""

new_listview2 = """          Expanded(
            flex: 1,
            child: ListView.builder(
              controller: _consoleScrollController,
              itemCount: consoleOutput.length,"""
content = content.replace(old_listview2, new_listview2)


# 4. Trigger scrolling whenever runningNodeId changes
old_setstate1 = """      setState(() => runningNodeId = currentNodeId);"""
new_setstate1 = """      setState(() => runningNodeId = currentNodeId);
      _scrollToActiveLine();"""
content = content.replace(old_setstate1, new_setstate1)

old_setstate2 = """      setState(() {
        isPaused = true;
      });"""
new_setstate2 = """      setState(() {
        isPaused = true;
      });
      _scrollToActiveLine();"""
content = content.replace(old_setstate2, new_setstate2)

# 5. Trigger scrolling when console output is added
old_console1 = """              consoleOutput.add('> Initialized $left = $val');"""
new_console1 = """              consoleOutput.add('> Initialized $left = $val');
              _scrollToConsoleBottom();"""
content = content.replace(old_console1, new_console1)

old_console2 = """              consoleOutput.add('> Evaluated $right to $val');"""
new_console2 = """              consoleOutput.add('> Evaluated $right to $val');
              _scrollToConsoleBottom();"""
content = content.replace(old_console2, new_console2)

old_console3 = """            consoleOutput.add('> Output: $evaluatedStr');"""
new_console3 = """            consoleOutput.add('> Output: $evaluatedStr');
            _scrollToConsoleBottom();"""
content = content.replace(old_console3, new_console3)


# 6. Finally fix the Legend!
old_legend = """                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: e.value, borderRadius: BorderRadius.circular(12)),
                          child: Text(e.key, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      );"""

new_legend = """                      String valStr = '';
                      if (variables.containsKey(e.key)) {
                         final v = variables[e.key]!;
                         valStr = v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
                      } else if (arrays.containsKey(e.key)) {
                         valStr = arrays[e.key]!.map((a) => a == a.truncateToDouble() ? a.toInt() : a).toList().toString();
                      }
                      final displayStr = valStr.isNotEmpty ? '${e.key}: $valStr' : e.key;

                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: e.value, borderRadius: BorderRadius.circular(12)),
                          child: Text(displayStr, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      );"""
content = content.replace(old_legend, new_legend)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
