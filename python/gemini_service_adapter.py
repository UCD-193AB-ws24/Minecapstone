import json
import re
import asyncio
import google.generativeai as genai
from typing import Optional
from llm_service import LLMService

class GeminiServiceAdapter(LLMService):
    """Adapter for Google's Gemini API with vision support"""
    
    def __init__(self, model="gemini-2.0-flash", settings=None):
        super().__init__(model=model, settings=settings)
        
        # Initialize the Gemini client with explicit API key
        print(f"Configuring Gemini with API key")
        genai.configure(api_key=self.api_key)
        
        # Load specific model settings if available
        self.config = settings or {}
        
        # Support for model-specific configurations
        if "model_configs" in self.config and self.model_name in self.config["model_configs"]:
            model_config = self.config["model_configs"][self.model_name]
            # Update settings with model-specific ones
            for key, value in model_config.items():
                if key not in self.config:
                    self.config[key] = value
        
        # Configure generation settings for code generation (low temperature for predictability)
        self.code_generation_config = genai.GenerationConfig(
            temperature=self.config.get("code_temperature", 0.2),
            top_p=self.config.get("code_top_p", 0.9),
            top_k=self.config.get("code_top_k", 20)
        )
            
        # Configure generation settings for goal generation (higher temperature for creativity)
        self.goal_generation_config = genai.GenerationConfig(
            temperature=self.config.get("goal_temperature", 0.8),
            top_p=self.config.get("goal_top_p", 0.95),
            top_k=self.config.get("goal_top_k", 50)
        )
        
        print(f"Initialized Gemini service with model: {self.model}")

    @property
    def supports_vision(self) -> bool:
        """Return whether this model supports vision"""
        if "supports_vision" in self.config:
            return self.config["supports_vision"]
        # Default check for known models
        return "gemini" in self.model_name and any(version in self.model_name for version in ["1.5", "2.0"])
    
    async def generate_script(self, prompt: str, image_data: Optional[str] = None) -> str:
        """Generate a script using Gemini with optional image data"""
        try:
            # Format the prompt with system instructions and user prompt
            full_prompt = f"{self.system_prompt}\n\n{prompt}\n{self.user_preprompt}"
            
            # Get Gemini model
            model = genai.GenerativeModel(self.model)
            
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
            model = genai.GenerativeModel(self.model)
            
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