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
                "model": "gpt-4o-mini"
            }
        
        service = config['service'].lower()
        model = config['model']
        
        # Create the appropriate service
        if service == "openai":
            return OpenAIServiceAdapter(model, config_path)
        elif service == "gemini":
            return GeminiServiceAdapter(model, config_path)
        elif service == "local":
            return LocalLLMServiceAdapter(model, config_path)
        else:
            raise ValueError(f"Unknown service type: {service}")