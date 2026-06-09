import ast
import subprocess
import tempfile
import os
import time
from typing import Dict, Any

# A very basic blacklist of dangerous modules for our MVP
DANGEROUS_MODULES = [
    "os", "sys", "subprocess", "shutil", "socket", 
    "requests", "urllib", "http", "pty", "pathlib"
]

class CodeExecutionError(Exception):
    pass

class SecurityNodeVisitor(ast.NodeVisitor):
    def visit_Import(self, node):
        for alias in node.names:
            if alias.name.split('.')[0] in DANGEROUS_MODULES:
                raise CodeExecutionError(f"Importing '{alias.name}' is not allowed for security reasons.")
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        if node.module and node.module.split('.')[0] in DANGEROUS_MODULES:
            raise CodeExecutionError(f"Importing from '{node.module}' is not allowed for security reasons.")
        self.generic_visit(node)

def check_code_security(code: str) -> None:
    """Parses code to check for blacklisted imports."""
    try:
        tree = ast.parse(code)
    except SyntaxError as e:
        raise CodeExecutionError(f"SyntaxError: {str(e)}")
        
    visitor = SecurityNodeVisitor()
    visitor.visit(tree)

async def execute_python_code(code: str, timeout_seconds: int = 5, standard_input: str = "") -> Dict[str, Any]:
    """Execute python code in a separate process with a timeout."""
    start_time = time.time()
    
    try:
        # 1. Security Check
        check_code_security(code)
        
        # 2. Write code to temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as temp_file:
            temp_file.write(code)
            temp_path = temp_file.name

        try:
            # 3. Execute code in a subprocess
            # Note: In a true production environment, this should run inside a Docker container
            # or a gVisor sandbox. For MVP, we use subprocess with timeout.
            process = subprocess.run(
                ['python3', temp_path],
                input=standard_input,
                capture_output=True,
                text=True,
                timeout=timeout_seconds
            )
            
            execution_time = (time.time() - start_time) * 1000  # in ms
            
            return {
                "stdout": process.stdout,
                "stderr": process.stderr,
                "execution_time_ms": int(execution_time),
                "is_success": process.returncode == 0
            }
            
        except subprocess.TimeoutExpired:
            execution_time = (time.time() - start_time) * 1000
            return {
                "stdout": "",
                "stderr": f"Error: Execution timed out after {timeout_seconds} seconds.",
                "execution_time_ms": int(execution_time),
                "is_success": False
            }
        finally:
            # Cleanup temp file
            if os.path.exists(temp_path):
                os.remove(temp_path)
                
    except CodeExecutionError as e:
        return {
            "stdout": "",
            "stderr": str(e),
            "execution_time_ms": int((time.time() - start_time) * 1000),
            "is_success": False
        }
    except Exception as e:
        return {
            "stdout": "",
            "stderr": f"System Error: {str(e)}",
            "execution_time_ms": int((time.time() - start_time) * 1000),
            "is_success": False
        }
