import ast
import subprocess
import tempfile
import os
import time
import queue
import json
from typing import Dict, Any, Optional

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

import io
import sys
import contextlib
import traceback
import asyncio
import threading
import base64
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

# Prevent concurrent matplotlib global state mutations
_execution_lock = threading.Lock()

class InteractiveStream(io.StringIO):
    def __init__(self, stream_type: str, out_queue: queue.Queue):
        super().__init__()
        self.stream_type = stream_type
        self.out_queue = out_queue

    def write(self, s: str):
        # We push stdout/stderr in real-time
        self.out_queue.put({"type": self.stream_type, "data": s})
        super().write(s)
        
    def flush(self):
        pass

def _run_in_process_interactive(code: str, out_queue: queue.Queue, in_queue: queue.Queue) -> None:
    """Runs code synchronously but streams output to queues instead of blocking everything."""
    f_out = InteractiveStream("stdout", out_queue)
    f_err = InteractiveStream("stderr", out_queue)
    
    def mock_input(prompt=""):
        if prompt:
            f_out.write(str(prompt))
        
        # Notify the frontend that we are waiting for input
        out_queue.put({"type": "input_request"})
        
        # Block until the frontend sends back input via the in_queue
        user_input = in_queue.get()
        
        # Optionally echo it back to stdout so it looks like a real terminal
        f_out.write(user_input + "\n")
        
        return user_input

    def mock_show(*args, **kwargs):
        buf = io.BytesIO()
        plt.savefig(buf, format='png')
        buf.seek(0)
        img_base64 = base64.b64encode(buf.read()).decode('utf-8')
        out_queue.put({"type": "plot", "data": img_base64})
        plt.close()

    # Provide a safe globals dictionary
    safe_globals = {
        "__builtins__": __builtins__.copy(),
        "input": mock_input,
        "plt": plt,
        "pd": pd,
        "np": np
    }

    with _execution_lock:
        original_show = plt.show
        plt.show = mock_show
        
        try:
            with contextlib.redirect_stdout(f_out), contextlib.redirect_stderr(f_err):
                exec(code, safe_globals)
                
            if plt.get_fignums():
                mock_show()
                
        except Exception as e:
            traceback.print_exc(file=f_err)
        finally:
            plt.show = original_show
            plt.clf()
            plt.close('all')
            # Signal the execution is completely finished
            out_queue.put({"type": "completed"})


# We keep the old batch one for backward compatibility and simple evaluations
def _run_in_process(code: str, standard_input: str) -> Dict[str, Any]:
    start_time = time.time()
    f_out = io.StringIO()
    f_err = io.StringIO()
    plots_list = []
    
    input_lines = standard_input.split('\n')
    input_iter = iter(input_lines)
    
    def mock_input(prompt=""):
        if prompt:
            f_out.write(str(prompt))
        try:
            return next(input_iter)
        except StopIteration:
            return ""

    def mock_show(*args, **kwargs):
        buf = io.BytesIO()
        plt.savefig(buf, format='png')
        buf.seek(0)
        img_base64 = base64.b64encode(buf.read()).decode('utf-8')
        plots_list.append(img_base64)
        plt.close()

    safe_globals = {
        "__builtins__": __builtins__.copy(),
        "input": mock_input,
        "plt": plt,
        "pd": pd,
        "np": np
    }

    with _execution_lock:
        original_show = plt.show
        plt.show = mock_show
        
        try:
            with contextlib.redirect_stdout(f_out), contextlib.redirect_stderr(f_err):
                exec(code, safe_globals)
                
            if plt.get_fignums():
                mock_show()
                
            success = True
        except Exception as e:
            traceback.print_exc(file=f_err)
            success = False
        finally:
            plt.show = original_show
            plt.clf()
            plt.close('all')
        
    execution_time = (time.time() - start_time) * 1000
    
    return {
        "stdout": f_out.getvalue(),
        "stderr": f_err.getvalue(),
        "execution_time_ms": int(execution_time),
        "is_success": success,
        "plots": plots_list
    }

async def execute_python_code(code: str, timeout_seconds: int = 15, standard_input: str = "") -> Dict[str, Any]:
    """Execute python code rapidly in-process to avoid cold starts."""
    try:
        check_code_security(code)
        
        result = await asyncio.wait_for(
            asyncio.to_thread(_run_in_process, code, standard_input),
            timeout=timeout_seconds
        )
        return result
        
    except asyncio.TimeoutError:
        return {
            "stdout": "",
            "stderr": f"Error: Execution timed out after {timeout_seconds} seconds.",
            "execution_time_ms": timeout_seconds * 1000,
            "is_success": False
        }
    except CodeExecutionError as e:
        return {
            "stdout": "",
            "stderr": str(e),
            "execution_time_ms": 0,
            "is_success": False
        }
    except Exception as e:
        return {
            "stdout": "",
            "stderr": f"System Error: {str(e)}",
            "execution_time_ms": 0,
            "is_success": False
        }
