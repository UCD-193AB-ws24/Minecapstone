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
[``./python/``](.\python)
- [``python/llm_config.json``](.\python\llm_config.json)
- [``python/local_llm_config.json``](.\python\local_llm_config.json)
- [``python/local_llm_configs/``](.\python\local_llm_configs)
  - [``python/local_llm_configs/deepseek_config.json``](.\python\local_llm_configs\deepseek_config.json)
  - [``python/local_llm_configs/gemma_config.json``](.\python\local_llm_configs\gemma_config.json)



<!-- `python/`  
`-llm_config.json` 				\# Main config  
`-local_llm_config.json` 			\# Currently active model config  
`-local_llm_configs/` 				\# Model specific configs  
	`-gemma_config.json`  
	`-deepseek_config.json`

**Specify in llm\_config:**  
`“service”: “local_llm”,`  
`“settings”: {`  
	`“config_path”: “local_llm_config.json”`  
`}` -->

local\_llm\_config.json file acts as your “currently active model” configuration. This is the file that gets loaded when you specify “config\_path”: “local\_llm\_config.json” in your main config. 

**Default Configuration Structure:**

Create or edit your local\_llm\_config.json with:  
`{`  
   `"api_endpoint": "http://localhost:11434/api/generate",`  
   `"model": "deepseek-r1", # Change this with the corresponding model`  
   `"supports_vision": false,`  
   `"request_format": {`  
     `"model": "{model}",`  
     `"prompt": "{prompt}",`  
     `"stream": false,`  
     `"options": {`  
       `"temperature": 0.7,`  
       `"max_tokens": 1024`  
     `}`  
   `},`  
   `"response_field": "response"`  
 `}`

### **Key Configuration Options**

Basic Settings:

* api\_endpoint: The Ollama API endpoint (always http://localhost:11434/api/generate for Ollama)  
* model: The exact model name as it appears in ollama list  
* supports\_vision: Set to false for most models (only certain models support images)

Request Format:

* options.temperature: Controls randomness (For deepseek specifically, 0.1 \= very predictable, 1.0 \= default, 1.5 \= very creative)  
* options.max\_tokens: Maximum response length

Response Handling:

* response\_field: Tells the system where to find the generated text in Ollama's response (always "response" for Ollama)

Finding Your Exact Model Name:

To ensure you're using the correct model name, run:

ollama list

Look for the exact name in the output. For example, if you see:

deepseek-r1:latest    abc123    4.2 GB    2 days ago

Then use `"model": "deepseek-r1:latest"` in your config.

**Model Specific Configurations:**

The local\_llm\_configs/ folder contains individual configuration files for each model you want to use. This allows you to easily switch between models and have different settings optimized for each one.

### **Creating Model-Specific Config Files**

Each model gets its own JSON file in the local\_llm\_configs/ directory. Here are examples for your models:

### **Ex: deepseek\_config.json**

`{`  
   `"api_endpoint": "http://localhost:11434/api/generate",`  
   `"model": "deepseek-r1",`  
   `"supports_vision": false,`  
   `"request_format": {`  
     `"model": "{model}",`  
     `"prompt": "{prompt}",`  
     `"stream": false,`  
     `"options": {`  
       `"temperature": 0.7,`  
       `"max_tokens": 1024`  
     `}`  
   `},`  
   `"response_field": "response",`  
   `"code_settings": {`  
     `"options": {`  
       `"temperature": 0.2`  
     `}`  
   `},`  
   `"goal_settings": {`  
     `"options": {`  
       `"temperature": 0.8`  
     `}`  
   `}`  
 `}`

### **Customizing for Your Needs**

You can adjust these settings based on your experience:

**If agents are making poor decisions:**

* Lower the temperature values  
* Increase max\_tokens if responses are being cut off

**If agents are too predictable:**

* Raise the temperature values  
* Increase goal\_settings temperature for more creative goals

**If code generation is unreliable:**

* Lower code\_settings temperature even further (try 0.05)  
* Consider switching to DeepSeek for better coding performance

