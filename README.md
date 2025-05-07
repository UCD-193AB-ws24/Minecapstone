# Minecapstone
Minecapstone is a project that hopes to introduce a complex and novel benchmarking system specifically designed to test embodied LLM agents (agentic AI).
To accomplish this, we developed a video game based environment that provides a complex 3D world supporting a variety of tasks and challenges specifically designed to test the capabilities of single-to-multi agent systems.
The game and the problem defined for the LLMs are designed around a survival/sandbox game, where the player must gather resources, build structures, and survive against hostile AI agents.

# Overview
* [Godot](https://godotengine.org/) is used for the game engine, and the game is written in GDScript + C#.
* [Python 3.11.9](https://www.python.org/downloads/release/python-3119/) is used for the backend server, which handles websocket connections and agent control. 
Older or new versions may or may not work.


## Setup
1. Install python requirements in a virtual environment.
```bash
python -m venv .venv        # Create virtual environment, can also use Python: Create Environment in VSC
pip install -r ./python/requirements.txt  # Install requirements
```

2. Then, copy ``.env.development`` and rename the new file to ``.env.development.local``.
3. Set all the environment variables within ``.env.development.local``.
####  DO NOT PUSH API KEYS TO THE REPO!!

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
    * This project is completely free and open-source, and open to contributions.
- ## Social/ethical analysis
    * This project is designed to be a benchmarking system for embodied LLM agents, and is not intended to be used for any malicious purposes. This project can be referenced in future research or projects.
- ## Engineering Standards
    * ### Godot
        * #### [Codestyle](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
        * #### Project Layout
            - `world/` contains the main game world scene (`world.tscn`), UI (`ui.tscn`), and related scripts.
            - `prefabs/` holds reusable scene objects such as the player, NPCs, and items.
            - `scenarios/` includes scenario scenes for benchmarking and evaluation (e.g., `scenario_attack_baseline.tscn`, `scenario_look_at_visual.tscn`).
            - `worldgen/` contains procedural world generation logic and resources.
            - `items/` and `globals/` provide item definitions and global scripts (autoloads).
            - All configuration and input mappings are managed in `project.godot`.
            - Assets (textures, materials, etc.) are stored in dedicated folders referenced by scenes.
    * ### Python backend
        - `python/` contains the backend server and agent control logic.
    * ### Contributing
        * Development branches should be named dev-<your_name>-<feature_name> and pull requests should be made with at least one reviewer before merging into main.
- ## TODO/Not in current sample
    * Need infinite thinking