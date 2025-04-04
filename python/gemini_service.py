# gemini_service.py
import asyncio
import websockets
import json
import os
import re
from pydantic import BaseModel
from dotenv import load_dotenv

# Import the Google GenerativeAI library correctly
import google.generativeai as genai

# Load environment variables for API key
load_dotenv("./.env.development.local")
if not os.path.exists("./.env.development.local"):
    load_dotenv("./.env")

# Define response models similar to your OpenAI implementation
class LinesOfCodeWithinFunction(BaseModel):
    line_of_code_of_function: list[str]

class Goal(BaseModel):
    plaintext_goal: str

class GeminiService:
    """Implementation for Google's Gemini API using the official Google AI SDK"""
    
    def __init__(self, api_key=None, model="gemini-2.0-flash"):
        """Initialize the Gemini service"""
        self.api_key = api_key or os.environ.get("GEMINI_API_KEY")
        self.model = model
        
        print(f"Initializing GeminiService with model: {self.model}")
        
        # Initialize the Gemini client with correct API
        genai.configure(api_key=self.api_key)
        
        # Configure generation settings for code generation (low temperature for predictability)
        self.code_generation_config = genai.GenerationConfig(
            temperature=0.2,  # Low temperature for consistent, predictable code
            top_p=0.9,
            top_k=20
        )
        
        # Configure generation settings for goal generation (higher temperature for creativity)
        self.goal_generation_config = genai.GenerationConfig(
            temperature=0.8,  # Higher temperature for more creative goals
            top_p=0.95,
            top_k=50
        )
        
        # System prompt - keeping the same one you use for OpenAI
        self.system_prompt = """
        You are an autonomous agent in a 3D world. You'll be called after completing previous actions to decide what to do next.

        FUNCTION REFERENCE:
        - get_position() -> Vector3 - Get your current position
        - move_to_position(x, y) [REQUIRES AWAIT] - Move to coordinates, returns true when reached
        - say(message) - Broadcast a message to all nearby agents
        - say_to(message, target_id) - Send a message to a specific agent
        - get_nearby_agents() -> Array[int] - Get IDs of nearby agents
        - eat_food() - Restore your hunger by 10 points

        IMPORTANT: Functions marked with [REQUIRES AWAIT] MUST be called with the await keyword:
        CORRECT EXAMPLE:
        var reached = await move_to_position(30, 0)
        if reached:
            say("I've arrived!")

        INCORRECT EXAMPLE:
        var reached = move_to_position(30, 0)  # ERROR: Missing await!

        Distances are meters, so anything within 1 meter is considered "nearby".

        Remember:
        1. Your goal is defined by you, and can be anything given your constraints and abilities.
        2. Keep your code simple and focused on the immediate next steps to achieve your goal.
        3. Your code will execute fully before you're called again for the next action.
        4. You don't need to explicitly complete goals - the game will handle that for you.
        5. If you receive messages from other agents, you can choose how to respond based on your current goal.
        """
        
        # User preprompt for script generation
        self.user_preprompt = """
        Provide the list of functions you would like to call to achieve the goal.
        Remember that you're a persistent agent in an ongoing simulation - you'll be recalled after your code completes.

        Your responses should focus on immediate actions. For a PENDING goal, work toward completing it. For a COMPLETED or FAILED goal, set a new goal based on the situation.

        Changes in Godot 4.3 you MUST ADHERE TO:
        - deg2rad is now deg_to_rad() in Godot 4.3
        - OS.get_ticks_msec() is now Time.get_ticks_msec() in Godot 4.3
        - yield() is deprecated in Godot 4.3, don't use it at all

        You are writing the body of the function "func eval()", which is called only once.
        Ensure the code is Godot 4.3 compatible.
        
        Provide your response in the following JSON format:
        {
            "line_of_code_of_function": [
                "var line1 = 'code'",
                "var line2 = 'more code'",
                "..."
            ]
        }
        """
        
    async def server(self, websocket):
        """Handle websocket messages"""
        try:
            async for message in websocket:
                prompt = ""

                if message.startswith("GOAL "):
                    prompt = message[len("GOAL "):]
                    print(f"\n[DEBUG] Received GOAL request with prompt: {prompt[:50]}...")
                    goal = await self.generate_goal(context=prompt)
                    await websocket.send(goal)
                    print(f"[DEBUG] Generated goal: {goal}")
                elif message.startswith("SCRIPT "):
                    prompt = message[len("SCRIPT "):]
                    print(f"\n[DEBUG] Received SCRIPT request with prompt: {prompt[:50]}...")
                    code = await self.generate_script(prompt=prompt)
                    await websocket.send(code)
                    print(f"[DEBUG] Generated script:\n{code}")
        except Exception as e:
            print(f"Error in Gemini service: {e}")

    async def generate_script(self, prompt: str):
        """Generate a script using Gemini with low temperature for consistency"""
        try:
            # Format the prompt with system instructions and user prompt
            full_prompt = f"{self.system_prompt}\n\n{prompt}\n{self.user_preprompt}"
            print(f"[DEBUG] Sending script prompt to Gemini (length: {len(full_prompt)} chars)")
            print(f"[DEBUG] Using low temperature: {self.code_generation_config.temperature} for stable code generation")
            
            # Get Gemini model
            model = genai.GenerativeModel(self.model)
            
            # Make request to Gemini API through the client
            print("[DEBUG] Calling Gemini API...")
            response = await asyncio.to_thread(
                model.generate_content,
                full_prompt,
                generation_config=self.code_generation_config  # Use code-specific config
            )
            
            # Extract the text from the response
            content = response.text
            print(f"\n[DEBUG] Raw Gemini response:\n{'-'*40}\n{content}\n{'-'*40}")
            
            # Try to parse as JSON
            try:
                # First, find JSON blocks if the response has markdown formatting
                json_match = re.search(r'```(?:json)?\s*({.*?})\s*```', content, re.DOTALL)
                if json_match:
                    print("[DEBUG] Found JSON block in markdown")
                    content = json_match.group(1)
                
                print(f"[DEBUG] Attempting to parse as JSON: {content[:100]}...")
                content_json = json.loads(content)
                code_lines = content_json.get("line_of_code_of_function", [])
                print(f"[DEBUG] Successfully parsed JSON, found {len(code_lines)} lines of code")
            except json.JSONDecodeError as e:
                # Fall back to extracting code directly
                print(f"[DEBUG] JSON parse error: {e}. Extracting code directly...")
                lines = content.split("\n")
                # Filter for code-like lines (basic heuristic)
                code_lines = []
                in_code_block = False
                for line in lines:
                    stripped = line.strip()
                    if stripped.startswith("```") and not in_code_block:
                        in_code_block = True
                        continue
                    elif stripped.startswith("```") and in_code_block:
                        in_code_block = False
                        continue
                        
                    if in_code_block or (not stripped.startswith("#") and stripped and not stripped.startswith("```")):
                        code_lines.append(line)
                print(f"[DEBUG] Extracted {len(code_lines)} lines of code from text")
            
            # Process the code lines
            print(f"[DEBUG] Processing code lines: replacing tabs and deg2rad references")
            code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]
            formatted_code = "\n\t" + "\n\t".join(code_lines)
            print(f"[DEBUG] Final formatted code (length: {len(formatted_code)} chars)")
            return formatted_code
                
        except Exception as e:
            print(f"[DEBUG] Error generating script with Gemini: {e}")
            import traceback
            traceback.print_exc()
            return "\n\t# Exception in Gemini script generation"

    async def generate_goal(self, context: str):
        """Generate a goal using Gemini with higher temperature for creativity"""
        try:
            # Format the prompt for goal generation
            full_prompt = f"""{self.system_prompt}

{context}

Based on the situation described, provide a single plain text goal that you will pursue. 
Be creative and ambitious with your goals while staying within your capabilities.
Respond with your goal in the following JSON format:
{{
    "plaintext_goal": "Your goal here"
}}
"""
            print(f"[DEBUG] Sending goal prompt to Gemini (length: {len(full_prompt)} chars)")
            print(f"[DEBUG] Using higher temperature: {self.goal_generation_config.temperature} for creative goal generation")
            
            # Get Gemini model
            model = genai.GenerativeModel(self.model)
            
            # Make request to Gemini API through the client
            print("[DEBUG] Calling Gemini API for goal...")
            response = await asyncio.to_thread(
                model.generate_content,
                full_prompt,
                generation_config=self.goal_generation_config  # Use goal-specific config
            )
            
            # Extract the text from the response
            content = response.text
            print(f"\n[DEBUG] Raw Gemini goal response:\n{'-'*40}\n{content}\n{'-'*40}")
            
            # Try to parse as JSON
            try:
                # First, find JSON blocks if the response has markdown formatting
                json_match = re.search(r'```(?:json)?\s*({.*?})\s*```', content, re.DOTALL)
                if json_match:
                    print("[DEBUG] Found JSON block in markdown")
                    content = json_match.group(1)
                
                print(f"[DEBUG] Attempting to parse goal as JSON: {content[:100]}...")
                content_json = json.loads(content)
                goal = content_json.get("plaintext_goal", "")
                if goal:
                    print(f"[DEBUG] Successfully parsed JSON goal: {goal}")
                    return goal
            except json.JSONDecodeError as e:
                # If not valid JSON, extract first line as goal
                print(f"[DEBUG] JSON parse error for goal: {e}. Extracting text directly...")
                
            # Fallback: extract a reasonable goal from text
            lines = content.split("\n")
            for line in lines:
                line = line.strip()
                if line and not line.startswith("#") and not line.startswith("```"):
                    # Basic heuristic: first non-empty, non-comment line is probably the goal
                    print(f"[DEBUG] Extracted goal from text: {line}")
                    return line
            
            print("[DEBUG] No suitable goal found, using default")        
            return "Explore the world"
                
        except Exception as e:
            print(f"[DEBUG] Error generating goal with Gemini: {e}")
            import traceback
            traceback.print_exc()
            return "Explore the world"

    async def start(self, host="localhost", port=5000):
        """Start the websocket server"""
        server = await websockets.serve(
            self.server, 
            host, 
            port, 
            ping_interval=30, 
            ping_timeout=10, 
            max_size=1024*1024
        )
        print(f"Gemini service started on {host}:{port}")
        await server.wait_closed()

# Example usage
async def main():
    print("Starting Gemini Service...")
    gemini_service = GeminiService()
    print("Gemini Service initialized, starting server...")
    await gemini_service.start()

if __name__ == "__main__":
    asyncio.run(main())