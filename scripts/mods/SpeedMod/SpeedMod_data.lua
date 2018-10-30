local mod = get_mod("SpeedMod")

--Everything here is optional. You can remove unused parts.
return {
	name = "Speedrunning Mod",                               -- Readable mod name
	description = mod:localize("mod_description"),  -- Mod description
	is_togglable = true,                            -- If the mod can be enabled/disabled
	is_mutator = false,                             -- If the mod is mutator
	mutator_settings = {},                          -- Extra settings, if it's mutator
	options = {                             -- Widget settings for the mod options menu
		widgets = {
			{
				setting_id = "cutscene_menu",
				type = "checkbox",
				title = mod:localize("cutscene_menu_option_name"),
				tooltip = mod:localize("cutscene_menu_option_tooltip"),
				default_value = true,
			},
			{
				setting_id = "restart_level",
				type = "keybind",
				title = mod:localize("ree_hotkey"),
				tooltip = mod:localize("ree_hotkey_tooltip"),
				default_value = {},
				keybind_global  = false,       -- optional
				keybind_trigger = "pressed",
				keybind_type    = "function_call",
				function_name     = "restart_level", -- required, if (keybind_type == "action_call")
			},
		},
	},
}
