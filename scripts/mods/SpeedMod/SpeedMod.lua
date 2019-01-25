local mod = get_mod("SpeedMod")
dofile("scripts/mods/SpeedMod/view/active_mods_view")



-- Active Mods Menu
local view_data = {
  -- Any name may be chosen, but it has to be unique among all registered views
  view_name = "active_mods_view",
  view_settings = {
    init_view_function = function (ingame_ui_context)
      return ActiveModsView:new(ingame_ui_context)
    end,
    active = {
      inn = true,
      ingame = true,
    },
    -- There is no check for `nil` in `mod:register_new_views`, so even if empty, these have to be defined
    blocked_transitions = {
      inn = {},
      ingame = {},
    },
    -- has to be same value as the keybind setting's `action_name`
    hotkey_action_name = "open_active_mods_view",
    -- Some name that has to match with the key in `view_transitions`
    hotkey_transition_name = "active_mods_view",
    
    
  },
  view_transitions = {
    active_mods_view = function (self)
      -- Should match with `view_data.view_name`
      self.current_view = "active_mods_view"
    end,
  }
}

mod:register_new_view(view_data)


--Boss Wall Removal

--This hook is from Prop Joe's Spawn Tweaks (Modified)
mod:hook(DoorSystem, "update", function(func, self, context, t)
    if self.is_server then
        for map_section, _ in pairs(table.clone(self._active_groups)) do
            self:open_boss_doors(map_section)
            self._active_groups[map_section] = nil
        end
    end

    return func(self, context, t)
end)

local function count_event_breed(breed_name)
	return Managers.state.conflict:count_units_by_breed_during_event(breed_name)
end

if get_mod("Onslaught") and Managers.vmf.persistent_tables.Onslaught.Onslaught.active then
  TerrorEventBlueprints.farmlands_rat_ogre = {
		{
			"set_master_event_running",
			name = "farmlands_boss_barn"
		},
		{
			"spawn_at_raw",
			spawner_id = "farmlands_rat_ogre",
			breed_name = "skaven_rat_ogre"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_event_breed("skaven_rat_ogre") == 1
			end
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_spawned"
		},
		{
			"delay",
			duration = 1
		},
		{
			"spawn_at_raw",
			spawner_id = "onslaught_farmlands_extra_boss",
			breed_name = {
				"skaven_rat_ogre",
				"skaven_stormfiend",
				"chaos_troll",
				"chaos_spawn"
			}		
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_dead"
		}
	}
	
	TerrorEventBlueprints.farmlands_storm_fiend = {
		{
			"set_master_event_running",
			name = "farmlands_boss_barn"
		},
		{
			"spawn_at_raw",
			spawner_id = "farmlands_rat_ogre",
			breed_name = "skaven_stormfiend"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_event_breed("skaven_stormfiend") == 1
			end
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_spawned"
		},
		{
			"delay",
			duration = 1
		},
		{
			"spawn_at_raw",
			spawner_id = "onslaught_farmlands_extra_boss",
			breed_name = {
				"skaven_rat_ogre",
				"skaven_stormfiend",
				"chaos_troll",
				"chaos_spawn"
			}		
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_dead"
		}
	}
	
	TerrorEventBlueprints.farmlands_chaos_troll = {
		{
			"set_master_event_running",
			name = "farmlands_boss_barn"
		},
		{
			"spawn_at_raw",
			spawner_id = "farmlands_rat_ogre",
			breed_name = "chaos_troll"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_event_breed("chaos_troll") == 1
			end
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_spawned"
		},
		{
			"delay",
			duration = 1
		},
		{
			"spawn_at_raw",
			spawner_id = "onslaught_farmlands_extra_boss",
			breed_name = {
				"skaven_rat_ogre",
				"skaven_stormfiend",
				"chaos_troll",
				"chaos_spawn"
			}		
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_dead"
		}
	}
	
	TerrorEventBlueprints.farmlands_chaos_spawn = {
		{
			"set_master_event_running",
			name = "farmlands_boss_barn"
		},
		{
			"spawn_at_raw",
			spawner_id = "farmlands_rat_ogre",
			breed_name = "chaos_spawn"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_event_breed("chaos_spawn") == 1
			end
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_spawned"
		},
		{
			"delay",
			duration = 1
		},
		{
			"spawn_at_raw",
			spawner_id = "onslaught_farmlands_extra_boss",
			breed_name = {
				"skaven_rat_ogre",
				"skaven_stormfiend",
				"chaos_troll",
				"chaos_spawn"
			}		
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_dead"
		}
	}
else
  TerrorEventBlueprints.farmlands_rat_ogre = {
		{
			"set_master_event_running",
			name = "farmlands_boss_barn"
		},
		{
			"spawn_at_raw",
			spawner_id = "farmlands_rat_ogre",
			breed_name = "skaven_rat_ogre"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_event_breed("skaven_rat_ogre") == 1
			end
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_spawned"
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_dead"
		}
  }
  
	TerrorEventBlueprints.farmlands_storm_fiend = {
		{
			"set_master_event_running",
			name = "farmlands_boss_barn"
		},
		{
			"spawn_at_raw",
			spawner_id = "farmlands_rat_ogre",
			breed_name = "skaven_stormfiend"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_event_breed("skaven_stormfiend") == 1
			end
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_spawned"
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_dead"
		}
  }
  
	TerrorEventBlueprints.farmlands_chaos_troll = {
		{
			"set_master_event_running",
			name = "farmlands_boss_barn"
		},
		{
			"spawn_at_raw",
			spawner_id = "farmlands_rat_ogre",
			breed_name = "chaos_troll"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_event_breed("chaos_troll") == 1
			end
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_spawned"
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_dead"
		}
  }
  
	TerrorEventBlueprints.farmlands_chaos_spawn = {
		{
			"set_master_event_running",
			name = "farmlands_boss_barn"
		},
		{
			"spawn_at_raw",
			spawner_id = "farmlands_rat_ogre",
			breed_name = "chaos_spawn"
		},
		{
			"delay",
			duration = 1
		},
		{
			"continue_when",
			condition = function (t)
				return count_event_breed("chaos_spawn") == 1
			end
		},
		{
			"delay",
			duration = 1
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_spawned"
		},
		{
			"flow_event",
			flow_event_name = "farmlands_barn_boss_dead"
		}
	}
end



--Active Mods on Cutscene
mod:hook(CutsceneUI, "set_letterbox_enabled", function(func, self, ...)
  local is_in_inn = self.is_in_inn
  local cutscene_system = Managers.state.entity:system("cutscene_system")
  local cutscene_menu = mod:get("cutscene_menu")


  if not is_in_inn and cutscene_system.active_camera then
    if cutscene_menu then
      mod.active_mods()
    end
  end
  return func(self, ...)
end)

--Active Mods View Opening
mod.active_mods = function() 
  ingame_ui:handle_transition("active_mods_view")
end


--Restart Level
--Taken from Propjoe's Github "Restart Level Command"
mod.do_insta_fail = false

mod.restart_level = function()
	mod:pcall(function()
		if Managers.state.game_mode:level_key() == "inn_level" then
			mod:echo("Can't restart in the keep.")
			return
		end

		mod.do_insta_fail = true
		Managers.state.game_mode:fail_level()
	end)
end

mod:hook(GameModeAdventure, "evaluate_end_conditions", function(func, self, round_started, dt, t)
	local restart = false
	if self.lost_condition_timer and mod.do_insta_fail then
		mod.do_insta_fail = false
		self.lost_condition_timer = t - 1
		restart = true
	end

	local ended, reason = func(self, round_started, dt, t)

	if ended and restart then
		return ended, "reload"
	end

	return ended, reason
end)


--Commands
mod:command("active_mods", mod:localize("active_mods_command_description"), function() mod.active_mods() end)
mod:command("ree", mod:localize("ree_command_description"), function() mod.restart_level() end)

-- Potion Stacking

BuffTemplates.speed_boost_potion = {
	activation_effect = "fx/screenspace_potion_02",
	deactivation_sound = "hud_gameplay_stance_deactivate",
	activation_sound = "hud_gameplay_stance_ninjafencer_activate",
	buffs = {
	  {
		apply_buff_func = "apply_movement_buff",
		multiplier = 1.5,
		name = "movement",
		icon = "potion_buff_02",
		refresh_durations = true,
		remove_buff_func = "remove_movement_buff",
		--max_stacks = 1,
		duration = 10,
		path_to_movement_setting_to_modify = {
		  "move_speed"
		}
	  },
	  {
		multiplier = 0.5,
		name = "attack speed buff",
		refresh_durations = true,
		--max_stacks = 1,
		duration = 10,
		stat_buff = StatBuffIndex.ATTACK_SPEED
	  }
	}
  }
  
  BuffTemplates.speed_boost_potion_increased = {
	activation_effect = "fx/screenspace_potion_02",
	deactivation_sound = "hud_gameplay_stance_deactivate",
	activation_sound = "hud_gameplay_stance_ninjafencer_activate",
	buffs = {
	  {
		apply_buff_func = "apply_movement_buff",
		multiplier = 1.5,
		name = "movement",
		icon = "potion_buff_02",
		refresh_durations = true,
		remove_buff_func = "remove_movement_buff",
		--max_stacks = 1,
		duration = 15,
		path_to_movement_setting_to_modify = {
		  "move_speed"
		}
	  },
	  {
		multiplier = 0.5,
		name = "attack speed buff",
		refresh_durations = true,
		--max_stacks = 1,
		duration = 15,
		stat_buff = StatBuffIndex.ATTACK_SPEED
	  }
	}
  }
  
  BuffTemplates.speed_boost_potion_reduced = {
	activation_effect = "fx/screenspace_potion_02",
	deactivation_sound = "hud_gameplay_stance_deactivate",
	activation_sound = "hud_gameplay_stance_ninjafencer_activate",
	buffs = {
	  {
		apply_buff_func = "apply_movement_buff",
		multiplier = 1.5,
		name = "movement",
		icon = "potion_buff_02",
		refresh_durations = true,
		remove_buff_func = "remove_movement_buff",
		--max_stacks = 1,
		duration = 5,
		path_to_movement_setting_to_modify = {
		  "move_speed"
		}
	  },
	  {
		multiplier = 0.5,
		name = "attack speed buff",
		refresh_durations = true,
		--max_stacks = 1,
		duration = 5,
		stat_buff = StatBuffIndex.ATTACK_SPEED
	  }
	}
  }