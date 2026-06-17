import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

# 1. Add loopCycles state and logic
state_old = """  int iterations = 0;
  List<String> consoleOutput = [];"""
state_new = """  int iterations = 0;
  int loopCycles = 0;
  List<String> consoleOutput = [];"""
content = content.replace(state_old, state_new)

snap_old = """  final int iterations;

  ExecutionSnapshot({
    required this.runningNodeId,
    required this.variables,
    required this.arrays,
    required this.consoleOutput,
    required this.iterations,
  });"""
snap_new = """  final int iterations;
  final int loopCycles;

  ExecutionSnapshot({
    required this.runningNodeId,
    required this.variables,
    required this.arrays,
    required this.consoleOutput,
    required this.iterations,
    required this.loopCycles,
  });"""
content = content.replace(snap_old, snap_new)

clone_old = """      iterations: iterations,
    );
  }"""
clone_new = """      iterations: iterations,
      loopCycles: loopCycles,
    );
  }"""
content = content.replace(clone_old, clone_new)

run_old = """          iterations = 0;
        });"""
run_new = """          iterations = 0;
          loopCycles = 0;
        });"""
content = content.replace(run_old, run_new)

restore_old = """              iterations = snapshot.iterations;
            });"""
restore_new = """              iterations = snapshot.iterations;
              loopCycles = snapshot.loopCycles;
            });"""
content = content.replace(restore_old, restore_new)

snapshot_add_old = """        iterations: iterations,
      ));"""
snapshot_add_new = """        iterations: iterations,
        loopCycles: loopCycles,
      ));"""
content = content.replace(snapshot_add_old, snapshot_add_new)

# Add loopCycles increment when edge is taken
edge_trav_old = """      // Animate edge traversal
      await _animateEdgeTraversal(node.id, nextNodeId);"""
edge_trav_new = """      // Check if back-edge for loop cycles
      final targetNode = nodes.firstWhere((n) => n.id == nextNodeId, orElse: () => node);
      if (targetNode.position.dy <= node.position.dy && targetNode.id != node.id) {
         setState(() => loopCycles++);
      }
      
      // Animate edge traversal
      await _animateEdgeTraversal(node.id, nextNodeId);"""
content = content.replace(edge_trav_old, edge_trav_new)

# 2. Add complexity helpers
helpers_code = """
  int _calculateMaxLoopDepth() {
     List<List<double>> backEdges = [];
     for (final edge in edges) {
        final fromNode = nodes.firstWhere((n) => n.id == edge.fromNodeId, orElse: () => nodes.first);
        final toNode = nodes.firstWhere((n) => n.id == edge.toNodeId, orElse: () => nodes.first);
        if (fromNode.id != toNode.id && fromNode.position.dy >= toNode.position.dy) {
           backEdges.add([toNode.position.dy, fromNode.position.dy]);
        }
     }
     if (backEdges.isEmpty) return 0;
     
     int maxDepth = 1;
     for (int i = 0; i < backEdges.length; i++) {
        int depth = 1;
        for (int j = 0; j < backEdges.length; j++) {
           if (i == j) continue;
           // if backEdge[j] strictly contains backEdge[i]
           if (backEdges[j][0] <= backEdges[i][0] && backEdges[j][1] >= backEdges[i][1]) {
              depth++;
           }
        }
        if (depth > maxDepth) maxDepth = depth;
     }
     return maxDepth;
  }

  String _getTimeComplexity() {
     int depth = _calculateMaxLoopDepth();
     if (depth == 0) return 'O(1)';
     if (depth == 1) return 'O(n)';
     if (depth == 2) return 'O(n²)';
     if (depth == 3) return 'O(n³)';
     return 'O(n^$depth)';
  }

  int _getCyclomaticComplexity() {
     if (nodes.isEmpty) return 0;
     return edges.length - nodes.length + 2;
  }
  
  void _generateStaticCode() {"""
content = content.replace("  void _generateStaticCode() {", helpers_code)

# 3. Add complexity badges to UI
ui_old = """        const Divider(color: Colors.white24),
        
        // Static Code View"""
ui_new = """        const Divider(color: Colors.white24),
        
        // Complexity Badges
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                     decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blueAccent)),
                     child: Text('Time: ${_getTimeComplexity()}', style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                   ),
                   const SizedBox(width: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                     decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.purpleAccent)),
                     child: Text('Complexity (V): ${_getCyclomaticComplexity()}', style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                   ),
                ],
              ),
              if (_calculateMaxLoopDepth() > 0)
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orangeAccent)),
                   child: Text('Loop Cycles: $loopCycles', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                 ),
            ],
          ),
        ),
        
        // Static Code View"""
content = content.replace(ui_old, ui_new)


with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
