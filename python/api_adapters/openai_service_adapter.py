import json
from typing import Optional
from pydantic import BaseModel
from openai import OpenAI
from llm_service import LLMService

class LinesOfCodeWithinFunction(BaseModel):
    line_of_code_of_function: list[str]

class Goal(BaseModel):
    plaintext_goal: str

class OpenAIServiceAdapter(LLMService):
    """Adapter for OpenAI service with vision support"""
    
    def __init__(self, model="gpt-4o-mini", config_path: Optional[str] = None):
        super().__init__("openai", model, config_path)

        # Initialize client with explicit API key
        self.client = OpenAI(api_key=self.api_key)
        
        print(f"Initialized OpenAI service with model: {self.model}")

    @property
    def supports_vision(self) -> bool:
        """Check if the model supports vision capabilities"""
        # TODO: use the actual config values rather than hardcoding
        # Default check for known models
        return self.model in ["gpt-4o", "gpt-4o-mini", "gpt-4-vision", "gpt-4.1"]
    
    async def generate_script(self, prompt, image_data: Optional[str] = None) -> str:
        """Generate a script using OpenAI with optional image data"""
        
        # Format the messages based on whether we have image data
        if image_data and self.supports_vision:
            user_prompt = prompt.pop()["content"]
            prompt.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": f"{user_prompt}"},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/png;base64,{image_data}",
                        }
                    }
                ]
            })
        
        # Get temperature from config
        temperature = self.config.get("code_temperature", self.config.get("temperature", 0.7))

        # Call the API
        completion = self.client.beta.chat.completions.parse(
            model=self.model,
            messages=prompt,
            response_format=LinesOfCodeWithinFunction,
            temperature=temperature,
        )
        
        response = json.loads(completion.choices[0].message.content)
        
        # Format the lines with proper indentation and join them
        code_lines = response["line_of_code_of_function"]
        code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]
     
        # Add a newline and tab to the beginning of each line
        formatted_code = "\n\t" + "\n\t".join(code_lines)
        return formatted_code
    
    async def generate_goal(self, context, image_data: Optional[str] = None) -> str:
        """Generate a goal using OpenAI with optional image data"""
        
        # Format the messages based on whether we have image data
        if image_data and self.supports_vision:
            user_prompt = context.pop()["content"]
            context.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": f"{user_prompt}"},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/png;base64,{image_data}",
                        }
                    }
                ]
            })
        
        # Get temperature from config
        temperature = self.config.get("goal_temperature", self.config.get("temperature", 0.7))
        
        # Call the API
        completion = self.client.beta.chat.completions.parse(
            model=self.model,
            messages=context,
            response_format=Goal,
            temperature=temperature,
        )
        
        response = json.loads(completion.choices[0].message.content)
        goal = response["plaintext_goal"]
        # print(f"OpenAI generated goal: {goal}")
        return goal