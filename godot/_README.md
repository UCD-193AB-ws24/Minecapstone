The tools used to benchmark in this system are called scenarios. Scenarios have definitive successes (and potentially definitive failures). These are used to determine if an Agent is successfully accomplishing its goal, accomplishing a wrong goal or something different all together.

A key component of scenario building is through Godots [signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html).

# Scenarios and Benchmarking

## Scenario contents

### [Agent](./prefabs/player/agent.tscn)

This is the simulated character that will perform the actions dictated by the LLM., given context about the world, surrounding entities and items, and a goal. The agent may be given any additional initial conditions required to complete the goal, but often we omit as much as possible for more consistent testing.

### [Scenario Manager](./benchmarking/prefabs/scenario_manager.gd)

Base class that handles the logic for resetting and collection of metrics for all scenarios.

### Goal

The actual goal of the scenario, given to and handled by the agent. This can be defined in a number of ways. Some examples include:

- A physical location (see [move to](./benchmarking/scenarios/scenario_moveto.gd))
- A potential item check (see [eat meat](./benchmarking/scenarios/scenario_eatmeat.gd))
- An entity’s death (see [attack](./benchmarking/scenarios/scenario_attack_baseline.gd))

These events are specific to each scenario and are typically handled by using Godot signals. These are all handled through Godot’s signals and are present in each scenario’s respective scenario manager.

Example Scenario Setup (Move To)  
![image1](https://github.com/user-attachments/assets/4698708d-31ba-4d9d-8c87-5d7a8d517a02)


## Setting up the benchmark

We have a suit of scenarios built to test simple and complex reasoning for LLMs. To use these visit the benchmarking scene and add the desired scenarios to the list under the inspector tab.  
![image2](https://github.com/user-attachments/assets/a674790e-3c04-4a38-a6c3-27b17ea196d7)


## Scene switching and data collection

### [Scene Switcher](./benchmarking/prefabs/scenario_switcher.gd)

Each scenario is built to run a number of times before it is switched off. Each iteration the scenario is logged. Once the number of iterations reaches the defined `MAX_ITERATION` the scenario switcher collects the data and begins setup on the [next scene.](./benchmarking/prefabs/scenario_manager.gd#L89)

### Data Collection and Print Out

By default the scenario manager will printout the [results](./benchmarking/prefabs/scenario_manager.gd#L78) of each individual scenario. This can be toggled with the debug input to the get_results function.

At the end of all scenarios the scenario switcher will printout the scenario name followed by the [overall results](./benchmarking/prefabs/scenario_switcher.gd#L38) of the scenario.

# Setting Up Custom Scenarios

If the provided scenarios do not fit the tester’s desired needs, custom scenarios can be created.

## Create a scenario scene

### An Agent (provided by the agent scene)

Agents may require initial conditions such as items in their inventory or certain elements to be placed in a particular way. For the latter that can be defined in the world using the nodes. For the former that is done in the scenario manager. Example of [adding items](./benchmarking/scenarios/scenario_eatmeat.gd#L30).

Goals can be quickly defined within the agent. Under the inspector tab in the editor a goal can be defined. This goal is sent to the LLM  
Example from Move To Scenario:  
![image3](https://github.com/user-attachments/assets/06ff9505-b95e-4099-9af1-f256ef089bc1)


### A custom scenario manager

A deeper dive into the scenario manager is to accomplish a couple goals

- Setup basic scenario by connecting goal signals and setting up initial conditions needed for the custom scenario
- Add the `track_success` and `track_failure` calls based on the goal signal setup.
- Timeout behavior can be overridden as well, by default it reports failure and resets
- Ensure the reset behavior properly resets each node and reconnects the success and failure signals properly

### Goal definition

Can be defined within the scenario manager itself or be additional nodes with zones. This is very dependents on the

### Any additional nodes needed for the desired scenario

Some examples include failure platforms (see [move to](./benchmarking/scenarios/scenario_moveto.gd)), entities beyond the target entity (see [look at](./benchmarking/scenarios/scenario_look_at.gd)).

## Add scene to the array in the benchmarking scene

Similar to using the basic scenario suite, just simply add the custom scenario to the array in the benchmark scene and run as usual.

# Additional Implementations

## Blocks

Within [`benchmarking/prefabs`](./benchmarking/prefabs) there is a block scene that contains a temporary block object.

To use this just drag the scene into your scenario and by default it will behave as a dirt block.

Additionally there are more options to use the chunks and open world to use blocks (more on this later.

## Using Different LLMs

Within the `python/` folder are different LLM configurations and ability to use different LLMs outside of chatgpt/gemini

[LLM USER GUIDE](./python/README.md)

## Multiple LLMS

TODO

## Chunks and World Generation

TODO
