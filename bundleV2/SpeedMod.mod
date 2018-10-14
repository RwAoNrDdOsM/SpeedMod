return {
	run = function()
		fassert(rawget(_G, "new_mod"), "SpeedMod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("SpeedMod", {
			mod_script       = "scripts/mods/SpeedMod/SpeedMod",
			mod_data         = "scripts/mods/SpeedMod/SpeedMod_data",
			mod_localization = "scripts/mods/SpeedMod/SpeedMod_localization"
		})
	end,
	packages = {
		"resource_packages/SpeedMod/SpeedMod"
	}
}
