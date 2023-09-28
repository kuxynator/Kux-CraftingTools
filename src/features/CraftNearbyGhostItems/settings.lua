require("mod")
local extend = KuxCoreLib.SettingsData.extend
extend.prefix = mod.prefix
local x = extend{"runtime-user","a"}
x:string{"reach-mode", "character", {"character", "custom"}}
x:int{"max-reach", 0, min=0, max=1000}
x:bool{"HideCraftNearbyGhostItemsButton", false}