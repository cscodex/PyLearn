import sys

def patch_file():
    with open('frontend/lib/features/course/presentation/pages/ide_screen.dart', 'r') as f:
        content = f.read()

    # 1. Replace Navigator.push with setting state variable
    old_generate = """          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndependentFlowchartDesignerScreen(
                initialFlowchart: flowchartObj,
              ),
            ),
          );"""
    new_generate = """          setState(() {
            _generatedFlowchart = flowchartObj;
            _showFlowchartOverlay = true;
          });"""
    content = content.replace(old_generate, new_generate)

    # 2. Add state variables
    if "SavedFlowchart? _generatedFlowchart;" not in content:
        content = content.replace("bool _isExecuting = false;", "bool _isExecuting = false;\n  SavedFlowchart? _generatedFlowchart;\n  bool _showFlowchartOverlay = false;")

    # 3. Add Flowchart floating button next to Run button
    old_floating = """                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: _isExecuting ? null : _runCode,
                        backgroundColor: theme.colorScheme.surface,
                        elevation: 4,
                        child: _isExecuting 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                          : const Icon(Icons.play_arrow, color: Colors.green, size: 32),
                      ),
                    ),
                  ],"""
    new_floating = """                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_generatedFlowchart != null) ...[
                            FloatingActionButton(
                              heroTag: 'flowchart_btn',
                              onPressed: () {
                                setState(() {
                                  _showFlowchartOverlay = true;
                                });
                              },
                              backgroundColor: theme.colorScheme.surface,
                              elevation: 4,
                              child: const Icon(Icons.account_tree, color: Colors.purpleAccent, size: 28),
                            ),
                            const SizedBox(width: 16),
                          ],
                          FloatingActionButton(
                            heroTag: 'run_btn',
                            onPressed: _isExecuting ? null : _runCode,
                            backgroundColor: theme.colorScheme.surface,
                            elevation: 4,
                            child: _isExecuting 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                              : const Icon(Icons.play_arrow, color: Colors.green, size: 32),
                          ),
                        ],
                      ),
                    ),
                  ],"""
    content = content.replace(old_floating, new_floating)

    # 4. Add the overlay stack
    old_body = """      body: Column(
        children: ["""
    new_body = """      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: ["""
    content = content.replace(old_body, new_body)

    # 5. Close the stack and add the overlay
    old_end = """              ),
            ),
          ],
        ),
      ),
    );
  }
}"""
    new_end = """              ),
            ),
          ],
        ),
      ),
      if (_showFlowchartOverlay && _generatedFlowchart != null)
        Positioned.fill(
          child: Container(
            color: Colors.black87,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    color: theme.colorScheme.surface,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Generated Flowchart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _showFlowchartOverlay = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: IndependentFlowchartDesignerScreen(
                      initialFlowchart: _generatedFlowchart,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }
}"""
    content = content.replace(old_end, new_end)

    with open('frontend/lib/features/course/presentation/pages/ide_screen.dart', 'w') as f:
        f.write(content)

patch_file()
