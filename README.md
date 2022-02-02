# Digital Hormone Model Robotic Swarm
![example-img](https://github.com/e-candeloro/Digital-Hormone-Model-Robotic-Swarm/blob/main/images/Step50.jpg)
## WHAT IS IT?

This is a project done for the course of [Distributed Artificial Intelligence](https://offertaformativa.unimore.it/corso/insegnamento?cds_cod=20-262&aa_ord_id=2009&pds_cod=20-262-2&aa_off_id=2021&lang=ita&ad_cod=IIM-62&aa_corso=2&fac_id=10005&coorte=2020&anno_corrente=2021&durata=2) (2021-2022) by Prof. [Franco Zambonelli](https://personale.unimore.it/rubrica/dettaglio/zambonelli) at the [University of Modena and Reggio Emilia](https://international.unimore.it/).

This work aims to implement in Net-Logo the Digital Hormone Model (DHM-0) presented in this [paper](https://www.researchgate.net/publication/262849917_Hormone-Inspired_Self-Organization_and_Distributed_Control_of_Robotic_Swarms_Special_Issue_on_Analysis_and_Experiments_in_Distributed_Multi-Robot_Systems_Guest_Editors_Nikolaos_P_Papanikolopoulos_and_) [1] and used to build a swarm of autonomous agents that show capabilities of self-organizination and emerging intelligence when interacting with each other in a common environment.

## HOW IT WORKS

The model mimics the behaviour of cells in various organism. Cells communicate via secreting hormones in the environment that they can also sense. Each cell follows a set of rules that, based on the environment and near hormones values, leads to a particular action.
In our case the "cells" are agents (turtles in Net-Logo).

Each agent will do a simple set of actions in a repetitive loop.

1. **Release hormones in the environment**
2. **Select the action to make**
3. **Simulate the hormones reaction and dissipation**
4. **Repeat to step 1**

### 1. Release Hormones
The agent will emit a set of two hormones in a given radius around itself: an activator A and inhibitor I.
The spatial distribution of the concentration C(x,y) hormones around the agent is given by the formulas below and follow a gaussian distribution.

![formulas](https://github.com/e-candeloro/Digital-Hormone-Model-Robotic-Swarm/blob/main/images/Activator-Inhibitor-Formulas.jpg)

Here the Aa and Ai are called the activator and inhibitor constants respectively.
The other parameters are the two sigma of the two gaussian distributions of the activator and inhibitor.
In our case the sigma value of the inhibitor is greater than the activator sigma.
In our case, we consider the sum of the two hormones for each location and therefore we obtain a sort of "laplacian" curve (see image below).

![hormones distribution ](https://github.com/e-candeloro/Digital-Hormone-Model-Robotic-Swarm/blob/main/images/Hormones-Distribution.jpg)

### 2. Select the action to make
Each agent will measure the cumulative hormones concentration inside 9 grids (patches) (see image below).
The 9 grids are the neighboor 8 and the agent position.

![agents-moves](https://github.com/e-candeloro/Digital-Hormone-Model-Robotic-Swarm/blob/main/images/agent-moves.png)

Once the measurements are made, the agent will select one of the nine grids to move to, following the given rules:

- the probability of moving to a given grid is *proportional* to the concentration of activator hormones A and *inversely proportional* to that of the inhibitor hormone I
- the sum of all the probabilities is normalized to 1

That means that the agent will move stochastically around the space, following the hormones with a certain probability.
If an agent wants to move to a grid where there is already another agent, then the movement will occur to another free neighboor cell.
### 3. Simulate hormones reaction and dissipation
https://user-images.githubusercontent.com/67196406/151953684-f7bee3c1-5e79-427a-a903-bb0519a58029.mp4

In this project the hormone diffusion equation were omitted, implementing only the hormone dissipation and reaction.

In each grid (patch) of the environment, all hormones produced by the agents nearby are summed, and after that a dissipation step take place to ensure the hormone value decreases with time if no agent is near.
The dissipation rate is controllable via a parameter.

NOTE: the actual dissipation is computed by the patch agent and not the turtle agent, but this is an implementation detail.

## HOW TO USE IT

This project requires Net-Logo installed on your machine.
After opening the project, you can set the project parameteres and press the button "setup" to confirm them. Then you can start the simulation pressing the "go" button or in a single step-by-step incremental way using the "1-step" button.

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

Given a sufficient large number of agents in the simulation and an activator/inhibitor balance, the agents will show a self-organization propension and aggregate and distribute in particular patterns.

When two or more agents come close, the will tend to remain aggregated given that the activator hormones will "attract" them in groups.

At the same time the inhibitor hormone will guarantee the non aggregation of groups of agents, "repelling" them in other location.

The rate of dissipation will also affect the simulation making the hormones evaporate more quickly or slowly and making aggregation less or more common.

Finally, the stochastic behaviour will give the swarm of autonomous agents the self-organization and "edge of chaos" characteristics that improve the whole system adaptability. In this way, a single agents doesn't always make the best decision possible but can act randomly with a given probability.

## THINGS TO TRY
https://user-images.githubusercontent.com/67196406/151856809-a85a457a-82b6-43db-bc6d-2bd365104929.mp4

Changing the sigma and constants of the activator and inhibitor hormones will make the systems behave in different ways:

- more importance to the activator will tend to make agents aggregate more
- more importance to the inhibitor will tend to make agents aggregate less
- a balanced aggregator/inhibitor importance will make the agents aggregated but not too much, making emerging patterns of local clusters and distributing the agents in the environment.

Changing the rate of dissipation will:

- aggregate more agents if the value is low (hormones tend to remain in the grids)
- aggregate less agents if the value is high (hormones quickly evaporate and disappear)

Changing the number of turtles on a low number will make the emerging self-organization behaviours disappear.
Increasing the number of turtles over a certain number will make the self-organization behaviours appear and at that point increasing the number of turtles will not affect greatly the system behaviour.

## EXTENDING THE MODEL

The model can be easily extended changing the hormone distribution model and/or optimizing code to compute it.
The stochastic model of behaviour of each agents can be improved to make the agent less or more prone to random choices.
Additionally, a propagation model can be implemented to simulate a non instantaneous hormone release in space by the agents, integrating the equation in the paper [1]

## NETLOGO FEATURES

For the reporter function "sense_and_choose_direction", a particular sets of commands were used: 
1. a vector containing the hormones values in the neighboor patch was created then normalized to obtain a probability array for each of the 9 possible actions. 
2. Then to sample and choose the next action, it was necessary to create a cumulative density function table (CDF) and use a random generated number from 0 to 1 to make the sampling. 
3. After these steps, the next choosen action was reported to the "select_and_perform_action" procedure that will execute the movement only if the selected cell is free of other agents.


## RELATED MODELS

A set of code examples for the Net-Logo library were used for reference. In particular, the Ant example under the "Biology" folder from the library was used to see how to implement the hormone evaporation algorithm required for the project.

## CREDITS AND REFERENCES

This work was done by Ettore Candeloro and is under the MIT license, freely available at Git-Hub [here](https://github.com/e-candeloro/Digital-Hormone-Model-Robotic-Swarm)

Part of the images and formulas used to explain the project are from the below cited paper. All credits goes to the authors.

[1] Shen, Wei-min & Will, Peter & Galstyan, Aram & Chuong, Cheng-Ming. (2004). Hormone-Inspired Self-Organization and Distributed Control of Robotic Swarms: Special Issue on Analysis and Experiments in Distributed Multi-Robot Systems (Guest Editors: Nikolaos P. Papanikolopoulos and Stergios I. Roumeliotis). Autonomous Robots. 17. 10.1023/B:AURO.0000032940.08116.f1. 
