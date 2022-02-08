globals []

patches-own[sum_hormones]



to setup
  clear-all
  create-turtles num_turtles
  ask turtles [
    set shape "square"
    set color white
    setxy random-xcor random-ycor
  ]

  reset-ticks
end

;;compute activator concentration value given patch and cell positions
to-report activator [cellx celly patchx patchy]
  let const (activator_const / (2 * pi * (activator_sigma)^(2) ) )
  let exponent ( (((patchx - cellx )^(2)) + ((patchy - celly)^(2))) / (2 * (activator_sigma)^(2)) )
  let act_value (const * (e ^ (- exponent)))
  report act_value
end

;;compute inhibitor concentration value given patch and cell positions
to-report inhibitor [cellx celly patchx patchy]
  let const (inhibitor_const / (2 * pi * (inhibitor_sigma)^(2) ) )
  let exponent ( (((patchx - cellx )^(2)) + ((patchy - celly)^(2))) / (2 * (inhibitor_sigma)^(2)) )
  let inh_value (const * (e ^ (- exponent)))
  report inh_value
end

;;compute the sum of activator and inhibitor in a given patch, given a cell position
to-report compute_hormones [cellx celly patchx patchy]
  let A ( activator cellx celly patchx patchy )
  let I ( inhibitor cellx celly patchx patchy )
  let tot_value (A - I)
  report tot_value
end

;check hormones value at a position x and y and give a proportional value if there is more activator
;or an inversially proportional value if there is more inhibitor
to-report compute_grid_prob [gridx gridy]
  let value 0
  ask patch-at gridx gridy [
      set value (e ^ (sum_hormones)) ;we use the e^x to give more weight to high values of hormones
      ;if the value is > 0 (activator dominant) we tend to have high numbers -> more probable to move there!
      ;if the value is < 0 (inhibitor dominant) we tend to have low numbers -> less probable to move there!
  ]

  if verbose = true [
    show "value computed for patch"
    show value
  ]
  report value
end

; compute the grid probability vector then choose a direction to take in the neigboor8 or self position (not moving)
to-report sense_and_choose_direction
  let tot_sum 0 ;;used to normalize the list of probabilities
  let value_list [] ;;non-normalized value list for computing the probabilities of moving
  let prob_list [] ;;normalized value list containing the probabilites
  let number random-float 1.001 ;random number to sample the CDF table

  ;; ______________
  ;;|-1,1 |0,1 |1,1 |  The relative patch position given the turtle at 0,0 is given by this table.
  ;;|____ |____|____|  This will enable to compute the probability of moving to each of the 9 cell.
  ;;|-1,0 |0,0 |1,0 |
  ;;|____ |____|____|
  ;;|-1,-1|0,-1|1,-1|
  ;;|_____|____|____|

  set value_list lput (compute_grid_prob 1 1) value_list
  set value_list lput (compute_grid_prob 0 1) value_list
  set value_list lput (compute_grid_prob -1 1) value_list
  set value_list lput (compute_grid_prob -1 0) value_list
  set value_list lput (compute_grid_prob -1 -1) value_list
  set value_list lput (compute_grid_prob 0 -1) value_list
  set value_list lput (compute_grid_prob 1 -1) value_list
  set value_list lput (compute_grid_prob 1 0) value_list
  set value_list lput (compute_grid_prob 0 0) value_list

  foreach value_list [ i -> set tot_sum (tot_sum + i)] ;compute the total sum of the values for normalizing

  set prob_list (map [i -> (i / tot_sum)] value_list) ;normalize the values to obtain a probabilities array


  if verbose = true [
    show "un-normalized vector:"
    show value_list
    show "prob vector:"
    show prob_list
    ;show sum prob_list
    ;show tot_sum
  ]

  ;;we need to build a cumulative density function (CDF) and then sample with the random number between 0 and 1 to know where to move

  ;;list of probabilities for the 9 possible moves
  let pnorth-est (item 0 prob_list)
  let pnorth (item 1 prob_list)
  let pnorth-ovest (item 2 prob_list)
  let povest (item 3 prob_list)
  let psouth-ovest (item 4 prob_list)
  let psouth (item 5 prob_list)
  let psouth-est (item 6 prob_list)
  let pest (item 7 prob_list)
  let pcenter (item 8 prob_list)

  ;;intervals for the CDF table
  let interval0 pnorth-est
  let interval1 (interval0 + pnorth)
  let interval2 (interval1 + pnorth-ovest)
  let interval3 (interval2 + povest)
  let interval4 (interval3 + psouth-ovest)
  let interval5 (interval4 + psouth)
  let interval6 (interval5 + psouth-est)
  let interval7 (interval6 + pest)
  let interval8 (interval7 + pcenter)

  ;;choose the direction with a sample at the CFD table
  (ifelse ((0 <= number) and (number <= interval0)) [report [1 1] ] ;;move to north-est
    ((interval0 < number) and (number <= interval1)) [report [0 1] ] ;;move to north
    ((interval1 < number) and (number <= interval2)) [report [-1 1] ] ;;move to north-ovest
    ((interval2 < number) and (number  <= interval3)) [report [-1 0] ] ;;move to ovest
    ((interval3 < number) and (number  <= interval4)) [report [-1 -1] ] ;;move to south-ovest
    ((interval4 < number) and (number <= interval5)) [report [0 -1] ] ;;move to south
    ((interval5 < number) and (number <= interval6)) [report [1 -1] ] ;;move to south-est
    ((interval6 < number) and (number <= interval7)) [report [1 0] ] ;;move to est
    ((interval7 < number) and (number <= 1.001)) [report [0 0] ] ;;move to center (remain still)
  )


end

; generate a random positioned explosion of a random radius that will kill all the turtles inside it >:-)
to explosion
  let radius explosion_radius
  ask one-of patches [
    ask patches in-radius radius [ set pcolor red ]
    ask turtles in-radius radius [
      die
    ]
  ]
end

;;make cells secrete hormones following the activator-inhibitor distribution around the given hormone radius
to secrete_hormones
  let x xcor
  let y ycor
  ask patches in-radius hormone_radius [
    ;;updates the patches hormone value in an additional way (overlaps of hormones for each agent gets summed up)
    set sum_hormones (sum_hormones + (compute_hormones x y pxcor pycor))
    ;;color the patches in 2 different colors to distinguish between activator and inhibitor predominant values
    ifelse sum_hormones >= 0
    [set pcolor magenta]
    [set pcolor lime ]
    ]

end


;take the stocasthic suggested direction, computed via the "sense and choose direction" reporter, then actually perform the action
;checks if the action to perform can be allowed
to select_and_perform_action

  let direction sense_and_choose_direction ;call the reporter to do the stochastic selection of the action to make

  let movx (item 0 direction)
  let movy (item 1 direction)

  if verbose = true [
    show "moving to:"
    show direction
  ]

  ;check if the grid selected to where to move is occupied by another turtle (except the position 0 0 of the current turtle)
  ifelse ((not any? turtles-on (patch-at movx movy)) or ((movx = 0) and (movy = 0)))

  [move-to (patch-at movx movy)] ;if the cell is free or movx and movx are null, then do the action

  [select_and_perform_action]; if the cell is not free (another turtle is here), redo the stochastic selection of the action with a recursive call

end

;;apply evaporation of hormones in the patch
to evaporate_hormones
  ;;the rate of dissipation controls how quickly the hormones evaporate
  set sum_hormones (sum_hormones * (100 - rate_of_dissipation) / 100)

  ;;prints out the hormone value in the patch, with a precision of 2 after the comma
  if (see_hormone_values = true) [set plabel (precision sum_hormones 2)]

  ;; if hormone value is low (under a certain threshold), reset the value to zero
  if (abs sum_hormones) <= 0.0001
  [
    set pcolor black
    set sum_hormones 0
  ]
end

to go
clear-output

  ask turtles[
    ;turtles secrete hormones then choose what action to take sensing theirs and others (hormones) in the environment
    ;turtles will tend to move towards activator hormones containing patches and less towards inhibitor hormones,
    ;but still the behaviour is stochastic
    secrete_hormones
    select_and_perform_action
  ]

  ask patches [
    ;patches will contain hormones and evaporate them over time
    evaporate_hormones
  ]


  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
501
10
1154
664
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-64
64
-64
64
0
0
1
ticks
30.0

BUTTON
27
28
91
61
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
108
28
171
61
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
25
215
197
248
hormone_radius
hormone_radius
2
20
5.0
1
1
NIL
HORIZONTAL

BUTTON
200
28
267
61
1-step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
25
170
197
203
rate_of_dissipation
rate_of_dissipation
1
100
88.0
1
1
NIL
HORIZONTAL

SLIDER
25
276
198
309
activator_const
activator_const
0
40
10.0
1
1
NIL
HORIZONTAL

SLIDER
25
324
197
357
inhibitor_const
inhibitor_const
0
40
10.0
1
1
NIL
HORIZONTAL

SLIDER
223
277
395
310
activator_sigma
activator_sigma
1
8
2.2
0.2
1
NIL
HORIZONTAL

SLIDER
223
325
396
358
inhibitor_sigma
inhibitor_sigma
1
8
4.0
0.2
1
NIL
HORIZONTAL

INPUTBOX
27
78
117
138
num_turtles
500.0
1
0
Number

BUTTON
199
87
268
120
NIL
explosion
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
287
87
459
120
explosion_radius
explosion_radius
4
40
20.0
1
1
NIL
HORIZONTAL

SWITCH
230
172
403
205
see_hormone_values
see_hormone_values
1
1
-1000

SWITCH
230
221
333
254
verbose
verbose
1
1
-1000

@#$#@#$#@
# Digital Hormone Model Robotic Swarm 
## [Read on Git-Hub](https://github.com/e-candeloro/Digital-Hormone-Model-Robotic-Swarm)
![example-img](file:images\Step50.jpg)
## WHAT IS IT?

This is a project done for the course of [Distributed Artificial Intelligence](https://offertaformativa.unimore.it/corso/insegnamento?cds_cod=20-262&aa_ord_id=2009&pds_cod=20-262-2&aa_off_id=2021&lang=ita&ad_cod=IIM-62&aa_corso=2&fac_id=10005&coorte=2020&anno_corrente=2021&durata=2) (2021-2022) by Prof. [Franco Zambonelli](https://personale.unimore.it/rubrica/dettaglio/zambonelli) at the [University of Modena and Reggio Emilia](https://international.unimore.it/).

This work aims to implement in Net-Logo the Digital Hormone Model (DHM-0) presented in this [paper](https://www.researchgate.net/publication/262849917_Hormone-Inspired_Self-Organization_and_Distributed_Control_of_Robotic_Swarms_Special_Issue_on_Analysis_and_Experiments_in_Distributed_Multi-Robot_Systems_Guest_Editors_Nikolaos_P_Papanikolopoulos_and_) [1] and used to build a swarm of autonomous agents that show capabilities of self-organizination and emerging intelligence when interacting with each other in a common environment.

## HOW IT WORKS

The model mimics the behaviour of cells in various organism. Cells communicate via secreting hormones in the environment that they can also sense. Each cell follows a set of rules that, based on the environment and near hormone value, leads to a particular action.
In our case the "cells" are agent (turtles in Net-Logo).

Each agent will do a simple set of actions in a repetite loop.

1. **Release hormones in the environment**
2. **Select the action to make**
3. **Simulate the hormones reaction and dissipation**
4. **Repeat to step 1**

### 1. Release Hormones
The agent will emit a set of two hormones in a given radius around itself: an activator A and inhibitor I.
The spatial distribution of the concentration C(x,y)hormones around the agent is given by the formulas below.

![formulas](file:images\Activator-Inhibitor-Formulas.jpg)

In our case, we consider the sum of the two hormone for each location and therefore we obtain a sort of "laplacian" curve (see image below).

![hormones distribution ](file:images\Hormones-Distribution.jpg)

Here the Aa and Ai are called the activator and inhibitor constants respectively.
The other parameters are the two sigma of the two gaussian distributions of the activator and inhibitor.
In our case the sigma value of the inhibitor is greater than the activator sigma.

### 2. Select the action to make
Each agent will then sense the environment via the neighboor grids. It will measure the cumulative hormones concentration inside 9 grids (see image below).
The 9 grids are the neighboor 8 and the agent position.

![agents-moves](file:images\agent-moves.png)

Once the measurements are made, the agent will select one of the nine grids to move to, following the given rules:

- the probability of moving to a given grid is proportional to the concentration of activator hormones A and inversely proportional to that of the inhibitor hormone I
- the sum of all the probabilities is normalized to 1

That means that the agent will move stochastically around the space, following the hormones.
If an agent wants to move to a grid where there is already another agent, then his movement will be switched to another free neighboor cell.

### 3. Simulate hormones reaction and dissipation
In this project the hormone diffusion equation were omitted, implementing only the hormone dissipation and reaction.

In each grid (patch) of the environment, all hormones produced by the agents nearby are summed, and after that a dissipation step take place to ensure the hormone value decreases with time if no agent is near.
The dissipation rate is controllable via a parameter.

NOTE: the actual dissipation is computed by the patch agent and not the turtle agent, but this is an implementation detail.

## HOW TO USE IT

This project requires Net-Logo installed on your machine.
After opening the project, you can set the project parameteres and press the button "setup" to confirm them. Then you can start the simulatio pressing the "go" button or in a single step-by-step incremental way using the "1-step" button.

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
[video demo with parameters changing](https://user-images.githubusercontent.com/67196406/151856809-a85a457a-82b6-43db-bc6d-2bd365104929.mp4)

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

This work was done by Ettore Candeloro and is under the MIT licence, freely available at Git-Hub [here](https://github.com/e-candeloro/Digital-Hormone-Model-Robotic-Swarm)

Part of the images and formulas used to explain the project are from the below cited paper. All credits goes to the authors.

[1] Shen, Wei-min & Will, Peter & Galstyan, Aram & Chuong, Cheng-Ming. (2004). Hormone-Inspired Self-Organization and Distributed Control of Robotic Swarms: Special Issue on Analysis and Experiments in Distributed Multi-Robot Systems (Guest Editors: Nikolaos P. Papanikolopoulos and Stergios I. Roumeliotis). Autonomous Robots. 17. 10.1023/B:AURO.0000032940.08116.f1. 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
