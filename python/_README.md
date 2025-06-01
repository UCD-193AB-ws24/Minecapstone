# Cloud-hosted LLM Configuration Tutorial

## Setup
Cloud-hosted LLMS vary in their configuration settings which means creating an adapter file for your LLM is needed.
To help with creating a custom adapter, we provide an abstract class template called [llm_service.py](./python/llm_service.py).
Create an adapter file in Python and have it inherit from this class. The template file has abstract methods you need to implement in order to guide your integration of the llm. How you implement the methods will depend on how your LLM receives and handles requests. Example of adapters are found for [OpenAI](./python/api_adapters/openai_service_adapter.py) and [Gemini](./python/api_adapters/gemini_service_adapter.py). We recommend looking at them as reference for how the abstract methods will work and how you similarly implement them for your LLM.


## Config Structure

[`./python/`](.\python)

- [`python/llm_config.json`](.\python\llm_config.json) main config

llm_config.json is the main config file that holds a list of available llms and dictates which one will load.
First thing you need to do here is create an entry under the key "available_services". 
with the template:
```
"name-of-organization-that-owns-the-llm": {
	"models": [
		{name:"exact-name-of--LLM's-specific-model", "supports_vision": boolean value here},
		.
		.
		.
	]
}

```
You can look at the llm_config.json's contents to see how the provided LLMs are configured in the file.

# Local LLM Configuration Tutorial

## Installation and Setup
Install Ollama or use your own locally trained LLM. Refer to the bash snippet below to learn how to install models from Ollama.
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

- [`python/llm_config.json`](.\python\llm_config.json) main config
- [`python/local_llm_config.json`](.\python\local_llm_config.json) config for local LLMs (template)
- [`python/local_llm_configs/`](.\python\local_llm_configs) contains model-specific config files

local_llm_config.json is a template file for specifying the configuration settings of a given local llm.
Files of this type gets loaded when you specify the config path in your main config.
Local LLM config entries go under the key "models" which is located within the key "local".
The template for the entry is:
```
{
"name": "name of model",
"config_path": "local_llm_configs/name_of_your_llm_config.json"
}
```
[Refer to the main config for examples of how to include your local LLM ](https://github.com/UCD-193AB-ws24/Minecapstone/blob/2f82e8ab2778d49bc4c736b71f3b9fdb67aad331/python/llm_config.json#L19)
**Default Configuration Structure:**
As for the actual local llm config file,
Create or edit the local_llm_config.json with:  
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
Ollama uses 11434 by default, so make sure to set your API endpoint to `http://localhost:11434/api/generate`. 

To use the local-hosted LLM, make sure you set 
```
"service": "local"
```
in [`python/llm_config.json`](.\python\llm_config.json)
and specify the mode name in "model:"


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

#Setting the active LLM

Go to the [`python/llm_config.json`](.\python\llm_config.json) and set these two keys:
```
	"service": "available_services-options",
	"model": "exact name of LLM model"
```
in order to set the active LLM for the program. If you want to use a local LLM, set service to "local".
Here are a few examples to help your understanding:
```
	"service": "local",
	"model": "llava:latest"

	"service": "openai",
	"model": "gpt-40-mini"

	"service": "gemini",
	"model": "gemini-2.0-flash"
```

#Running your LLM

Activate the python websocket by running this command from your root folder:
```
python python/websocket.py
```
If successful, your output should look like this:
```
Initialized Local LLM service with endpoint: http://localhost:11434/api/generate
Using model: llava:latest
LLM service supports vision/images

```

