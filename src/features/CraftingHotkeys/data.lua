local extendHotkey = function(prefix, key)
	data:extend({
		{
			type = "custom-input",
			name = prefix .. "craft-1",
			key_sequence = "ALT + " .. key,
		},
		{
			type = "custom-input",
			name = prefix .. "craft-5",
			key_sequence = "CONTROL + " .. key,
		},
		{
			type = "custom-input",
			name = prefix .. "craft-all",
			key_sequence = "CONTROL + ALT + " .. key,
		},
	})
end

extendHotkey("cursor-", "G")
for i = 1, 10 do
	extendHotkey(string.format("shortcut-%x-", i), tostring(i % 10))
end