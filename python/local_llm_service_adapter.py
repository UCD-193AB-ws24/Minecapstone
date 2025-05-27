from llm_service import LLMService
import requests
import json
import re
from typing import Optional, Dict, Any
import os

class LocalLLMServiceAdapter(LLMService):
    """Adapter for any locally run LLM"""

    def __init__(self, model="example", config_path: Optional[str] = None):
        super().__init__("local", model, config_path)

        # TODO: fix this
    
        # Get basic configuration
        self.api_endpoint = self.config.get("api_endpoint", "http://localhost:11434/api/generate")
        self.model_name = model or self.config.get("model", "")
        self.timeout = self.config.get("timeout", 30)  # seconds
        
        print(f"Initialized Local LLM service with endpoint: {self.api_endpoint}")
        if self.model_name:
            print(f"Using model: {self.model_name}")

    def load_config(self, config_path: str) -> dict:
        config_path = super().load_config(config_path)["config_path"]
        config_path = "./python/" + config_path
        local_llm_config = {}
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                local_llm_config = json.load(f)
        else:
            print(f"Local LLM config file not found: {config_path}")
        return local_llm_config

    @property
    def supports_vision(self) -> bool:
        """Check if model supports vision"""
        return self.config.get("supports_vision", False)
    
    async def generate_script(self, prompt: str, image_data: Optional[str] = None) -> str:
        """Generate a script using local LLM with optional image data"""
        full_prompt = f"{self.system_prompt}\n\n{prompt}\n\n{self.user_preprompt}"

        try:
            import asyncio
            response_text = await asyncio.to_thread(
                self._make_api_request,
                full_prompt,
                image_data,
                "code"  # Specify request_type for script generation
            )

            code = self._extract_code(response_text)

            # Format the code for Godot
            code_lines = code.split("\n")
            code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]
            formatted_code = "\n\t" + "\n\t".join(code_lines)

            return formatted_code

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
        
        try:
            import asyncio
            response_text = await asyncio.to_thread(
                self._make_api_request,
                full_prompt,
                image_data,
                "goal"  # Specify request_type for goal generation
            )

            goal = self._extract_goal(response_text)
            print(f"Local LLM generated goal: {goal}")
        
            return goal
        
        except Exception as e:
            print(f"Error generating goal with Local LLM: {e}")
            return "Failed to generate goal"  # Add a default return value for error case

    def _make_api_request(self, prompt: str, image_data: Optional[str] = None, request_type: str = "general") -> str:
        """Make a request to the local LLM API"""
        # Get request format from config, or use default
        request_format = self.config.get("request_format", {"prompt": "{prompt}"})
        
        # Create a copy of the request format
        payload = {}
        for key, value in request_format.items():
            if isinstance(value, str):
                # Replace placeholders
                processed_value = value.replace("{prompt}", prompt)
                if "{model}" in processed_value and self.model_name:
                    processed_value = processed_value.replace("{model}", self.model_name)
                payload[key] = processed_value
            else:
                # Copy other values as is
                payload[key] = value
        
        # Add image if supported
        if image_data and self.supports_vision:
            image_field = self.config.get("image_field", "images")
            payload[image_field] = [image_data]
        
        # Apply type-specific settings
        if request_type == "code" and "code_settings" in self.config:
            for key, value in self.config["code_settings"].items():
                payload[key] = value
        elif request_type == "goal" and "goal_settings" in self.config:
            for key, value in self.config["goal_settings"].items():
                payload[key] = value
        
        # Make the request
        headers = {"Content-Type": "application/json"}
        if "headers" in self.config:
            headers.update(self.config["headers"])

        #print(payload)
        
        response = requests.post(
            self.api_endpoint,
            json=payload,
            headers=headers,
            timeout=self.timeout
        )
        
        # Handle non-200 responses
        if response.status_code != 200:
            raise Exception(f"API returned status {response.status_code}: {response.text}")
        
        # Try to parse JSON response
        try:
            result = response.json()
            
            # Use configured response field if specified
            response_field = self.config.get("response_field", None)
            if response_field and response_field in result:
                return result[response_field]
            
            # Check common response fields
            for field in ["text", "content", "response", "output", "generated_text"]:
                if field in result:
                    return result[field]
            
            # Fall back to the full response
            return str(result)
            
        except ValueError:
            # Not JSON, return text directly
            return response.text
        
    def _extract_code(self, text: str) -> str:
        """Helper method: extract code from the response text"""
        # Look for code blocks
        code_match = re.search(r'```(?:python|gdscript)?\s*(.*?)```', text, re.DOTALL)
        if code_match:
            return code_match.group(1).strip()
        
        # Try to parse JSON format
        try:
            data = json.loads(text)
            if "line_of_code_of_function" in data:
                return "\n".join(data["line_of_code_of_function"])
        except (json.JSONDecodeError, TypeError):
            pass
        
        # Assume the entire text is code (simple approach)
        return text
    
    def _extract_goal(self, text: str) -> str:
        """Extract a goal from the response text"""
        # Try to parse JSON response
        try:
            data = json.loads(text)
            if "plaintext_goal" in data:
                return data["plaintext_goal"]
        except (json.JSONDecodeError, TypeError):
            pass
        
        # Clean up the text (remove markdown, etc.)
        cleaned = re.sub(r'```.*?```', '', text, flags=re.DOTALL)
        lines = cleaned.strip().split('\n')
        
        # Find the first non-empty, non-header line
        for line in lines:
            line = line.strip()
            if line and not line.startswith('#') and line != "Goal:":
                # Clean up the line
                line = re.sub(r'^[*-] ', '', line)
                line = re.sub(r'^Goal: ', '', line)
                return line
        
        # Fall back to default
        return "No goal generated"