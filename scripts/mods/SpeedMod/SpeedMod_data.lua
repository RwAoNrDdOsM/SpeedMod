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
			--[[{
				setting_id = "cutscene_menu",
				type = "checkbox",
				title = "cutscene_menu_option_name",
				tooltip = "cutscene_menu_option_tooltip",
				default_value = true,
			},]]
			{
				setting_id = "restart_level",
				type = "keybind",
				default_value = {},
				keybind_global  = false,       -- optional
				keybind_trigger = "pressed",
				keybind_type    = "function_call",
				function_name     = "restart_level", -- required, if (keybind_type == "action_call")
			},
			{
				setting_id    = "boss_walls",
				type          = "checkbox",
				default_value = true,
			},
			{
				setting_id    = "speed_stacking",
				type          = "checkbox",
				default_value = true,
			},
			{
				setting_id    = "potion_share",
				type          = "checkbox",
				default_value = true,
			},
			{
				setting_id    = "career_ability",
				type          = "dropdown",
				default_value = "no_change",
				options = {
				  {text = "career_ability_no_change",   value = "no_change", show_widgets = {1}},
				  {text = "disable_career_ability",   value = "disable_career_ability", show_widgets = {}},
				  {text = "set_amount_career_ability",   value = "set_amount_career_ability", show_widgets = {1,2}},
				  {text = "set_amount_career_ability_each_career", value = "set_amount_career_ability_each_career", 
				  	show_widgets = {
						1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
					}
				  },
				},
				sub_widgets = {
					{
						setting_id    = "no_cooldown",
						type          = "checkbox",
						default_value = false,
					},
					{
						setting_id      = "set_amount_career_ability_value",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_bw",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_pm",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_uc",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_rv",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_ib",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_sl",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_mn",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_hnm",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_fk",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_ww",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_hm",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_sh",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_whc",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_bh",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
					{
						setting_id      = "set_amount_career_ability_ze",
						type            = "numeric",
						default_value   = 5,
						range           = {1, 50},
					},
				}
			},
		},
	},
}
