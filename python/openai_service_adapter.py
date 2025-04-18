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
    
    def __init__(self, model="gpt-4o", settings=None):
        super().__init__(model=model, settings=settings)

        # Initialize client with explicit API key
        self.client = OpenAI(api_key=self.api_key)
        
        print(f"Initialized OpenAI service with model: {self.model}")
    
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