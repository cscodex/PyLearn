import re

with open("frontend/lib/features/profile/presentation/pages/profile_screen.dart", "r") as f:
    content = f.read()

old_error_block = """            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }"""

new_error_block = """            } catch (e) {
              if (context.mounted) {
                String errorMessage = 'Failed to update password';
                if (e is DioException) {
                  errorMessage = e.response?.data['detail'] ?? e.message ?? errorMessage;
                } else {
                  errorMessage = e.toString();
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
              }
            }"""

if "import 'package:dio/dio.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:dio/dio.dart';")

content = content.replace(old_error_block, new_error_block)

with open("frontend/lib/features/profile/presentation/pages/profile_screen.dart", "w") as f:
    f.write(content)
