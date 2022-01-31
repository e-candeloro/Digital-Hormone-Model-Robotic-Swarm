# Digital-Hormone-Model-Robotic-Swarm

## WHAT IS IT?

This is a project done for the course of [Distributed Artificial Intelligence]() 2021-2022 by Prof. [Franco Zambonelli](https://personale.unimore.it/rubrica/dettaglio/zambonelli) at the [University of Modena and Reggio Emilia](https://international.unimore.it/).

This work wants to implement in Net-Logo the Digital Hormone Model (DHM-0) presented in this [paper](https://www.researchgate.net/publication/262849917_Hormone-Inspired_Self-Organization_and_Distributed_Control_of_Robotic_Swarms_Special_Issue_on_Analysis_and_Experiments_in_Distributed_Multi-Robot_Systems_Guest_Editors_Nikolaos_P_Papanikolopoulos_and_) [1] and used to build a swarm of autonomous agents that show capabilities of self-organizination and emerging intelligence when interacting with each other in a common environment.

## HOW IT WORKS

Each agent will do a simple set of actions in a repetite loop.

1. **Release hormones in the environment**
2. **Select the action to make**
3. **Simulate the hormones reaction and dissipation**
4. **Repeat to step 1**

### 1. Release Hormones
The agent will emit a set of two hormones in a given radius: an activator A and inhibitor I.
The spatial distribution of the concentration C(x,y)hormones around the agent is given by the formulas below.

![formulas](https://github.com/e-candeloro/Digital-Hormone-Model-Robotic-Swarm/blob/main/images/Activator-Inhibitor-Formulas.jpg?raw=true)

In our case, we consider the sum of the two hormone for each location and therefore we obtain a sort of "laplacian" curve (see image below)

[image here]
### 2. Select the action to make
Each agent will then sense the environment via the neighboor grids. It will measure the cumulative hormones concentration inside 9 grids (see image below)

[image here]

Once the measurements are made, the agent will select one of the nine grids to move following the given rules:

- the probability of moving to a neighboor grid is proportional to the concentration of activator hormones A and inversely proportional to that of the inhibitor hormone I
- the sum of all the probabilities is normalized to 1

That means that the agent will move stochastically around the space, following the hormones.
If an agent want to move to a grid where there is already another agent, then the movement will be switched to another free neighboor cell
### 3. Simulate hormones reaction and dissipation
In this project the hormone diffusion equation were omitted, implementing only the hormone dissipation and reaction.
In each grid(patch) of the environment, all hormones produced by the agents in near location are summed and after that, a dissipation step take place to ensure the hormone value decreases with time if no agent is near.
The dissipation rate is controllable via a parameter.

## HOW TO USE IT

This project requires Net-Logo installed on your machine.
After opening the project, you can set the project parameteres and press the button "setup" to confirm them. Then you can start the simulation continuosly pressing the "go" button or in a single step-by-step incremental way using the "1-step" button.

The project parameters you can change are:

- **num_turtles**: number of agents for the simulation
- **rate_of_dissipation**: rate of evaporation for the hormones in the environment
- **activator_const**: amplitude constant for the hormone activator distribution
- **inhibitor_const**: amplitude constant for the hormone inhibitor distribution
- **activator_sigma**: standard deviation constant for the hormone activator distribution
- **inhibitor_sigma**: standard deviation constant for the hormone inhibitor distribution

#### IMPORTANT!
The inhibitor sigma value must be greater that the activator sigma for simulation purposes.
Also if all the activator and inhibitor parameters are equal, there will be an error given the fact that the hormones will cancel out.

## THINGS TO NOTICE

Given a sufficient large number of agents in the simulation and an activator/inhibitor balance, the agents will show a self-organization propension and aggregate and distribute in particular ways.
In particular, when two or more agents come close, the will tend to remain aggregated given that the activator hormones will "attract" them.
At the same time the inhibitor hormone will guarantee the non aggregation of all the agents, "repelling" them and making them move away.

The rate of dissipation will also affect the simulation making the hormones evaporate more quickly or slowly.

Finally, the stochastic behaviour will give the swarm of autonomous agents the self-organization and "edge of chaos" characteristics that improve the whole system adaptability. In this way, a single agents doesn't always make the best decision possible but can act randomly with a given probability.

## THINGS TO TRY

Changing the sigma and constants of the activator and inhibitor hormones will make the systems behave in different ways:

- more importance to the activator will tend to make agents aggregate more
- more importance to the inhibitor will tend to make agents aggregate less
- a balanced aggregator/inhibitor importance will make the agents aggregated but not too much, making emerging patterns of local clusters and distributing the agents in the environment.

Changing the rate of dissipation will:

- aggregate more agents if the value is low (hormones tend to remain in the grids)
- aggregate less agents if the value is high (hormones quickly evaporate and disappear)

Changing the number of turtles on a too low number will make the emerging behaviours disappear but when the value is high enough, different numbers yield similar results

## EXTENDING THE MODEL

The model can be easily extended changing the hormone distribution model and/or optimizing code to compute it.
The stochastic model of behaviour of each agents can be improved to make the agent less or more prone to random choices.
Also this simulation model excludes the equation for the propagation of hormones in the space, assuming an instant emission around each agents.
Therefore a propagation model can be implemented following the equation seen in the paper cited above.

## NETLOGO FEATURES

For the reporter function "sense_and_choose_direction", a particular sets of commands were used: a vector containing the hormones values in the neighboor patch was created then normalized to obtain a probability vector. To sample and choose the next action it was necessary to create a cumulative density function table (CDF) and then use a random generate number from 0 to 1 to make the sampling. After these steps, the next choosen action was reported to the "select_and_perform_action" procedure.


## RELATED MODELS

A set of code examples for the Net-Logo library were used for reference. In particular, the Ant examole under the "Biology" tab from the library was used to see how to implement the hormone evaporation required for the project.

## CREDITS AND REFERENCES

This work was done by Ettore Candeloro and is under the MIT licence, freely available at Git-Hub [here](https://github.com/e-candeloro/Digital-Hormone-Model-Robotic-Swarm)

Part of the images used to explain the project are from the below cited paper. All credits goes to the authors.

[1] Shen, Wei-min & Will, Peter & Galstyan, Aram & Chuong, Cheng-Ming. (2004). Hormone-Inspired Self-Organization and Distributed Control of Robotic Swarms: Special Issue on Analysis and Experiments in Distributed Multi-Robot Systems (Guest Editors: Nikolaos P. Papanikolopoulos and Stergios I. Roumeliotis). Autonomous Robots. 17. 10.1023/B:AURO.0000032940.08116.f1. 
