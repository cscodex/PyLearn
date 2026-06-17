import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

# Add _evalCondition helper method before _runFlowchart
eval_helper = """
  bool? _evalCondition(String text) {
     try {
        String op = '';
        List<String> parts = [];
        if (text.contains('>=')) { op = '>='; parts = text.split('>='); }
        else if (text.contains('<=')) { op = '<='; parts = text.split('<='); }
        else if (text.contains('!=')) { op = '!='; parts = text.split('!='); }
        else if (text.contains('==')) { op = '=='; parts = text.split('=='); }
        else if (text.contains('>')) { op = '>'; parts = text.split('>'); }
        else if (text.contains('<')) { op = '<'; parts = text.split('<'); }

        if (parts.length == 2 && op.isNotEmpty) {
           double left = _evalExpr(parts[0].trim());
           double right = _evalExpr(parts[1].trim());
           switch (op) {
             case '>': return left > right;
             case '<': return left < right;
             case '>=': return left >= right;
             case '<=': return left <= right;
             case '==': return left == right;
             case '!=': return left != right;
           }
        } else if (text.toLowerCase() == 'true') {
           return true;
        } else if (text.toLowerCase() == 'false') {
           return false;
        }
     } catch (e) {
        return null;
     }
     return null;
  }
  
  void _generateStaticCode() {"""

content = content.replace("  void _generateStaticCode() {", eval_helper)

# Fix play button in AppBar
old_play_btn = """            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.greenAccent),
              tooltip: 'Run Flowchart',
              onPressed: _runFlowchart,
            ),"""

new_play_btn = """            IconButton(
              icon: Icon(Icons.play_arrow, color: nodes.isEmpty ? Colors.grey : Colors.greenAccent),
              tooltip: 'Run Flowchart',
              onPressed: nodes.isEmpty ? null : _runFlowchart,
            ),"""

content = content.replace(old_play_btn, new_play_btn)

# Fix Legend to show current value
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

# Fix True/False append in UI
old_ui_return = """              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.yellowAccent.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isActive ? Border.all(color: Colors.yellowAccent, width: 1.5) : null,
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontFamily: 'monospace', fontSize: 14),
                    children: spans,
                  ),
                ),
              );"""

new_ui_return = """              // Append True/False if it's a condition and active
              if (isActive && (rawText.startsWith('if (') || rawText.startsWith('loop ('))) {
                 final rawCondition = line['rawConditionText'] as String?;
                 if (rawCondition != null) {
                    bool? condRes = _evalCondition(rawCondition);
                    if (condRes != null) {
                       spans.add(TextSpan(
                         text: condRes ? '   ---> True' : '   ---> False',
                         style: TextStyle(color: condRes ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                       ));
                    }
                 }
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.yellowAccent.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isActive ? Border.all(color: Colors.yellowAccent, width: 1.5) : null,
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontFamily: 'monospace', fontSize: 14),
                    children: spans,
                  ),
                ),
              );"""

content = content.replace(old_ui_return, new_ui_return)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
