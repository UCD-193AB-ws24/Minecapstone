# Minecapstone

The Simulated Profiling Environment for Embodied Intelligence (SPEEN) is an open-source platform for evaluating embodied Large Language Model agents in a simulated game environment.

We provide both structured **quantitative benchmarking** through diverse scenarios, and an open-world sandbox for **qualitative assessment** of decision-making behaviors.

These simulated environments are designed to test the capabilities of single-to-multi **embodied agent** systems, the LLMs that control them, and the prompting architectures that drive decision-making.

Our system provides researchers a tool to test various embodied LLM implementations in a flexible simulated environment and contribute to the development of robust evaluative measures for Trustworthy AI.

**Check out the other documentation files ([`./python/README.md`](./python/README.md) and [`./godot/README.md`](./godot/README.md))** for more information on how to modify or add new scenarios!

# Overview

## Packaged Solution

TBD

## Functionality

### Basic Benchmarking

Runs a set of scenarios and records quantitative measurements (time, success rate) of the agent.

1. Open the Godot project in the Godot editor.
2. In the scenarios folder, open the benchmarking scene which will sequentially load all the scenarios.
3. Observe the agent's behavior, and wait for the agent to finish all scenarios.
4. Observe the success, failure, and hallucination rate output.

### Infinite Decision-Making Sandbox

This sandbox environment allows the agents to make decisions in an infinite loop, allowing them to think and act without any time constraints. This is useful for testing the agent's ability to think and act in a complex environment.

1. Open the Godot project in the Godot editor.
2. In the scenarios folder, open the world/world.tscn scene.
3. You can set the goal of the agent by selecting the Agent node and setting the scenario goal in the inspector.

### Technology

- [**Godot 4.4**](https://godotengine.org/) is used for the game engine, and the game is written in GDScript + C#.
- [**Python 3.11.9**](https://www.python.org/downloads/release/python-3119/) is used for the backend server, which handles websocket connections and agent control.
  Older or new versions may or may not work.

## Setup

1. Install python requirements in a virtual environment.
   ```bash
   python -m venv .venv    # Create virtual environment, can also use Python: Create Environment in VSC
   pip install -r ./python/requirements.txt    # Install requirements
   ```
2. Then, copy `.env.development` and rename the new file to `.env.development.local`.
3. Set all the environment variables within `.env.development.local`.

   **DO NOT PUSH API KEYS TO THE REPO!!**

4. Run the ** Python backend** to enable agent control before running the Godot project.

   ```bash
   # First configure ./python/config.json to swap out the LLM and adjust the parameters.
   # Read the documentation for more information on how to configure the LLM.

   python ./python/websocket.py
   ```

## Engineering Standards and Design Constraints

### Cost

- This project is completely free and open-source, and open to contributions.

### Social/ethical analysis

- This project is designed to be a benchmarking system for embodied LLM agents, and is not intended to be used for any malicious purposes.
- This project can be referenced in future research or projects.

### Engineering Standards

- **Godot**
  - **Read the docs for more information about the project structure.**
  - [`prefabs/`](./prefabs/) holds reusable scene objects such as the player, NPCs, and items.
  - [`scenarios/`](./scenarios/) contains scenario scenes for the benchmarking system.
  - [`worldgen/`](./worldgen/) contains procedural world generation logic and resources for the sandbox environment.
- **Python backend**
  - [`python/`](./python/) contains the backend server and agent control logic.
  - [`websocket.py`](./python/websocket.py) - Main server entry point that handles WebSocket connections
  - [`config.json`](./python/config.json) - Configuration file for LLM parameters and selection
- **Contributing**
  - [**Codestyle**](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
  - Development branches should be named `dev-<your_name>-<feature_name>` and pull requests should be made with at least one reviewer before merging into main.
  - Commit frequently, and use descriptive commit messages. Precede commit messages with `fix:`, `feat:`, or `chore:` to indicate the type of change.

## Future Work/Not in current sample

- In future work, SPEEN can be extended to more complex and/or more realistic scenarios that match real-world tasks (e.g. home automation, manual labor, defense systems, etc.).
- While the current prompting architecture is functional, it can be improved to handle the storage of previous agent actions and decisions, allowing for more complex decision-making.

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

### Darroll

| **Role/Contribution**                | Description                                                                                         |
| ------------------------------------ | --------------------------------------------------------------------------------------------------- |
| 1. **Project manager**               | Repository maintenance, project direction and coordination                                          |
| 2. **World generation**              | For sandbox: Chunk system, procedural generation, voxel optimization, trees                         |
| 3. **Prompting architecture**        | Generating goals, scripts                                                                           |
| 4. **Context preservation**          | Saving additional context about previous goals and actions per agent for improved decision-making   |
| 5. **AI integration**                | Agent executing generated code                                                                      |
| 6. **Agent navigation**              | Navlogic, runtime navmesh generation                                                                |
| 7. **Chain-of-thought mode**         | Infinite thinking                                                                                   |
| 8. **Base player/NPC functionality** | Movement, camera, raycasting                                                                        |
| 9. **Scenario dev**                  | Complex puzzle, move_to, move_to_visual                                                             |
| 10. **Scenario Manager**             | Base scenario class, tracking successes & failures, resetting to original state                     |
| 11. **Benchmarker**                  | Sequential running of scenarios + getting metrics                                                   |
| 12. **Visual modality**              | Support for vision-enabled LLMs processing camera input                                             |
| 13. **World shaders**                | Water, sky, biome                                                                                   |
| 14. **Block system**                 | Block types, textures, breaking and placing blocks                                                  |
| 15. **Structure generation**         | Trees as interactable objects                                                                       |
| 16. **Debugging tools**              | Agent labels, debug UI, debug for script/goal gen                                                   |
| 17. **Agent self-fixing**            | Catching and tracking errors and allowing agent recovery                                            |
| 18. **Day/night cycle**              | In sandbox                                                                                          |
| 19. **Prompt engineering**           | Iteratively designing standardized prompt                                                           |
| 20. **Quality Control**              | Ensuring clean PRs and issue tracking                                                               |
| 21. **Bug fixes**                    | Fixing issues in environments, agent management, prompting architecture, LLM service adapters, etc. |
| 22. **Refactoring**                  | Refactoring dirty code                                                                              |

### Ken

| **Role/Contribution**                           | Description                                                |
| ----------------------------------------------- | ---------------------------------------------------------- |
| 1. **Item system, inventory management system** | Design & implementation                                    |
| 2. **Item interaction functionality**           | Picking up item drops, Dropping items                      |
| 3. **Scenario dev**                             | Complex multiprompt + multiagent, attack_conehead, fetch   |
| 4. **Interactables**                            | LLM context for interactables                              |
| 5. **Agent Manager**                            | Identifying agents from by their IDs                       |
| 6. **Signal adapter**                           | For C#-GDScript signal communication (deprecated)          |
| 7. **Bug fixes**                                | Entity detection, scenario reset, item pickup improvements |
| 8. **Agent API development**                    | give_to, discard_here, set_look_target, movement APIs      |

### Ryan

| **Role/Contribution**                | Description                                                                  |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| 1. **LLM-swapping user config tool** | LLM service adapter to support local LLMs and various APIs, parsing resposes |
| 2. **Local LLM integration**         | Configuration and setup for locally running LLMs, Ollama support             |
| 3. **Base memory management system** | Adding memory context to prompt                                              |
| 4. **Messaging system**              | MessageBroker to manage inter-agent communication                            |
| 5. **Zombie AI Behaviors**           | Attack, chasing, wandering                                                   |
| 6. **Scenario dev**                  | eat, say                                                                     |
| 7. **Needs**                         | Health, hunger, food                                                         |
| 8. **Sprinting**                     |                                                                              |

### Matthew

| **Role/Contribution**                  | Description                                         |
| -------------------------------------- | --------------------------------------------------- |
| 1. **Block breaking system**           | Taking time to break blocks                         |
| 2. **Ore generation system**           | With different ore types                            |
| 3. **Tool use and tool proficiencies** | Integrated with the block breaking system           |
| 4. **Entity targeting and combat**     | Target selection, move to target, attack target API |
| 5. **Bug fixes**                       |                                                     |

### Jon

| **Role/Contribution**                         | Description                                      |
| --------------------------------------------- | ------------------------------------------------ |
| 1. **Chunk caching and loading**              |                                                  |
| 2. **Animal AI behavior**                     |                                                  |
| 3. **Entity detection and targeting systems** |                                                  |
| 4. **Scenario dev**                           | look_at, look_at_visual                          |
| 5. **Spectator and God view modes**           | Initial user camera views                        |
| 6. **Combat logic**                           | LLM agent combat logic and attacking functions   |
| 7. **Scenario timing**                        | Timeout timer implementation in scenario manager |
