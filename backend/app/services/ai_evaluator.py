import os
from groq import AsyncGroq
import json

class AIEvaluator:
    def __init__(self):
        # Initialize Groq client. It will automatically look for GROQ_API_KEY in environment
        self.client = AsyncGroq()

    async def evaluate(self, prompt: str, expected_output: str, actual_output: str, source_code: str) -> dict:
        """
        Evaluate student code using an LLM.
        Returns a dict: {"score": int, "reason": str}
        """
        system_message = (
            "You are an expert, compassionate Computer Science teacher. "
            "You are grading a student's coding challenge submission. "
            "Sometimes, exact string matching fails because a student used slightly different words, "
            "formatting, or case (e.g. 'January: 120' vs 'Jan: 120'). "
            "Your job is to semantically evaluate if the student's output is correct based on the prompt "
            "and the expected output.\n\n"
            "Return ONLY a valid JSON object with no markdown formatting. It must have exactly two keys:\n"
            "1. 'score': an integer from 0 to 100 indicating how correct the student's output is compared to the expected output.\n"
            "2. 'reason': a short, encouraging string (max 2 sentences) explaining why they got this score, and what to fix if it's not 100."
        )

        user_message = f"""
Challenge Prompt / Description:
{prompt}

Teacher's Expected Output:
{expected_output}

Student's Actual Output:
{actual_output}

Student's Source Code:
{source_code}
"""

        try:
            chat_completion = await self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": system_message},
                    {"role": "user", "content": user_message}
                ],
                model="llama-3.3-70b-versatile",
                temperature=0.0,
                max_tokens=150,
                response_format={"type": "json_object"}
            )
            
            response_content = chat_completion.choices[0].message.content
            return json.loads(response_content)
        except Exception as e:
            # Fallback if AI fails
            return {
                "score": 0,
                "reason": f"AI Evaluation failed: {str(e)}. Please ensure your output exactly matches the expected output."
            }

    async def analyze_complexity(self, source_code: str) -> dict:
        """
        Analyze the time and space complexity of the given Python code.
        Returns {"time_complexity": "O(...)", "space_complexity": "O(...)", "explanation": "..."}
        """
        system_message = (
            "You are an expert algorithm analyzer. Analyze the provided Python code for Big-O time and space complexity.\n"
            "Return ONLY a JSON object with exactly three keys:\n"
            "1. 'time_complexity': A string like 'O(N)', 'O(N^2)', 'O(1)', etc.\n"
            "2. 'space_complexity': A string like 'O(N)', 'O(1)', etc.\n"
            "3. 'explanation': A short 1-2 sentence explanation of why it has this complexity."
        )
        try:
            chat_completion = await self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": system_message},
                    {"role": "user", "content": f"Code to analyze:\n\n{source_code}"}
                ],
                model="llama-3.3-70b-versatile",
                temperature=0.0,
                max_tokens=200,
                response_format={"type": "json_object"}
            )
            return json.loads(chat_completion.choices[0].message.content)
        except Exception as e:
            return {
                "time_complexity": "O(?)",
                "space_complexity": "O(?)",
                "explanation": f"Analysis failed: {str(e)}"
            }

    async def generate_flowchart(self, source_code: str) -> dict:
        """
        Convert Python code into a flowchart JSON structure compatible with React Flow / Flutter Flow properties.
        Returns {"nodes": [...], "edges": [...]}
        """
        system_message = (
            "You are an expert compiler that converts Python code into a flowchart graph.\n"
            "Your job is to read the provided Python code and output ONLY a JSON object representing the flowchart graph.\n"
            "The JSON must have exactly two keys: 'nodes' and 'edges'.\n"
            "A Node object must look like: {\"id\": \"n1\", \"type\": \"oval\" | \"parallelogram\" | \"rectangle\" | \"diamond\", \"text\": \"code or text\", \"x\": 0, \"y\": 0}\n"
            "Use oval for start/end, parallelogram for input/output, rectangle for process/code, diamond for conditions/loops.\n"
            "An Edge object must look like: {\"fromNodeId\": \"n1\", \"toNodeId\": \"n2\", \"fromAnchor\": \"bottom\", \"toAnchor\": \"top\", \"label\": \"YES\" | \"NO\" | null}\n"
            "Position nodes logically, flowing top to bottom (increment y by 100 for each step). Branch horizontally for conditions (increment/decrement x).\n"
            "Ensure the graph starts with a 'start' node and ends with an 'end' node."
        )
        try:
            chat_completion = await self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": system_message},
                    {"role": "user", "content": f"Convert this Python code to a flowchart:\n\n{source_code}"}
                ],
                model="llama-3.3-70b-versatile",
                temperature=0.0,
                max_tokens=2000,
                response_format={"type": "json_object"}
            )
            return json.loads(chat_completion.choices[0].message.content)
        except Exception as e:
            return {"nodes": [], "edges": []}

# Singleton instance
ai_evaluator = AIEvaluator()
