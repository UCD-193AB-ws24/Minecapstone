import json
import re
import asyncio
import google.generativeai as genai
from typing import Optional
from llm_service import LLMService

class GeminiServiceAdapter(LLMService):
    """Adapter for Google's Gemini API with vision support"""
    
    def __init__(self, model="gemini-2.0-flash", settings=None):
        """Initialize the Gemini service adapter"""
        self.model_name = model
        self.settings = settings or {}
        
        # Get API key from settings or environment
        api_key = self.settings.get("api_key")
        if not api_key:
            from llm_service import load_api_keys
            api_keys = load_api_keys()
            api_key = api_keys["gemini"]
        
        if not api_key:
            raise ValueError("Gemini API key not found! Please set it in the .env.development.local file or provide it in the settings.")
        
        # Initialize the Gemini client with explicit API key
        print(f"Configuring Gemini with API key")
        genai.configure(api_key=api_key)
        
        # Configure generation settings for code generation (low temperature for predictability)
        self.code_generation_config = genai.GenerationConfig(
            temperature=self.settings.get("code_temperature", 0.2),
            top_p=self.settings.get("code_top_p", 0.9),
            top_k=self.settings.get("code_top_k", 20)
        )
            
        # Configure generation settings for goal generation (higher temperature for creativity)
        self.goal_generation_config = genai.GenerationConfig(
            temperature=self.settings.get("goal_temperature", 0.8),
            top_p=self.settings.get("goal_top_p", 0.95),
            top_k=self.settings.get("goal_top_k", 50)
        )
        
        # System prompt - keeping the same one used for OpenAI
        self.system_prompt = """
        You are an autonomous agent in a 3D world. You'll be called after completing previous actions to decide what to do next.

        FUNCTION REFERENCE:
        - get_position() -> Vector3 - Get your current position
        - say(message) - Broadcast a message to all nearby agents
        - say_to(message, target_id) - Send a message to a specific agent
        - select_nearest_entity_type(string target) - Select the nearest entity as the target. The argument target provides the name of the entity to target. If target is "", the nearest entity is selected.
        - move_to_position(x, y) [REQUIRES AWAIT] - Move to coordinates, returns true when reached
        - move_to_current_target() [REQUIRES AWAIT] - Move the agent to the current target position.
        - attack_current_target(int c) [REQUIRES AWAIT] - Attack the currently selected target. The argument c provides the number of times to attack.
        - eat_food() - Restore your hunger by 10 points

        IMPORTANT: Functions marked with [REQUIRES AWAIT] MUST be called with the await keyword:
        CORRECT EXAMPLE:
        var reached = await move_to_position(30, 0)
        if reached:
            say("I've arrived!")

        CORRECT EXAMPLE: Attacking functions are sensitive to how they are called:
        Example Prompt: "Attack the nearest zombie 3 times"
        CORRECT EXAMPLE:
        select_nearest_entity_type("zombie")
        await attack_current_target(3)

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
        
        print(f"Initialized Gemini service with model: {self.model_name}")
    
    @property
    def supports_vision(self) -> bool:
        """Return whether this model supports vision"""
        # Gemini 1.5/2.0 models support vision
        return "gemini" in self.model_name and any(version in self.model_name for version in ["1.5", "2.0"])
    
    async def generate_script(self, prompt: str, image_data: Optional[str] = None) -> str:
        """Generate a script using Gemini with optional image data"""
        try:
            # Format the prompt with system instructions and user prompt
            full_prompt = f"{self.system_prompt}\n\n{prompt}\n{self.user_preprompt}"
            
            # Get Gemini model
            model = genai.GenerativeModel(self.model_name)
            
            # Make request to Gemini API through the client
            if image_data and self.supports_vision:
                try:
                    # For Gemini with vision capabilities
                    import base64
                    import io
                    from PIL import Image
                    
                    # Decode base64 image
                    image_bytes = base64.b64decode(image_data)
                    image = Image.open(io.BytesIO(image_bytes))
                    
                    # Generate content with text and image
                    response = await asyncio.to_thread(
                        model.generate_content,
                        [full_prompt, image],
                        generation_config=self.code_generation_config
                    )
                except Exception as e:
                    print(f"Error processing image with Gemini: {e}")
                    # Fall back to text-only if image processing fails
                    response = await asyncio.to_thread(
                        model.generate_content,
                        full_prompt,
                        generation_config=self.code_generation_config
                    )
            else:
                # Text-only request
                response = await asyncio.to_thread(
                    model.generate_content,
                    full_prompt,
                    generation_config=self.code_generation_config
                )
            
            # Extract the text from the response
            content = response.text
            
            # Try to parse as JSON
            try:
                # First, find JSON blocks if the response has markdown formatting
                json_match = re.search(r'```(?:json)?\s*({.*?})\s*```', content, re.DOTALL)
                if json_match:
                    content = json_match.group(1)
                
                content_json = json.loads(content)
                code_lines = content_json.get("line_of_code_of_function", [])
            except json.JSONDecodeError:
                # Fall back to extracting code directly
                print("Warning: Gemini didn't return proper JSON. Extracting code directly...")
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
            
            fixed_code_lines = []
            for line in code_lines:
                # Fix code wrapped in single or double quotes (string literals)
                if (line.strip().startswith("var ") and 
                    ("= '" in line or '= "' in line) and
                    ("await " in line or "move_to_position" in line or "attack_current_target" in line)):
                    # Extract the actual code from the string literal
                    quote_start = line.find("'") if "'" in line else line.find('"')
                    quote_end = line.rfind("'") if "'" in line else line.rfind('"')
                    if quote_start > 0 and quote_end > quote_start:
                        actual_code = line[quote_start+1:quote_end]
                        # Replace the string literal with actual code
                        fixed_line = actual_code
                        print(f"Fixed Gemini code: '{line}' → '{fixed_line}'")
                        fixed_code_lines.append(fixed_line)
                    else:
                        fixed_code_lines.append(line)
                else:
                    fixed_code_lines.append(line)

            # Use the fixed code lines
            code_lines = fixed_code_lines
            
            # Process the code lines (existing code continues here)
            code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]
            formatted_code = "\n\t" + "\n\t".join(code_lines)
            print(f"Gemini generated script (length: {len(formatted_code)} chars)")
            return formatted_code
                
        except Exception as e:
            print(f"Error generating script with Gemini: {e}")
            import traceback
            traceback.print_exc()
            return "\n\t# Exception in Gemini script generation"

    async def generate_goal(self, context: str, image_data: Optional[str] = None) -> str:
        """Generate a goal using Gemini with optional image data"""
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
            
            # Get Gemini model
            model = genai.GenerativeModel(self.model_name)
            
            # Make request to Gemini API through the client
            if image_data and self.supports_vision:
                try:
                    # For Gemini with vision capabilities
                    import base64
                    import io
                    from PIL import Image
                    
                    # Decode base64 image
                    image_bytes = base64.b64decode(image_data)
                    image = Image.open(io.BytesIO(image_bytes))
                    
                    # Generate content with text and image
                    response = await asyncio.to_thread(
                        model.generate_content,
                        [full_prompt, image],
                        generation_config=self.goal_generation_config
                    )
                except Exception as e:
                    print(f"Error processing image with Gemini: {e}")
                    # Fall back to text-only if image processing fails
                    response = await asyncio.to_thread(
                        model.generate_content,
                        full_prompt,
                        generation_config=self.goal_generation_config
                    )
            else:
                # Text-only request
                response = await asyncio.to_thread(
                    model.generate_content,
                    full_prompt,
                    generation_config=self.goal_generation_config
                )
            
            # Extract the text from the response
            content = response.text
            
            # Try to parse as JSON
            try:
                # First, find JSON blocks if the response has markdown formatting
                json_match = re.search(r'```(?:json)?\s*({.*?})\s*```', content, re.DOTALL)
                if json_match:
                    content = json_match.group(1)
                
                content_json = json.loads(content)
                goal = content_json.get("plaintext_goal", "")
                if goal:
                    print(f"Gemini generated goal: {goal}")
                    return goal
            except json.JSONDecodeError:
                # If not valid JSON, extract first line as goal
                pass
                
            # Fallback: extract a reasonable goal from text
            lines = content.split("\n")
            for line in lines:
                line = line.strip()
                if line and not line.startswith("#") and not line.startswith("```"):
                    # Basic heuristic: first non-empty, non-comment line is probably the goal
                    print(f"Gemini extracted goal from text: {line}")
                    return line
                    
            return "Explore the world"
                
        except Exception as e:
            print(f"Error generating goal with Gemini: {e}")
            import traceback
            traceback.print_exc()
            return "Explore the world"
    
    async def handle_websocket_message(self, message_obj: dict) -> str:
        """Handle a websocket message with possible image data"""
        message = message_obj.get("prompt", "")
        image_data = message_obj.get("image_data", None)
        
        if message_obj.get("type") == "GOAL":
            return await self.generate_goal(message, image_data)
        elif message_obj.get("type") == "SCRIPT":
            return await self.generate_script(message, image_data)
        else:
            return "Error: Unknown message type"