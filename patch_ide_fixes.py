import sys

def patch_file():
    with open('frontend/lib/features/course/presentation/pages/ide_screen.dart', 'r') as f:
        content = f.read()

    # 1. Add missing imports
    if "import 'package:shared_preferences/shared_preferences.dart';" not in content:
        content = content.replace("import 'package:http/http.dart' as http;", "import 'package:http/http.dart' as http;\nimport 'package:shared_preferences/shared_preferences.dart';\nimport 'independent_flowchart_designer_screen.dart';")

    # 2. Fix _analyzeComplexity token
    old_token_1 = "final token = await widget.tokenProvider();"
    new_token_1 = """final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');"""
    content = content.replace(old_token_1, new_token_1)

    # 3. Fix _generateFlowchart
    old_generate = """          final flowchartObj = SavedFlowchart(
            id: 0,
            title: 'AI Generated Flowchart',
            nodes: data['nodes'] ?? [],
            edges: data['edges'] ?? [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );"""
    
    new_generate = """          final flowchartObj = SavedFlowchart(
            id: 0,
            title: 'AI Generated Flowchart',
            nodes: (data['nodes'] as List<dynamic>?)?.map((e) => FlowchartNode.fromJson(e)).toList() ?? [],
            edges: (data['edges'] as List<dynamic>?)?.map((e) => FlowchartEdge.fromJson(e)).toList() ?? [],
            createdAt: DateTime.now(),
          );"""
    content = content.replace(old_generate, new_generate)

    with open('frontend/lib/features/course/presentation/pages/ide_screen.dart', 'w') as f:
        f.write(content)

patch_file()
