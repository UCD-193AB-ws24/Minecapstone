using Godot;

using System;
using System.Collections.Generic;
using System.Threading.Tasks;

[GlobalClass]
public partial class AgentController : Node
{

	private Agent agent;
	private Vector3 position;
	private MessageBroker message_broker;
	private Label3D label;


	public AgentController setup(Agent target_agent) {
		this.agent = target_agent;
		this.position = target_agent.position;
		this.label = agent.get_node("Label3D");
		return this;
	}


	public Vector3 get_position() {
		return agent.global_position;
	}


	public async void move_to_position(double x, double y, double distance_away =1.0) {
		label.Text = "Moving to position: " + (x) + ", " + (y);
		await agent.move_to_position(x, y, distance_away);
	}

	public async void select_nearest_entity_type(string target = "") {
		label.Text = "Selecting nearest target of type: " + target;
		agent.select_nearest_target(target);
	}


	public async void move_to_current_target(double distance_away = 1.0) {
		label.Text = "Moving to position of target: " + agent.current_target.name;
		await agent.move_to_current_target(distance_away);
	}

	public async void look_at_current_target() {
		agent.look_at_current_target();
	}


	public async void attack_current_target(int num_attacks = 1) {	
		label.Text = "Attacking entity " + (num_attacks) + " times.";
		await agent._attack_current_target(num_attacks);
	}


	public async void discard(string itemName, int amount) {
		label.Text = "Discarding item: " + itemName + ", amount: " + (amount);
		agent.discard_item(itemName, amount);
	}
		


	public async void say(string msg) {
		message_broker.send_message(msg, agent.hash_id);
		// agent.record_action("Said: " + msg)
	}


	public async void say_to(string msg, int target_id) {
		this.message_broker.send_message(msg, agent.hash_id, target_id);
		// agent.record_action("Said to " + str(target_id) + ": " + msg)
	}


	public async void eat_food() {
		// Currently hardcoded to restore 10 hunger;
		label.Text = "Eating food, restored 10 hunger";
		agent.eat_food(10);
	}



	public async Task<bool> eval() {
		try {
		
			return true;
		} catch (Exception e) {
			GD.Print("Error in eval: " + e.Message);
			return false;
		}
	}

// ============================== Goal management================================


	public bool SetGoal(string goal_description) {
		agent.set_goal(goal_description);
		return true;
	}

/**
# TODO: We should automatically determine whether a goal is completed or failed
# not the agent, somehow.
# func set_goal(goal_description: String):
# 	agent.set_goal_status(Agent.GoalStatus.IN_PROGRESS, goal_description)
# 	agent.record_action("Set new goal: " + goal_description)
# 	return true
	
# func complete_goal():
# 	agent.set_goal_status(Agent.GoalStatus.COMPLETED)
# 	agent.record_action("Completed goal: " + agent.goal)
# 	return true
	
# func fail_goal():
# 	agent.set_goal_status(Agent.GoalStatus.FAILED)
# 	agent.record_action("Failed goal: " + agent.goal)
# 	return true
*/
}
