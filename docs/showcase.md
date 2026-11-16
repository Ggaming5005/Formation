# Repeatable cinematic capture

`examples/Showcase.luau` runs the actual Formation controller with the original twelve demo companions and the current player's avatar. It does not synthesize pet motion, draw pretend measurements, or change global Lighting.

Run from a LocalScript in a clean copy of the Formation demo place. Disable the ordinary `Demo.client.luau` launcher first so that it does not create a second course/controller.

```lua
local player = game:GetService("Players").LocalPlayer
local Showcase = require(game:GetService("ReplicatedStorage").FormationExamples.Showcase)
local capture = Showcase.start(player)

-- When capture is finished:
-- capture:Destroy()
```

After a two-second hold, the scene loops through Rows, Arc, Orbit, and Flying for eight seconds each. The avatar follows a small 12-by-5-stud ellipse while ground height is sampled from the course. The camera frames the actual companion positions with a gentle drift. The original avatar's walk animation is used when available.

Record 34 seconds to include the opening hold and one complete loop, or record a later full 32-second loop. A landscape 16:9 viewport is the intended composition. `capture.Gui:GetAttribute("Mode")` identifies the current chapter.

The returned handle exposes `Demo`, `Controller`, and `Gui`. Call `Destroy()` explicitly: it disconnects the render callback, stops its optional walk track, restores avatar anchoring/position/velocity and humanoid presentation, restores camera state, and destroys the demo and overlay. It also cleans up if that character is removed. Destroying only the caller's script is not a cleanup mechanism.
