import json
from llm_service import LLMService


class LLMServiceFactory:
    """Factory for creating model instances"""
    
    @staticmethod
    def get_service(config_path="config.json") -> LLMService:
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
        settings = config.get("settings", {})
        
        # Create the appropriate service
        if service_type == "openai":
            from openai_service_adapter import OpenAIServiceAdapter
            return OpenAIServiceAdapter(model=model, settings=settings)
        elif service_type == "gemini":
            from gemini_service_adapter import GeminiServiceAdapter
            return GeminiServiceAdapter(model=model, settings=settings)
        elif service_type == "local_llm":
            from local_llm_service_adapter import LocalLLMService
            return LocalLLMService(model=model, settings=settings)
        else:
            raise ValueError(f"Unknown service type: {service_type}")