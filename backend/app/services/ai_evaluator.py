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
        Returns a dict: {"passed": bool, "reason": str}
        """
        system_message = (
            "You are an expert, compassionate Computer Science teacher. "
            "You are grading a student's coding challenge submission. "
            "Sometimes, exact string matching fails because a student used slightly different words, "
            "formatting, or case (e.g. 'January: 120' vs 'Jan: 120'). "
            "Your job is to semantically evaluate if the student's output is correct based on the prompt "
            "and the expected output.\n\n"
            "Return ONLY a valid JSON object with no markdown formatting. It must have exactly two keys:\n"
            "1. 'passed': a boolean indicating if the student's output is semantically correct.\n"
            "2. 'reason': a short, encouraging string (max 2 sentences) explaining why they passed or failed, and what to fix if they failed."
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
                "passed": False,
                "reason": f"AI Evaluation failed: {str(e)}. Please ensure your output exactly matches the expected output."
            }

# Singleton instance
ai_evaluator = AIEvaluator()
