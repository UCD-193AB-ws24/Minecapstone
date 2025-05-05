# Minecapstone
Mein Capstone? Nein. Unser Capstone.

## Setup
1. This project uses Python 3.11.9, older or new versions may or may not work.
```bash
python -m venv .venv				# Create virtual environment, can also use Python: Create Environment
pip install -r ./python/requirements.txt	# Install requirements
```

2. Then, copy ``.env.development`` and rename the new file to ``.env.development.local``.
3. Set all the environment variables within ``.env.development.local``.
####  DO NOT PUSH API KEYS TO THE REPO!!

4. To enable agent control, you must run the Python backend before running a Scene in Godot.
```bash
python ./python/websocket.py
```

## Progress
- [x] Player physics, player movement
- [x] Representing Graphics and Collisions w/ Vertice Mesh
- [x] Placing, breaking blocks, including between chunks, using raycasting
- [x] Spectator and God views
- [x] Block textures
- [x] Player needs, sprinting
- [x] Prototype chunk saving, loading, and infinite generation
- [x] Basic Inventory Management, item dictionary to identify and store items/blocks
- [x] Navigation prototype
- [x] Procedural world generation using voronoi biome selection, noise for ocean/land and height maps
- [x] Ore generation
- [x] Item drops, with the ability to pick them up
- [x] Basic Zombie AI w/ pathfinding
- [x] Chunk optimizations (better transparency checks), basic visual shaders for fun
- [x] Tools
- [x] Websocket Python server for LLM agents
- [x] Embodied LLM agent functionality -- infinite decision-making
- [x] Command-based architecture for querying and running goals & scripts

