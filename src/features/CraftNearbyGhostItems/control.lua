local mod_gui = require("mod-gui")
local mod = require("mod")
local Factorissimo = KuxCoreLib.Factorissimo --[[@as KuxCoreLib.Factorissimo]]

local uiDefinitions = {
	["CraftNearbyGhostItemsButton"] = {
		type = "sprite-button",
		name = "CraftNearbyGhostItemsButton",
		sprite = "item/iron-plate",
		tooltip = "Craft Ghost Queue"
		-- style="icon_button"
	}
}

local function autoCraft(player)
	if not player.character then return end
	local info = global.playerData[player.index]
	if not info then
		info = {player_position = player.position, next = 0, ghosts = {}}
		global.playerData[player.index] = info
	end

	local dx = player.position.x - info.player_position.x
	local dy = player.position.y - info.player_position.y
	info.player_position = player.position

	local max_reach = player.mod_settings[mod.prefix.."max-reach"].value
	if(max_reach <= 0) then max_reach = player.character.reach_distance end
	local reach = player.mod_settings[mod.prefix.."reach-mode"].value == "character" and math.min(player.character.reach_distance, max_reach) or max_reach

	if info.next >= #info.ghosts then
		local aabb = Factorissimo.isFactoryFloor(player.surface) and Factorissimo.getFactoryWallRect(player.surface, player.position) or
				{
					left_top     = {player.position.x - reach, player.position.y - reach},
					right_bottom = {player.position.x + reach, player.position.y + reach
				}
		}
		local ghosts = player.surface.find_entities_filtered {
			area = aabb,
			force = player.force,
			type = "entity-ghost"
		}
		info.next = 1
		info.ghosts = ghosts
	end

	while info.next <= #info.ghosts do
		local ghost = info.ghosts[info.next]
		info.next = info.next + 1

		if ghost.valid then
			local dx = player.position.x - ghost.position.x
			local dy = player.position.y - ghost.position.y
			if dx * dx + dy * dy <= reach * reach then
				for _, stack in pairs(ghost.ghost_prototype.items_to_place_this) do

					local recipe = game.recipe_prototypes[stack.name]
					local item = stack.name
					if player.force.recipes[item] ~= nil and
						((player.get_craftable_count(item) > 0 and
							player.force.recipes[item].enabled == true)) then
						if recipe ~= nil and recipe.allow_as_intermediate then
							if player.begin_crafting({count = 1, recipe = stack.name, silent = true}) > 0 then
								player.print("Crafting " .. stack.name)
							end
						end
					end

				end
			end
		end
	end
end

-------------------------------------------------------------------------------

local setFlowbarButton = function (player, name, isAvalable)
	if player then
		local buttonFlow = mod_gui.get_button_flow(player)
		local button = buttonFlow[name]
		if isAvalable then
			if not button then
				button = buttonFlow.add(uiDefinitions["CraftNearbyGhostItemsButton"])
			end
		else
			if button then
				button.destroy()
			end
		end
	else
	end
end

local getPlayerBoolSetting = function(player, settingsName)
	local settings = player.mod_settings[settingsName]
	if not settings then return false end
	return settings.value == true
end

local initGloabals = function ()
	global.playerData = global.playerData --[[migration]] or global.player_info or {}
	global.player_info = nil --[[migration]]
end

local initGuiForAllPlayers = function ()
	for _, p in pairs(game.players) do
		setFlowbarButton(p, "CraftNearbyGhostItemsButton", getPlayerBoolSetting(p, "Kux-CraftingTools-HideCraftNearbyGhostItemsButton") == false)
	end
end

script.on_init(function(e)
	initGloabals()
	initGuiForAllPlayers()
end)

script.on_configuration_changed(function(e)
	initGloabals()
	initGuiForAllPlayers()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function (e)
	if e.setting == "Kux-CraftingTools-HideCraftNearbyGhostItemsButton" then
		if e.player_index then
			local p = game.get_player(e.player_index)
			setFlowbarButton(p, "CraftNearbyGhostItemsButton", getPlayerBoolSetting(p, "Kux-CraftingTools-HideCraftNearbyGhostItemsButton") == false)
		else
			for _, p in pairs(game.players) do
				setFlowbarButton(p, "CraftNearbyGhostItemsButton", getPlayerBoolSetting(p, "Kux-CraftingTools-HideCraftNearbyGhostItemsButton") == false)
			end
		end
	end
end)

script.on_event(defines.events.on_gui_click, function(event)
	local element = event.element
	local name = element.name
	local player = game.players[event.player_index]

	if not name then return end

	if name == "CraftNearbyGhostItemsButton" then autoCraft(player) end
end)

script.on_event(defines.events.on_player_created, function(event)
	local button = mod_gui.get_button_flow(game.players[event.player_index]).add(uiDefinitions["CraftNearbyGhostItemsButton"])
end)

script.on_event("CraftNearbyGhostItems", function (e)
	local player = game.players[e.player_index]
	autoCraft(player)
end)