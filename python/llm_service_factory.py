import json
from llm_service import LLMService
from openai_service_adapter import OpenAIServiceAdapter
from gemini_service_adapter import GeminiServiceAdapter
from local_llm_service_adapter import LocalLLMServiceAdapter


class LLMServiceFactory:
    """Factory for creating model instances"""
    
    @staticmethod
    def get_service(config_path) -> LLMService:
        """Create an LLM service based on the provided configuration file"""
        
        # Load the configuration
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
        except FileNotFoundError:
            print(f"Config file {config_path} not found. Using default OpenAI configuration.")
            config = {
                "service": "openai",
                "model": "gpt-4o"
            }
        
        service_type = config.get("service", "openai").lower()
        model = config.get("model", "")
        
        # Create the appropriate service
        if service_type == "openai":
            return OpenAIServiceAdapter(model, config_path)
        elif service_type == "gemini":
            return GeminiServiceAdapter(model, config_path)
        elif service_type == "local":
            return LocalLLMServiceAdapter(model, config_path)
        else:
            raise ValueError(f"Unknown service type: {service_type}")