import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

# Fix loop text
content = content.replace("text = 'while (' + text.replaceAll('\\n', ' ') + ')';", "text = 'loop (' + text.replaceAll('\\n', ' ') + ')';")

# Fix UI injection
old_ui_logic = """              // Tokenize string roughly by words to colorize matching variables
              final words = rawText.split(RegExp(r'(\\b|\\s+)'));
              for (String w in words) {
                 final cleanW = w.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
                 if (varColors.containsKey(cleanW)) {
                    spans.add(WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: varColors[cleanW], borderRadius: BorderRadius.circular(4)),
                        child: Text(w, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ));
                    // Inject value if active
                    if (isActive) {
                       dynamic val;
                       if (variables.containsKey(cleanW)) {
                         val = variables[cleanW] == variables[cleanW]!.truncateToDouble() ? variables[cleanW]!.toInt() : variables[cleanW];
                       } else if (arrays.containsKey(cleanW)) {
                         val = arrays[cleanW]!.map((e) => e == e.truncateToDouble() ? e.toInt() : e).toList();
                       }
                       if (val != null) {
                          spans.add(TextSpan(text: ' [${val}] ', style: TextStyle(color: varColors[cleanW], fontWeight: FontWeight.bold, fontSize: 11)));
                       }
                    }
                 } else {
                    spans.add(TextSpan(text: w));
                 }
              }"""

new_ui_logic = """              // Check if assignment (contains '=' but not '==', '<=', '>=', '!=')
              int eqIdx = rawText.indexOf('=');
              bool isAssignment = false;
              if (eqIdx > 0 && rawText[eqIdx - 1] != '!' && rawText[eqIdx - 1] != '<' && rawText[eqIdx - 1] != '>' && (eqIdx + 1 >= rawText.length || rawText[eqIdx + 1] != '=')) {
                 isAssignment = true;
              }
              
              // Tokenize string roughly by words to colorize matching variables
              final words = rawText.split(RegExp(r'(\\b|\\s+)'));
              int currentLength = 0;
              for (String w in words) {
                 bool inLeftSide = isAssignment && currentLength <= eqIdx;
                 currentLength += w.length;
                 
                 final cleanW = w.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
                 if (varColors.containsKey(cleanW)) {
                    dynamic val;
                    bool showValue = isActive && !inLeftSide;
                    if (showValue) {
                       if (variables.containsKey(cleanW)) {
                         val = variables[cleanW] == variables[cleanW]!.truncateToDouble() ? variables[cleanW]!.toInt() : variables[cleanW];
                       } else if (arrays.containsKey(cleanW)) {
                         val = arrays[cleanW]!.map((e) => e == e.truncateToDouble() ? e.toInt() : e).toList();
                       }
                    }
                    
                    spans.add(WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: varColors[cleanW], borderRadius: BorderRadius.circular(4)),
                        child: Text(val != null ? val.toString() : w, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ));
                 } else {
                    spans.add(TextSpan(text: w));
                 }
              }"""

content = content.replace(old_ui_logic, new_ui_logic)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
