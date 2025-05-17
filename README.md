# Minecapstone

Minecapstone is a project that hopes to introduce a complex and novel benchmarking system specifically designed to test embodied LLM agents (agentic AI).
To accomplish this, we developed a video game based environment that provides a complex 3D world supporting a variety of tasks and challenges specifically designed to test the capabilities of single-to-multi agent systems.
The game and the problem defined for the LLMs are designed around a survival/sandbox game, where the player must gather resources, build structures, and survive against hostile AI agents.

# Overview

- [Godot](https://godotengine.org/) is used for the game engine, and the game is written in GDScript + C#.
- [Python 3.11.9](https://www.python.org/downloads/release/python-3119/) is used for the backend server, which handles websocket connections and agent control.
  Older or new versions may or may not work.

## Setup

1. Install python requirements in a virtual environment.

```bash
python -m venv .venv        # Create virtual environment, can also use Python: Create Environment in VSC
pip install -r ./python/requirements.txt  # Install requirements
```

2. Then, copy `.env.development` and rename the new file to `.env.development.local`.
3. Set all the environment variables within `.env.development.local`.

#### DO NOT PUSH API KEYS TO THE REPO!!

4. To enable agent control, you must run the Python backend before running a Scene in Godot.

```bash
python ./python/websocket.py
```

### Swapping LLMs

Use ./python/config.json to swap out the LLM used for agent control.
TODO: Add support for locally run LLMs.

# Functionality

## Basic Benchmarking

This is a basic quantiative benchmarking system that runs a set of scenarios and records the success and failure rates of the agent.

1. Open the Godot project in the Godot editor.
2. In the scenarios folder, open the benchmarking scene which will sequentially load all the scenarios.
3. Observe the agent's behavior, and wait for the agent to finish all scenarios.
4. Observe the success, failure, and hallucination rate output.

## Infinite Decision-Making

This is a more advanced benchmarking system that tests the agent's ability to make decisions over an extended period of time.

1. Open the Godot project in the Godot editor.
2. In the scenarios folder, open the world/world.tscn scene.
3. You can set the goal of the agent by selecting the Agent node and setting the scenario goal in the inspector.

# Engineering Standards and Design Constraints

- ## Cost
  - This project is completely free and open-source, and open to contributions.
- ## Social/ethical analysis
  - This project is designed to be a benchmarking system for embodied LLM agents, and is not intended to be used for any malicious purposes. This project can be referenced in future research or projects.
- ## Engineering Standards
  - ### Godot
    - #### [Codestyle](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
    - #### Project Layout
      - `world/` contains the main game world scene (`world.tscn`), UI (`ui.tscn`), and related scripts.
      - `prefabs/` holds reusable scene objects such as the player, NPCs, and items.
      - `scenarios/` includes scenario scenes for benchmarking and evaluation (e.g., `scenario_attack_baseline.tscn`, `scenario_look_at_visual.tscn`).
      - `worldgen/` contains procedural world generation logic and resources.
      - `items/` and `globals/` provide item definitions and global scripts (autoloads).
      - All configuration and input mappings are managed in `project.godot`.
      - Assets (textures, materials, etc.) are stored in dedicated folders referenced by scenes.
  - ### Python backend
    - `python/` contains the backend server and agent control logic.
  - ### Contributing
    - Development branches should be named dev-<your_name>-<feature_name> and pull requests should be made with at least one reviewer before merging into main.
- ## Future Work/Not in current sample
  - TBD

# Troubleshooting

# FAQ

# Contact Information

- darroll saddi AKA [@Iemontine](https://www.linkedin.com/in/darrolls)
- ken lin AKA [@Keshfer](https://www.linkedin.com/in/ken-lin-b1a925296/)
- [ryan li](https://www.linkedin.com/in/ryan-li-a05b34236/)
- [jon logasca](https://www.linkedin.com/in/jon-lagasca-300958345/)
- [matthew fulde](https://www.linkedin.com/in/matthew-fulde-25761725b/)

# Glossary

# Appendix

# Credits

## Iemontine

1. Project manager and director
2. World generation
   - Chunk system, procedural generation, voxel optimization
3. Prompting architecture
   - Generating goals, scripts
4. AI integration
   - Agent executing generated code
5. Agent navigation
   - Navlogic, runtime navmesh generation
6. Chain-of-thought mode
   - "Infinite thinking"
7. Base player/NPC functionality
   - Movement, camera, raycasting
8. Scenario Manager
   - Base example scenario
9. Benchmarker
   - Sequential running of scenarios + getting metrics
10. World shaders
    - Water, sky, biome
11. Block system
    - Block types, textures
12. Structure generation
    - Trees as interactable objects
13. Debugging tools
    - Agent labels, debug UI, debug for script/goal gen
14. Agent self-fixing
    - self-repair
15. Day/night cycle + shaders
16. Prompt engineering
17. Support for visual modal LLMs - sending camera data to backend as image
18. QC
19. Bug fixes
20. Refactoring
21. Repository maintenance

## Keshfer

1. Design of inventory and item management system
2. Item interaction functionality (picking up drops)
3. Scenario dev (complex multiprompt + multiagent)
4. Interactables
5. Signal adapter for C#-GDScript signal communication
6. Bug fixes

## Ryan

1. LLM-swapping user config tool
   - Designed and implemented a flexible LLM service adapter architecture
   - Developed JSON-based configuration files for easily switching between LLM providers
   - Built a local LLM adapter supporting various API formats and configurations
   - Thorough parsing for llm generated responses
2. Base memory management system
   - Added memory context in script generation
3. Messaging system for inter-agent communication
   - MessageBroker that delegates messages to agents
4. Zombie NPC
   - Attack, chasing, wandering
5. Scenario dev (eat and say)
6. Health, hunger, and food implementation
7. Sprinting

## Matt

1. Block breaking system (taking time to break blocks)
2. Ore generation system with different ore types
3. Tool use and tool proficiencies
4. Entity targetting and combat
5. Bug fixes

## Jon

1. Chunk caching and loading
2. Animal AI behaviors
3. Entity detection and targeting systems
4. Scenario dev (look_at)
