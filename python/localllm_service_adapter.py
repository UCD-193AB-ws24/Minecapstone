from llm_service import LLMService
import requests
import json
import re
from typing import Optional, Dict, Any

class LocalLLMService(LLMService):
    """Adapter for any locally run LLM"""

    def __init__(self, model="default", settings = None):
        super().__init__(model = model, settings = settings)

        # Need configurations for local LLM
        # api.endpoint
        # api type
        # supports 

        print(f"Initialized Local LLM service with endppint: {self.api.endpoint}")

    @property
    def supports_vision(self) -> bool:
        """Check if model supports vision"""
        return False  # Placeholder, adjust based on actual local LLM capabilities
    
    async def generate_script(self, prompt: str, image_data: Optional[str] = None) -> str:
        """Generate a script using local LLM with optional image data"""
        full_prompt = f"{self.system_prompt}\n\n{prompt}\n\n{self.user_preprompt}"

        try:
            import asyncio
            response_text = await asyncio.to_thread(
                self.make_api_request,
                full_prompt,
                image_data
            )

            code = self._extract_code(response_text)

            # Format the code for Godot
            code_lines = code.split("\n")
            code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]
            formatted_code = "\n\t" + "\n\t".join(code_lines)

        except Exception as e:
            print(f"Error generating script with Local LLM: {e}")
            return "\n\t# Error generating script with Local LLM"

    async def generate_goal(self, context: str, image_data: Optional[str] = None) -> str:
        """Generate a goal using local LLM with optional image data"""
        full_prompt = f"""{self.system_prompt}

{context}

Based on the situation described, provide a single plain text goal that you will pursue. 
Be creative and ambitious while staying within your capabilities.
Your response should be a single sentence or short paragraph goal only.
"""