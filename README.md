# Minecapstone
The Simulated Profiling Environment for Embodied Intelligence (SPEEN) is an open-source platform for evaluating embodied Large Language Model agents in a simulated game environment.

We provide both structured **quantitative benchmarking** through diverse scenarios, and an open-world sandbox for **qualitative assessment** of decision-making behaviors.

These environments are designed to test the capabilities of single-to-multi **embodied agent** systems, the LLMs that control them, and the prompting architectures that drive decision-making.

Our system provides researchers a tool to test various embodied LLM implementations in a flexible simulated environment and contribute to the development of robust evaluative measures for Trustworthy AI.

**Check out the other documentation files ([``./python/README.md``](./python/README.md) and [``./godot/README.md``](./godot/README.md)) for more information on how to modify or add new scenarios!**

# Overview
## Functionality
### Basic Benchmarking
Runs a set of scenarios and records quantitative measurements (time, success rate) of the agent.
1. Open the Godot project in the Godot editor.
2. In the scenarios folder, open the benchmarking scene which will sequentially load all the scenarios.
3. Observe the agent's behavior, and wait for the agent to finish all scenarios.
4. Observe the success, failure, and hallucination rate output.

### Infinite Decision-Making
This sandbox environment allows the agents to make decisions in an infinite loop, allowing them to think and act without any time constraints. This is useful for testing the agent's ability to think and act in a complex environment.
1. Open the Godot project in the Godot editor.
2. In the scenarios folder, open the world/world.tscn scene.
3. You can set the goal of the agent by selecting the Agent node and setting the scenario goal in the inspector.

### Technology
* [**Godot 4.4**](https://godotengine.org/) is used for the game engine, and the game is written in GDScript + C#.
* [**Python 3.11.9**](https://www.python.org/downloads/release/python-3119/) is used for the backend server, which handles websocket connections and agent control. 
Older or new versions may or may not work.

## Setup
1. Install python requirements in a virtual environment.
    ```bash
    python -m venv .venv    # Create virtual environment, can also use Python: Create Environment in VSC
    pip install -r ./python/requirements.txt    # Install requirements
    ```
2. Then, copy ``.env.development`` and rename the new file to ``.env.development.local``.
3. Set all the environment variables within ``.env.development.local``.

    **DO NOT PUSH API KEYS TO THE REPO!!**

4. Run the ** Python backend** to enable agent control before running the Godot project.
    ```bash
    # First configure ./python/config.json to swap out the LLM and adjust the parameters.
    # Read the documentation for more information on how to configure the LLM.

    python ./python/websocket.py
    ```

## Engineering Standards and Design Constraints
### Cost
* This project is completely free and open-source, and open to contributions.
### Social/ethical analysis
* This project is designed to be a benchmarking system for embodied LLM agents, and is not intended to be used for any malicious purposes.
* This project can be referenced in future research or projects.
### Engineering Standards
* **Godot**
    - **Read the docs for more information about the project structure.**
    - [`prefabs/`](./prefabs/) holds reusable scene objects such as the player, NPCs, and items.
    - [`scenarios/`](./scenarios/) contains scenario scenes for the benchmarking system.
    - [`worldgen/`](./worldgen/) contains procedural world generation logic and resources for the sandbox environment.
* **Python backend**
    - [`python/`](./python/) contains the backend server and agent control logic.
    - [`websocket.py`](./python/websocket.py) - Main server entry point that handles WebSocket connections
    - [`config.json`](./python/config.json) - Configuration file for LLM parameters and selection
* **Contributing**
  * [**Codestyle**](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
  * Development branches should be named ``dev-<your_name>-<feature_name>`` and pull requests should be made with at least one reviewer before merging into main.
  * Commit frequently, and use descriptive commit messages. Precede commit messages with ``fix:``, ``feat:``, or ``chore:`` to indicate the type of change.
## Future Work/Not in current sample
* TBD

# Troubleshooting

# FAQ

# Contact Information

| Name          | LinkedIn                                                         |
| ------------- | ---------------------------------------------------------------- |
| Darroll Saddi | [AKA Iemontine](https://www.linkedin.com/in/darrolls)            |
| Ken Lin       | [AKA Keshfer](https://www.linkedin.com/in/ken-lin-b1a925296/)    |
| Ryan Li       | [LinkedIn](https://www.linkedin.com/in/ryan-li-a05b34236/)       |
| Jon Lagasca   | [LinkedIn](https://www.linkedin.com/in/jon-lagasca-300958345/)   |
| Matthew Fulde | [LinkedIn](https://www.linkedin.com/in/matthew-fulde-25761725b/) |

# Glossary


# Appendix


# Credits
### Iemontine
| Role/Contribution                 | Description                                                                            |
| --------------------------------- | -------------------------------------------------------------------------------------- |
| 1. Project manager and director   | Repository maintenance, project coordination                                           |
| 2. World generation               | Chunk system, procedural generation, voxel optimization                                |
| 3. Prompting architecture         | Generating goals, scripts                                                              |
| 4. AI integration                 | Agent executing generated code                                                         |
| 5. Agent navigation               | Navlogic, runtime navmesh generation                                                   |
| 6. Chain-of-thought mode          | Infinite thinking                                                                      |
| 7. Base player/NPC functionality  | Movement, camera, raycasting                                                           |
| 8. Scenario Manager               | Base scenario class, tracking successes and failures, then resetting to original state |
| 9. Benchmarker                    | Sequential running of scenarios + getting metrics                                      |
| 10. World shaders                 | Water, sky, biome                                                                      |
| 11. Block system                  | Block types, textures                                                                  |
| 12. Structure generation          | Trees as interactable objects                                                          |
| 13. Debugging tools               | Agent labels, debug UI, debug for script/goal gen                                      |
| 14. Agent self-fixing             | Catching and tracking errors and allowing agent recovery                               |
| 15. Day/night cycle + shaders     |                                                                                        |
| 16. Prompt engineering            |                                                                                        |
| 17. Support for visual modal LLMs | Sending camera data to backend as image                                                |
| 18. Quality Control               |                                                                                        |
| 19. Bug fixes                     |                                                                                        |
| 20. Refactoring                   |                                                                                        |
### Keshfer
| Role/Contribution                           | Description                           |
| ------------------------------------------- | ------------------------------------- |
| 1. Item system, inventory management system | Design & implementation               |
| 2. Item interaction functionality           | Picking up item drops, Dropping items |
| 3. Scenario dev                             | Complex multiprompt + multiagent      |
| 4. Interactables                            |                                       |
| 5. Signal adapter                           | For C#-GDScript signal communication  |
| 6. Bug fixes                                |                                       |
### Ryan
| Role/Contribution                | Description                                                                  |
| -------------------------------- | ---------------------------------------------------------------------------- |
| 1. LLM-swapping user config tool | LLM service adapter to support local LLMs and various APIs, parsing resposes |
| 2. Base memory management system | Adding memory context to prompt                                              |
| 3. Messaging system              | MessageBroker to manage inter-agent communication                            |
| 4. Zombie AI Behaviors           | Attack, chasing, wandering                                                   |
| 5. Scenario dev                  | eat, say                                                                     |
| 6. Needs                         | Health, hunger, food                                                         |
| 7. Sprinting                     |                                                                              |
### Matt
| Role/Contribution                  | Description                 |
| ---------------------------------- | --------------------------- |
| 1. Block breaking system           | Taking time to break blocks |
| 2. Ore generation system           | With different ore types    |
| 3. Tool use and tool proficiencies |                             |
| 4. Entity targeting and combat     |                             |
| 5. Bug fixes                       |                             |
### Jon
| Role/Contribution                         | Description |
| ----------------------------------------- | ----------- |
| 1. Chunk caching and loading              |             |
| 2. Animal AI behavior                     |             |
| 3. Entity detection and targeting systems |             |
| 4. Scenario dev                           | look_at     |