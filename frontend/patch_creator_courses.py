import re

with open('../backend/app/api/v1/endpoints/creator_courses.py', 'r') as f:
    content = f.read()

# Make sure CourseListResponse is imported
if 'CourseListResponse' not in content:
    content = content.replace('CourseResponse, ModuleCreate', 'CourseResponse, CourseListResponse, ModuleCreate')

# Change the response_model and the return type docstring
content = content.replace('@router.get("/courses", response_model=List[CourseResponse])', '@router.get("/courses", response_model=List[CourseListResponse])')

with open('../backend/app/api/v1/endpoints/creator_courses.py', 'w') as f:
    f.write(content)

print("Patched creator_courses.py")
