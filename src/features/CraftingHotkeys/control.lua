local craft = function(player, item, count)
	print("craft "..count.." "..item.name)
    local found = false
    local len = 0
    local recipes = {}
    for name, recipe in pairs(player.force.recipes) do
        local products = recipe.products
        if recipe.enabled and not recipe.hidden then
            for _, prod in pairs(products) do
                if item.name == prod.name then
                    found = true
                    local craftable = player.get_craftable_count(name)
                    if craftable ~= 0 then
                        local prob = prod.probability or 1
                        local amt = prod.amount or (prod.amount_min + prod.amount_max) / 2
                        local est = craftable * prob * amt

                        if est >= count then
                            len = len + 1
                            table.insert(recipes, {
                                name = name,
                                count = (count == 0 or est == count)
                                    and craftable
                                    or math.ceil(count / amt),
                                prob = prob,
                                only = #products == 1,
                            })
                        end
                    end
                    break
                end
            end
        end
    end

    if len == 0 then
        if found then
			player.print({"messages.missing-ingredients", item.localised_name})
        else
            player.print({"messages.no-recipe", item.localised_name})
        end
    else
        local best = recipes[1]
        for i = 2, len do
            local recipe = recipes[i]
            if recipe.count > best.count
            or (recipe.count == best.count 
                and (recipe.prob > best.prob
                    or (recipe.prob == best.prob
                        and not best.only
                    )
                )
            ) then
                best = recipe
            end
        end

        player.begin_crafting({
            count = best.count,
            recipe = best.name,
            silent = true,
        })
    end
end

local craft2 = function(player, item, count)
	pcall(player.begin_crafting, {count=count, recipe=item.name, silent=false})
end

local register = function(prefix, handler)
    script.on_event(prefix .. "craft-1", handler(1))
    script.on_event(prefix .. "craft-5", handler(5))
    script.on_event(prefix .. "craft-all", handler(0))
end

-------------------------------------------------------------------------------

register("cursor-", function(count)
	return function(event)
		local player = game.get_player(event.player_index)
		local item = (player.cursor_stack ~= nil and player.cursor_stack.valid_for_read)
			and player.cursor_stack.prototype
			or player.cursor_ghost
		if item ~= nil then
			craft(player, item, count)
			return
		end
		if player.selected then
			craft(player, player.selected, count)
		end
	end
end)

for i = 1, 10 do
	register(string.format("shortcut-%x-", i), function(count)
		return function(event)
			local player = game.get_player(event.player_index)
			local bar = player.get_active_quick_bar_page(1) or 1
			local item = player.get_quick_bar_slot((bar - 1) * 10 + i)
			if item ~= nil then
				craft(player, item, count)
			end
		end
	end)
end


