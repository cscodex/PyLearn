from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from typing import Any
from sqlalchemy.ext.asyncio import AsyncSession
import asyncio
import queue
import json
import threading

from app.api import deps
from app.models.user import User
from app.schemas.execution import CodeExecutionRequest, CodeExecutionResponse, EvaluationRequest, EvaluationResponse
from pydantic import BaseModel
from app.services.code_execution import execute_python_code, _run_in_process_interactive, check_code_security, CodeExecutionError
from app.services.ai_evaluator import ai_evaluator
from app.models.assessment import CodingChallenge, TestCase, CodeSubmission
from sqlalchemy import select

router = APIRouter()

@router.post("/", response_model=CodeExecutionResponse)
async def execute_code(
    request: CodeExecutionRequest,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Execute python code securely."""
    
    result = await execute_python_code(request.code, standard_input=request.standard_input)
    
    # Add XP if successful
    xp_earned = 5 if result["is_success"] else 0
    if xp_earned > 0:
        current_user.xp += xp_earned
        # Update streak logic here eventually
        db.add(current_user)
        await db.commit()
        await db.refresh(current_user)
        
    return CodeExecutionResponse(
        stdout=result["stdout"],
        stderr=result["stderr"],
        execution_time_ms=result["execution_time_ms"],
        is_success=result["is_success"],
        xp_earned=xp_earned,
        plots=result.get("plots", [])
    )

class ComplexityAnalysisRequest(BaseModel):
    code: str

@router.post("/analyze_complexity")
async def analyze_complexity(
    request: ComplexityAnalysisRequest,
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Analyze Python code complexity using AI."""
    result = await ai_evaluator.analyze_complexity(request.code)
    return result

@router.websocket("/ws")
async def execute_code_ws(websocket: WebSocket):
    await websocket.accept()
    
    out_queue = queue.Queue()
    in_queue = queue.Queue()
    
    try:
        # 1. Receive the initial code payload
        data = await websocket.receive_text()
        payload = json.loads(data)
        code = payload.get("code", "")
        
        # Security Check
        try:
            check_code_security(code)
        except CodeExecutionError as e:
            await websocket.send_json({"type": "stderr", "data": str(e) + "\n"})
            await websocket.send_json({"type": "completed"})
            await websocket.close()
            return
            
        # 2. Start the execution thread
        execution_thread = threading.Thread(
            target=_run_in_process_interactive,
            args=(code, out_queue, in_queue),
            daemon=True
        )
        execution_thread.start()
        
        # 3. Create a task to push output to websocket
        async def output_sender():
            while True:
                try:
                    # Non-blocking check or short timeout
                    msg = await asyncio.to_thread(out_queue.get, True, 0.1)
                    await websocket.send_json(msg)
                    if msg.get("type") == "completed":
                        break
                except queue.Empty:
                    if not execution_thread.is_alive():
                        await websocket.send_json({"type": "completed"})
                        break
                    await asyncio.sleep(0.01)
                except WebSocketDisconnect:
                    break
                except Exception as e:
                    break

        sender_task = asyncio.create_task(output_sender())
        
        # 4. Listen for user input
        while True:
            try:
                recv_data = await websocket.receive_text()
                recv_payload = json.loads(recv_data)
                if recv_payload.get("action") == "input":
                    in_queue.put(recv_payload.get("data", ""))
            except WebSocketDisconnect:
                break
                
        # Clean up
        sender_task.cancel()
        
    except WebSocketDisconnect:
        pass
    except Exception as e:
        try:
            await websocket.send_json({"type": "stderr", "data": f"Server error: {e}\n"})
        except:
            pass

@router.post("/evaluate", response_model=EvaluationResponse)
async def evaluate_code(
    request: EvaluationRequest,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Evaluate python code against hidden test cases."""
    
    # 1. Fetch challenge and test cases
    if request.challenge_id:
        chal_res = await db.execute(select(CodingChallenge).filter(CodingChallenge.id == request.challenge_id))
    elif request.lesson_id:
        chal_res = await db.execute(select(CodingChallenge).filter(CodingChallenge.lesson_id == request.lesson_id))
    else:
        raise HTTPException(status_code=400, detail="Must provide either challenge_id or lesson_id")
        
    challenge = chal_res.scalars().first()
    
    test_cases = []
    if challenge:
        test_res = await db.execute(select(TestCase).filter(TestCase.challenge_id == challenge.id).order_by(TestCase.order_index))
        test_cases = test_res.scalars().all()
        
    # Auto-generate challenge and test case if not found but lesson has solution_code
    if not test_cases and request.lesson_id:
        from app.models.course import Lesson
        lesson_res = await db.execute(select(Lesson).filter(Lesson.id == request.lesson_id))
        lesson = lesson_res.scalars().first()
        
        if lesson and lesson.content_body and lesson.content_body.get('solution_code'):
            solution_code = lesson.content_body['solution_code']
            
            # 1. Create the missing CodingChallenge
            if not challenge:
                challenge = CodingChallenge(
                    lesson_id=lesson.id,
                    title=lesson.title,
                    description=lesson.content_body.get('text', ''),
                    difficulty='beginner',
                    xp_reward=lesson.xp_reward or 10
                )
                db.add(challenge)
                await db.commit()
                await db.refresh(challenge)
                
            # 2. Run the solution code to get the expected output
            sol_result = await execute_python_code(solution_code)
            expected_out = sol_result["stdout"] if sol_result["is_success"] else "Solution code failed"
            
            # 3. Create a TestCase
            tc = TestCase(
                challenge_id=challenge.id,
                input_data="",
                expected_output=expected_out,
                is_hidden=False,
                order_index=0
            )
            db.add(tc)
            await db.commit()
            await db.refresh(tc)
            
            test_cases.append(tc)
            
    if not challenge or not test_cases:
        raise HTTPException(status_code=404, detail="Coding challenge not found and no solution code provided in the lesson.")
        
    # 2. Run execution synchronously for each test case
    total_cases = len(test_cases)
    total_score = 0.0
    passed_cases = 0
    test_results = []
    total_time_ms = 0
    
    for tc in test_cases:
        result = await execute_python_code(request.code, standard_input=tc.input_data)
        
        expected = str(tc.expected_output).strip()
        actual = str(result["stdout"]).strip()
        
        is_passed = result["is_success"] and expected == actual
        tc_score = 100.0 if is_passed else 0.0
        ai_reason = None
        
        # If exact match fails but code ran successfully, try AI evaluation!
        if not is_passed and result["is_success"]:
            ai_result = await ai_evaluator.evaluate(
                prompt=challenge.description,
                expected_output=expected,
                actual_output=actual,
                source_code=request.code
            )
            tc_score = float(ai_result.get("score", 0))
            is_passed = tc_score == 100.0
            ai_reason = ai_result.get("reason", None)

        if is_passed:
            passed_cases += 1
            
        total_time_ms += result["execution_time_ms"]
        total_score += tc_score
        
        # Determine error string
        error_msg = result["stderr"] if not result["is_success"] else None
        if not is_passed and not error_msg and ai_reason:
            error_msg = f"AI Feedback: {ai_reason} (Score: {tc_score}%)"

        test_results.append({
            "test_case_id": tc.id,
            "passed": is_passed,
            "expected_output": expected if not tc.is_hidden else "Hidden",
            "actual_output": actual if not tc.is_hidden else ("Hidden" if not result["stderr"] else result["stderr"]),
            "is_hidden": tc.is_hidden,
            "error": error_msg
        })
        
    # 3. Calculate score and XP
    score = total_score / total_cases if total_cases > 0 else 0.0
    
    # We consider it "completed" if they scored at least 80%
    status = "completed" if score >= 80.0 else "failed"
    
    xp_earned = 0
    if score > 0:
        xp_earned = int((score / 100.0) * challenge.xp_reward)
        current_user.xp += xp_earned
        db.add(current_user)
        
    # 4. Save CodeSubmission
    submission = CodeSubmission(
        user_id=current_user.id,
        challenge_id=challenge.id,
        source_code=request.code,
        status=status,
        score=score,
        test_cases_passed=passed_cases,
        test_cases_total=total_cases,
        execution_time_ms=total_time_ms,
        test_results=test_results,
        xp_earned=xp_earned
    )
    db.add(submission)
    await db.commit()
    await db.refresh(submission)
    
    return EvaluationResponse(
        submission_id=submission.id,
        status=status,
        score=score,
        test_cases_passed=passed_cases,
        test_cases_total=total_cases,
        execution_time_ms=total_time_ms,
        test_results=test_results,
        xp_earned=xp_earned
    )
