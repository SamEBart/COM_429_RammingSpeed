This is the shader/material for the water in Ramming Speed. It is in a finished state, although some minor tweaks may be made later on.

There are several parameters that can be altered in order to change the appearance of the water. It is highly likely that the parameters will need quite a lot of tweaking once the shader is imported into the main Godot project, as the scale of objects in my testing project are probably quite different.

Because I created the shader using the Visual Shader system instead of writing shader code, I was unfortunately unable to add descriptions to the parameters, but I think their names are fairly self explanatory.

Two parameters that are worth mentioning:
Water_MovementDirection (Vector 2) controls the direction that the water scrolls, and Water_MovementSpeed (Float) controls the speed of the water's scrolling (both independent of the water's displacement.) In conjunction, I imagine these parameters being used to illustrate the direction of the water's current, or perhaps the direction that the wind is blowing.