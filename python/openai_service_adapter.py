import json
from typing import Optional
from openai import OpenAI
from pydantic import BaseModel
from llm_service import LLMService

class LinesOfCodeWithinFunction(BaseModel):
    line_of_code_of_function: list[str]

class Goal(BaseModel):
    plaintext_goal: str

class OpenAIServiceAdapter(LLMService):
    """Adapter for OpenAI service with vision support"""
    
    def __init__(self, model="gpt-4o", settings=None):
        """Initialize the OpenAI service adapter"""
        self.settings = settings or {}
        self.model = model
        
        # Get API key from settings or environment
        api_key = self.settings.get("api_key")
        if not api_key:
            from llm_service import load_api_keys
            api_keys = load_api_keys()
            api_key = api_keys["openai"]
        
        if not api_key:
            raise ValueError("OpenAI API key not found! Please set it in the .env.development.local file or provide it in the settings.")
        
        # Initialize client with explicit API key
        self.client = OpenAI(api_key=api_key)
        
        print(f"Initialized OpenAI service with model: {self.model}")
        
        # System prompt - same as in original implementation
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
        """
        
        print(f"Initialized OpenAI service with model: {self.model}")
    
    @property
    def supports_vision(self) -> bool:
        """OpenAI gpt-4o and gpt-4o-mini supports vision"""
        return self.model in ["gpt-4o", "gpt-4o-mini", "gpt-4-vision"]
    
    async def generate_script(self, prompt: str, image_data: Optional[str] = None) -> str:
        """Generate a script using OpenAI with optional image data"""
        
        # Format the messages based on whether we have image data
        if image_data and self.supports_vision:
            messages = [
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": [
                    {"type": "text", "text": f"{prompt}\n{self.user_preprompt}"},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/png;base64,{image_data}",
                        }
                    }
                ]}
            ]
        else:
            messages = [
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": prompt + "\n" + self.user_preprompt},
            ]
        
        # Call the API
        completion = self.client.beta.chat.completions.parse(
            model=self.model,
            messages=messages,
            response_format=LinesOfCodeWithinFunction,
            temperature=self.settings.get("temperature", 0.7),
        )
        
        response = json.loads(completion.choices[0].message.content)
        
        # Format the lines with proper indentation and join them
        code_lines = response["line_of_code_of_function"]
        code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]
     
        # Add a newline and tab to the beginning of each line
        formatted_code = "\n\t" + "\n\t".join(code_lines)
        print(f"OpenAI generated script (length: {len(formatted_code)} chars)")
        return formatted_code
    
    async def generate_goal(self, context: str, image_data: Optional[str] = None) -> str:
        """Generate a goal using OpenAI with optional image data"""
        
        # Format the messages based on whether we have image data
        if image_data and self.supports_vision:
            messages = [
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": [
                    {"type": "text", "text": context},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/png;base64,{image_data}",
                        }
                    }
                ]}
            ]
        else:
            messages = [
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": context},
            ]
        
        # Call the API
        completion = self.client.beta.chat.completions.parse(
            model=self.model,
            messages=messages,
            response_format=Goal,
            temperature=self.settings.get("temperature", 0.7),
        )
        
        response = json.loads(completion.choices[0].message.content)
        goal = response["plaintext_goal"]
        print(f"OpenAI generated goal: {goal}")
        return goal
    
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