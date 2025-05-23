# Local LLM Configuration Tutorial

## Installation and Setup

1. Install Ollama or use your own locally trained LLM
2. Ollama uses 11434 by default, so make sure to set your API endpoint to `http://localhost:11434/api/generate`

   ```bash
   # If using Ollama, install models:
   ollama pull gemma3
   # OR
   ollama pull deepseek-r1

   # Then run the desired model:
   ollama run gemma3
   # OR
   ollama run deepseek-r1
   ```

## Config Structure

[`./python/`](.\python)

- [`python/llm_config.json`](.\python\llm_config.json) $\rarr$ main config
- [`python/local_llm_config.json`](.\python\local_llm_config.json) $\rarr$ config for local LLMs
- [`python/local_llm_configs/`](.\python\local_llm_configs) $\rarr$ contains model-specific config files

local_llm_config.json file acts as your “currently active model” configuration.

This is the file that gets loaded when you specify “config_path”: “local_llm_config.json” in your main config.

**Default Configuration Structure:**

Create or edit your local_llm_config.json with:  
```json
{
  "api_endpoint": "http://localhost:11434/api/generate",
  "model": "deepseek-r1", // Change this to your model name
  "supports_vision": false,
  "request_format": {
    "model": "{model}",
    "prompt": "{prompt}",
    "stream": false,
    "options": {
      "temperature": 0.7,
      "max_tokens": 1024
    }
  },
  "response_field": "response"
}
```

### **Key Configuration Options**

Basic Settings:

- api_endpoint: The Ollama API endpoint (always http://localhost:11434/api/generate for Ollama)
- model: The exact model name as it appears in ollama list
- supports_vision: Set to false for most models (only certain models support images)

Request Format:

- options.temperature: Controls randomness (For deepseek specifically, 0.1 \= very predictable, 1.0 \= default, 1.5 \= very creative)
- options.max_tokens: Maximum response length

Response Handling:

- response_field: Tells the system where to find the generated text in Ollama's response (always "response" for Ollama)

Finding Your Exact Model Name:

To ensure you're using the correct model name, run:

ollama list

Look for the exact name in the output. For example, if you see:

deepseek-r1:latest abc123 4.2 GB 2 days ago

Then use `"model": "deepseek-r1:latest"` in your config.

**Model Specific Configurations:**

The local_llm_configs/ folder contains individual configuration files for each model you want to use. This allows you to easily switch between models and have different settings optimized for each one.

### **Creating Model-Specific Config Files**

Each model gets its own JSON file in the local_llm_configs/ directory. Here are examples for your models:

### **Ex: deepseek_config.json**

```json
{
	"api_endpoint": "http://localhost:11434/api/generate",
	"model": "deepseek-r1",
	"supports_vision": false,
	"request_format": {
		"model": "{model}",
		"prompt": "{prompt}",
		"stream": false,
		"options": {
			"temperature": 0.7,
			"max_tokens": 1024
		}
	},
	"response_field": "response",
	"code_settings": {
		"options": {
			"temperature": 0.2
		}
	},
	"goal_settings": {
		"options": {
			"temperature": 0.8
		}
	}
}
```

### **Customizing for Your Needs**

You can adjust these settings based on your experience:

**If agents are making poor decisions:**

- Lower the temperature values
- Increase max_tokens if responses are being cut off

**If agents are too predictable:**

- Raise the temperature values
- Increase goal_settings temperature for more creative goals

**If code generation is unreliable:**

- Lower code_settings temperature even further (try 0.05)
- Consider switching to DeepSeek for better coding performance
