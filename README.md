# Simple
This is a Simulink library and a few helper m scripts for lumped parameter modelling.

The helper functions run as init functions on the blocks to create a chain of goto/from blocks communicating the flow signals around the network.
The visible signals represent the flows, but when measured with a scope actually transmit the level variable (like with a scope in real life!).
To each visible level signal corresponds a goto flow signal going back in the opposite direction.  
Fan out of level signals from a source corresponds to sum of flows at the output of the source block.  
The library implements this with the scripts and helper "Inflow" and "Outflow" blocks.

The subsystems in the library mosly represent the usual suspect components in each domain:
Resistors, Capacitors, Inductors, Transistors in the Electrical domain
Motors Springs Dampers CLutches in the driveline domain
Valves, Pistons in the hydraulics domain
etc.
These are usually implemented in their most basic 'Constitutive' form to have level variable inputs
(Voltages/Speeds/Pressures).  
Then they are packaged up in a higher level subsys that has input(s) and output(s).
It follows some of the constitutive ports with 'Lumps', 
which 
 * sum all the flow out of them, 
 * divide by the total capacitance, 
 * integrate to set the new level at that outport

So there are also very important subsystems representing the lumps.
These generally look like circular sources with one output, like a Test Point on a circuit diagram.
They sit between constitutive component implementations, to make the whole network solve, 
and so that at the top level the arrows chain together to show the flow of the conserved quantity
(charge, momentum, matter etc)

Electrical systems have very few lumps!  Lumps would be "Cauer" style grounded capacitors.  
So when their is insufficient Lump to simulate easily the Lump blocks increase the capacitative denominator
before the integral so it is just enough for a first order lag level determination in a few time clicks.
Basically using RC ~= Ts.

Amazingly, this seems to work!  (where work means give the same answers as similar circuits modelled with the excellent Simscape).

I will add more functionality and domains when I have chance.
Enjoy!
