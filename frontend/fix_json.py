import os
import re

files_to_fix = [
    "lib/features/profile/domain/entities/user_stats.dart",
    "lib/features/admin/presentation/providers/admin_users_provider.dart",
    "lib/features/auth/domain/entities/user.dart",
    "lib/features/leaderboard/domain/entities/leaderboard_user.dart",
    "lib/features/creator/presentation/providers/creator_groups_provider.dart",
    "lib/features/admin/presentation/providers/admin_enrollments_provider.dart",
    "lib/features/creator/presentation/providers/creator_enrollments_provider.dart"
]

def camel_case(s):
    parts = s.split('_')
    return parts[0] + ''.join(word.capitalize() for word in parts[1:])

for fpath in files_to_fix:
    if not os.path.exists(fpath): continue
    with open(fpath, "r") as f:
        content = f.read()
    
    # We find all json['snake_case'] inside fromJson and change them
    def replace_json(match):
        snake = match.group(1)
        if '_' not in snake: return match.group(0) # no change for plain keys
        camel = camel_case(snake)
        return f"json['{camel}'] ?? json['{snake}']"

    # Replace json['something_with_underscore']
    content = re.sub(r"json\['([a-z0-9_]+)'\]", replace_json, content)
    
    # specifically fix id parsing
    if "id: json['id'] ?? ''," in content:
        content = content.replace("id: json['id'] ?? '',", "id: json['id']?.toString() ?? '',")
    elif "id: json['id'].toString()" in content:
        content = content.replace("id: json['id'].toString()", "id: json['id']?.toString() ?? ''")
    
    if "email: json['email']," in content:
        content = content.replace("email: json['email'],", "email: json['email'] ?? '',")
    
    with open(fpath, "w") as f:
        f.write(content)

print("Done fixing json parsing")
