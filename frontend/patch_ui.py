import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

# Define the new Console Widget
console_widget_code = """
  Widget _buildUnifiedConsole() {
    // Generate distinct colors for variables
    final List<Color> pillColors = [Colors.blueAccent, Colors.pinkAccent, Colors.purpleAccent, Colors.orangeAccent, Colors.tealAccent];
    final Map<String, Color> varColors = {};
    int colorIdx = 0;
    for (final v in variables.keys) {
      varColors[v] = pillColors[colorIdx % pillColors.length];
      colorIdx++;
    }
    for (final a in arrays.keys) {
      if (!varColors.containsKey(a)) {
        varColors[a] = pillColors[colorIdx % pillColors.length];
        colorIdx++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Debugger Controls & Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.greenAccent),
                  tooltip: isPaused ? 'Resume' : 'Pause',
                  onPressed: () => setState(() => isPaused = !isPaused),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white70),
                  tooltip: 'Step Prev',
                  onPressed: isPaused && executionHistory.isNotEmpty ? () => setState(() => stepPrev = true) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white70),
                  tooltip: 'Step Next',
                  onPressed: isPaused ? () => setState(() => stepNext = true) : null,
                ),
                const SizedBox(width: 8),
                const Text('Debugger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            // Legend
            if (varColors.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: varColors.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: e.value, borderRadius: BorderRadius.circular(12)),
                        child: Text(e.key, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    )).toList(),
                  ),
                ),
              ),
          ],
        ),
        const Divider(color: Colors.white24),
        
        // Static Code View
        Expanded(
          flex: 3,
          child: ListView.builder(
            itemCount: staticPseudocode.length,
            itemBuilder: (context, index) {
              final line = staticPseudocode[index];
              final bool isActive = line['nodeId'] == runningNodeId;
              
              // Highlight variables in text
              List<InlineSpan> spans = [];
              String rawText = line['text'];
              
              // Tokenize string roughly by words to colorize matching variables
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
              );
            },
          ),
        ),
        
        // Output Console
        if (consoleOutput.isNotEmpty) ...[
          const Divider(color: Colors.white24),
          const Text('Console Output', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: consoleOutput.length,
              itemBuilder: (context, index) {
                return Text(consoleOutput[index], style: const TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 12));
              },
            ),
          ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {"""

# Insert _buildUnifiedConsole before build method
content = content.replace("  @override\n  Widget build(BuildContext context) {", console_widget_code)

# Now replace the old Flex layout with _buildUnifiedConsole()
# We need to find `child: Flex(` and replace down to the end of the container.
# Since it's large, we use a regex.
pattern = re.compile(r'padding: const EdgeInsets\.all\(12\.0\),\s*child: Flex\([\s\S]*?// Undo/Redo Buttons')
replacement = """padding: const EdgeInsets.all(12.0),
                child: _buildUnifiedConsole(),
              ),
            ),
          // Undo/Redo Buttons"""

content = re.sub(pattern, replacement, content)

# Update container height
content = content.replace("height: MediaQuery.of(context).size.width < 650 ? 400 : 280", "height: MediaQuery.of(context).size.width < 650 ? 500 : 400")

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
