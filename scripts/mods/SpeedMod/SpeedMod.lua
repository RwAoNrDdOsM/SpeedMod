local mod = get_mod("SpeedMod")
--[[dofile("scripts/mods/SpeedMod/view/active_mods_view")



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

--Active Mods on Cutscene
mod:hook(CutsceneUI, "set_letterbox_enabled", function(self, ...)
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
end]]

--Boss Wall Removal

--This hook is from Prop Joe's Spawn Tweaks (Modified)
--- Disable boss doors.
mod:hook(DoorSystem, "update", function(func, self, context, t)
	if mod:get("boss_walls") then
		for map_section, _ in pairs(table.clone(self._active_groups)) do
			self:open_boss_doors(map_section)
			self._active_groups[map_section] = nil
		end
	end

	return func(self, context, t)
end)

--Restart Level
--Taken from Propjoe's Github "Helpers"
mod.do_insta_fail = false
mod.do_restart = false

mod.restart_level = function()
	mod:pcall(function()
		if Managers.state.game_mode:level_key() == "inn_level" then
			mod:echo("Can't restart in the keep.")
			return
		end

		mod.do_insta_fail = true
		mod.do_restart = true
		Managers.state.game_mode:fail_level()
	end)
end

mod:hook(GameModeAdventure, "evaluate_end_conditions", function(func, self, round_started, dt, t, ...)
	if self.lost_condition_timer and mod.do_insta_fail then
		mod.do_insta_fail = false
		self.lost_condition_timer = t - 1
	end
	local ended, reason = func(self, round_started, dt, t, ...)

	if ended and mod.do_restart then
		mod.do_restart = false
		return ended, "reload"
	end

	return ended, reason
end)

-- Potion Share
mod:hook_origin(ActionPotion, "finish", function (self, reason)
	if reason ~= "action_complete" then
		return
	end

	local current_action = self.current_action
	local owner_unit = self.owner_unit
	local buff_template = current_action.buff_template
	local buff_extension = ScriptUnit.extension(owner_unit, "buff_system")
	local potion_spread = buff_extension:has_buff_type("trait_ring_potion_spread")
	local targets = {
		owner_unit
	}
	local smallest_distance = TrinketSpreadDistance
	local additional_target = nil
	if mod:get("potion_share") then
		smallest_distance = 15
	end

	if potion_spread then
		local num_players = #PLAYER_AND_BOT_UNITS
		local owner_player_position = POSITION_LOOKUP[owner_unit]

		for i = 1, num_players, 1 do
			local other_player_unit = PLAYER_AND_BOT_UNITS[i]

			if Unit.alive(other_player_unit) and other_player_unit ~= owner_unit then
				local other_player_position = POSITION_LOOKUP[other_player_unit]
				local distance = Vector3.distance(owner_player_position, other_player_position)

				if distance <= smallest_distance then
					if not mod:get("potion_share") then
						smallest_distance = distance
					end
					additional_target = other_player_unit

					if additional_target then
						targets[#targets + 1] = additional_target
					end
				end
			end
		end
	end

	if buff_extension:has_buff_perk("potion_duration") then
		buff_template = buff_template .. "_increased"
	end

	local num_targets = #targets
	local network_manager = Managers.state.network
	local buff_template_name_id = NetworkLookup.buff_templates[buff_template]
	local owner_unit_id = network_manager:unit_game_object_id(owner_unit)

	if not buff_extension:has_buff_type("trait_ring_all_potions") then
		for i = 1, num_targets, 1 do
			local target_unit = targets[i]
			local unit_object_id = network_manager:unit_game_object_id(target_unit)
			local target_unit_buff_extension = ScriptUnit.extension(target_unit, "buff_system")

			if self.is_server then
				target_unit_buff_extension:add_buff(buff_template)
				network_manager.network_transmit:send_rpc_clients("rpc_add_buff", unit_object_id, buff_template_name_id, owner_unit_id, 0, false)
			else
				network_manager.network_transmit:send_rpc_server("rpc_add_buff", unit_object_id, buff_template_name_id, owner_unit_id, 0, true)
			end
		end
	else
		local additional_potion_buffs = {
			"speed_boost_potion_reduced",
			"damage_boost_potion_reduced",
			"cooldown_reduction_potion_reduced"
		}

		for i = 1, #additional_potion_buffs, 1 do
			local additional_buff_template_name_id = NetworkLookup.buff_templates[additional_potion_buffs[i]]

			if self.is_server then
				buff_extension:add_buff(additional_potion_buffs[i])
				network_manager.network_transmit:send_rpc_clients("rpc_add_buff", owner_unit_id, additional_buff_template_name_id, owner_unit_id, 0, false)
			else
				network_manager.network_transmit:send_rpc_server("rpc_add_buff", owner_unit_id, additional_buff_template_name_id, owner_unit_id, 0, true)
			end
		end
	end

	if self.ammo_extension then
		local ammo_usage = current_action.ammo_usage
		local _, procced = buff_extension:apply_buffs_to_value(0, "not_consume_potion")

		if not procced then
			self.ammo_extension:use_ammo(ammo_usage)
		else
			local inventory_extension = ScriptUnit.extension(owner_unit, "inventory_system")

			inventory_extension:wield_previous_weapon()

			if buff_extension:has_buff_type("trait_ring_not_consume_potion_damage") then
				DamageUtils.debug_deal_damage(self.owner_unit, "basic_debug_damage_player")
			end
		end
	end

	local player = Managers.player:unit_owner(owner_unit)
	local position = POSITION_LOOKUP[owner_unit]

	Managers.telemetry.events:player_used_item(player, self.item_name, position)
end)

local vmf = get_mod("VMF")
mod:hook("Localize", function(func, text_id)
    local str = vmf.quick_localize(mod, text_id)
	if str and mod:get("potion_share") then 
		return str 
	end
    return func(text_id)
end)

-- Heaps of stuff
mod.on_game_state_changed = function(status, state_name)
	-- disable careers
	if state_name == "StateIngame" and status == "enter" and mod:get("career_ability") == "disable_career_ability" then
		local units = PLAYER_AND_BOT_UNITS
		if #units == 0 then
			return
		end

		for i = 1, #units, 1 do
			local owner_unit = units[i]
			local is_server = Managers.state.network.is_server
			local network_manager = Managers.state.network
			local network_transmit = network_manager.network_transmit
			local buff_name = "disable_career_ability"
			local unit_object_id = network_manager:unit_game_object_id(owner_unit)
			local buff_template_name_id = NetworkLookup.buff_templates[buff_name]
			local local_player = Managers.player:local_player().player_unit
			local bot_player = not Managers.player:is_player_unit(owner_unit)

			if not buff_extension:has_buff_perk("disable_career_ability") and local_player == owner_unit or (is_server and bot_player) then
				if is_server then
					local buff_extension = ScriptUnit.extension(owner_unit, "buff_system")

					buff_extension:add_buff(buff_name, {
						attacker_unit = owner_unit
					})
					network_transmit:send_rpc_clients("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, false)
				else
					network_transmit:send_rpc_server("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, true)
				end
			end
		end
	end
	-- Reset Ults on new game
	if state_name == "StateIngame" and status == "enter" and mod:get("career_ability") ~= "disable_career_ability" then
		local units = PLAYER_AND_BOT_UNITS
		if #units == 0 then
			return
		end

		for i=1, #units, 1 do
			local owner_unit = units[i]
			local is_server = Managers.state.network.is_server
			local local_player = Managers.player:local_player().player_unit
			local bot_player = not Managers.player:is_player_unit(owner_unit)
			if local_player == owner_unit or (is_server and bot_player) then
				local career_extension = ScriptUnit.extension(owner_unit, "career_system")
				career_extension:reset_cooldown()
				career_extension:start_activated_ability_cooldown()
				career_extension._activated_ability.amount_career_ability = 0
				if not mod:get("no_cooldown") then
					career_extension._cooldown = 0
				end
			end
		end
	end
end

mod.on_setting_changed = function(setting_id)
	-- disable careers
	if setting_id == "career_ability" then
		local value = mod:get("career_ability")

		if value == "disable_career_ability" then
			local units = PLAYER_AND_BOT_UNITS
			if #units == 0 then
				return
			end

			for i=1, #units, 1 do
				local owner_unit = units[i]
				local is_server = Managers.state.network.is_server
				local network_manager = Managers.state.network
				local network_transmit = network_manager.network_transmit
				local buff_name = "disable_career_ability"
				local unit_object_id = network_manager:unit_game_object_id(owner_unit)
				local buff_template_name_id = NetworkLookup.buff_templates[buff_name]
				local buff_extension = ScriptUnit.extension(owner_unit, "buff_system")
				local local_player = Managers.player:local_player().player_unit
				local bot_player = not Managers.player:is_player_unit(owner_unit)

				if not buff_extension:has_buff_perk("disable_career_ability") and local_player == owner_unit or (is_server and bot_player) then
					if is_server then			
						buff_extension:add_buff(buff_name, {
							attacker_unit = owner_unit
						})
						network_transmit:send_rpc_clients("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, false)
					else
						network_transmit:send_rpc_server("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, true)
					end
					local career_extension = ScriptUnit.extension(owner_unit, "career_system")
					career_extension:reset_cooldown()
					career_extension:set_activated_ability_cooldown_paused()
				end
			end
		else
			local units = PLAYER_AND_BOT_UNITS
			if #units == 0 then
				return
			end

			for i=1, #units, 1 do
				local owner_unit = units[i]
				local is_server = Managers.state.network.is_server
				local network_manager = Managers.state.network
				local network_transmit = network_manager.network_transmit
				local buff_name = "disable_career_ability"
				local unit_object_id = network_manager:unit_game_object_id(owner_unit)
				local buff_template_name_id = NetworkLookup.buff_templates[buff_name]
				local buff_extension = ScriptUnit.extension(owner_unit, "buff_system")
				local local_player = Managers.player:local_player().player_unit
				local bot_player = not Managers.player:is_player_unit(owner_unit)
				if buff_extension:has_buff_perk("disable_career_ability") and local_player == owner_unit or (is_server and bot_player) then
					local buff = buff_extension:get_non_stacking_buff(buff_name)
					buff_extension:remove_buff(buff.id)
				end
				if Managers.state.game_mode:level_key() == "inn_level" then 
					local career_extension = ScriptUnit.extension(owner_unit, "career_system")
					career_extension:reset_cooldown()
					career_extension:start_activated_ability_cooldown()
					career_extension._activated_ability.amount_career_ability = 0
					if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
						career_extension._cooldown = 0
					end
				end
			end
		end
	end
	-- Speed Stacking
	if setting_id == "speed_stacking" then
		if mod:get("speed_stacking") then
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
						stat_buff = "attack_speed",
						refresh_durations = true,
						--max_stacks = 1,
						duration = 10
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
						stat_buff = "attack_speed",
						refresh_durations = true,
						--max_stacks = 1,
						duration = 15
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
						stat_buff = "attack_speed",
						refresh_durations = true,
						--max_stacks = 1,
						duration = 5
					}
				}
			}
		else
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
						max_stacks = 1,
						duration = 10,
						path_to_movement_setting_to_modify = {
							"move_speed"
						}
					},
					{
						multiplier = 0.5,
						name = "attack speed buff",
						stat_buff = "attack_speed",
						refresh_durations = true,
						max_stacks = 1,
						duration = 10
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
						max_stacks = 1,
						duration = 15,
						path_to_movement_setting_to_modify = {
							"move_speed"
						}
					},
					{
						multiplier = 0.5,
						name = "attack speed buff",
						stat_buff = "attack_speed",
						refresh_durations = true,
						max_stacks = 1,
						duration = 15
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
						max_stacks = 1,
						duration = 5,
						path_to_movement_setting_to_modify = {
							"move_speed"
						}
					},
					{
						multiplier = 0.5,
						name = "attack speed buff",
						stat_buff = "attack_speed",
						refresh_durations = true,
						max_stacks = 1,
						duration = 5
					}
				}
			}
		end
	end
	-- Boss Walls
	if setting_id == "boss_walls" then
		local function count_event_breed(breed_name)
			return Managers.state.conflict:count_units_by_breed_during_event(breed_name)
		end
		if mod:get("boss_walls") then
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
					"flow_event",
					flow_event_name = "farmlands_barn_boss_spawned"
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
	end
end

-- Remove Ability/Set amount of abilities
BuffTemplates.disable_career_ability = {
	buffs = {
		{
			name = "disable_career_ability",
			perk = "disable_career_ability",
			max_stacks = 1,
		}
	}
}
local index = #NetworkLookup.buff_templates + 1
NetworkLookup.buff_templates[index] = "disable_career_ability"
NetworkLookup.buff_templates.disable_career_ability = index


-- Battle Wizard
mod:hook_safe(CareerAbilityBWAdept, "init", function (self, ...)
	self.amount_career_ability = 0
end)

local function dprint(...)
	if DEBUG then
		printf(...)
	end
end

mod:hook_origin(CareerAbilityBWAdept, "_run_ability", function (self, ...)
	dprint("_run_ability")
	self:_stop_priming()

	local end_position = self._last_valid_position and self._last_valid_position:unbox()

	if not end_position then
		dprint("no end_position")

		return
	end

	local owner_unit = self.owner_unit
	local is_server = self.is_server
	local local_player = self.local_player
	local bot_player = self.bot_player
	local network_manager = self.network_manager
	local career_extension = self.career_extension
	local talent_extension = ScriptUnit.extension(owner_unit, "talent_system")

	if local_player or (is_server and bot_player) then
		local start_pos = POSITION_LOOKUP[owner_unit]
		local nav_world = Managers.state.entity:system("ai_system"):nav_world()
		local projected_start_pos = LocomotionUtils.pos_on_mesh(nav_world, start_pos, 2, 30)

		if projected_start_pos then
			local damage_wave_template_name = "sienna_adept_ability_trail"

			if talent_extension:has_talent("sienna_adept_ability_trail_increased_duration", "bright_wizard", true) then
				damage_wave_template_name = "sienna_adept_ability_trail_increased_duration"
			end

			local damage_wave_template_id = NetworkLookup.damage_wave_templates[damage_wave_template_name]
			local invalid_game_object_id = NetworkConstants.invalid_game_object_id

			network_manager.network_transmit:send_rpc_server("rpc_create_damage_wave", invalid_game_object_id, projected_start_pos, end_position, damage_wave_template_id)
		end
	end

	if local_player then
		local first_person_extension = self.first_person_extension

		first_person_extension:animation_event("battle_wizard_active_ability_blink")

		MOOD_BLACKBOARD.skill_adept = true

		career_extension:set_state("sienna_activate_adept")
	end

	local locomotion_extension = self.locomotion_extension

	locomotion_extension:teleport_to(end_position)

	local position = end_position
	local rotation = Unit.local_rotation(owner_unit, 0)
	local explosion_template = "sienna_adept_activated_ability_end_stagger"
	local scale = 1
	local career_power_level = career_extension:get_career_power_level()
	local area_damage_system = Managers.state.entity:system("area_damage_system")

	area_damage_system:create_explosion(owner_unit, position, rotation, explosion_template, scale, "career_ability", career_power_level, false)

	if talent_extension:has_talent("sienna_adept_ability_trail_double", "bright_wizard", true) then
		if local_player or (is_server and bot_player) then
			local buff_extension = self.buff_extension

			if buff_extension and buff_extension:has_buff_type("sienna_adept_ability_trail_double") then
				career_extension:start_activated_ability_cooldown()
				if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
					career_extension._cooldown = 0
				end

				local buff_id = self._double_ability_buff_id

				if buff_id then
					buff_extension:remove_buff(buff_id)
				end
			elseif buff_extension then
				self._double_ability_buff_id = buff_extension:add_buff("sienna_adept_ability_trail_double")
				self.amount_career_ability = self.amount_career_ability + 1
			end
		end
	else
		career_extension:start_activated_ability_cooldown()
		self.amount_career_ability = self.amount_career_ability + 1
		if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
			career_extension._cooldown = 0
		end
	end

	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_bw"))
	if set_amount and self.amount_career_ability >= set_amount then
		local unit = owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	self:_play_vo()
end)

-- Pyro
mod:hook_safe(ActionCareerBWScholar, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(ActionCareerBWScholar, "finish", function (self, ...)
	if self.state == "shot" then
		self.amount_career_ability = self.amount_career_ability + 1
	end
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_pm"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end

	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Unchained
mod:hook_safe(CareerAbilityBWUnchained, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityBWUnchained, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_uc"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Iron Breaker
mod:hook_safe(CareerAbilityDRIronbreaker, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityDRIronbreaker, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_ib"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Ranger Vet
mod:hook_safe(ActionCareerDRRanger, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(ActionCareerDRRanger, "finish", function (self, ...)
	if self.thrown then
		self.amount_career_ability = self.amount_career_ability + 1
	end
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_rv"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Slayer
mod:hook_safe(CareerAbilityDRSlayer, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityDRSlayer, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_sl"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Mercenary
mod:hook_safe(CareerAbilityESMercenary, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityESMercenary, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_mn"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Hunstman
mod:hook_safe(CareerAbilityESHuntsman, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityESHuntsman, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_hnm"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Footknight
mod:hook_safe(CareerAbilityESKnight, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityESKnight, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_fk"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Waywatcher
mod:hook_safe(ActionCareerWEWaywatcher, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(ActionCareerWEWaywatcher, "finish", function (self, ...)
	if self.state == "shot" then
		self.amount_career_ability = self.amount_career_ability + 1
	end
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_ww"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Handmaiden
mod:hook_safe(CareerAbilityWEMaidenGuard, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityWEMaidenGuard, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_hm"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Shade
mod:hook_safe(CareerAbilityWEShade, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityWEShade, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_sh"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- WHC
mod:hook_safe(CareerAbilityWHCaptain, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityWHCaptain, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_whc"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Bounty Hunter
mod:hook_safe(ActionCareerWHBountyhunter, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(ActionCareerWHBountyhunter, "finish", function (self, ...)
	if self.upper_shot_done and self.lower_shot_done then
		self.amount_career_ability = self.amount_career_ability + 1
	end
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_bh"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

-- Zealot
mod:hook_safe(CareerAbilityWHZealot, "init", function (self, ...)
	self.amount_career_ability = 0
end)
mod:hook_safe(CareerAbilityWHZealot, "_run_ability", function (self, ...)
	self.amount_career_ability = self.amount_career_ability + 1
	local set_amount = (mod:get("career_ability") == "disable_career_ability" and	false) 	
									or (mod:get("career_ability") == "set_amount_career_ability" and mod:get("set_amount_career_ability_value"))  
									or (mod:get("career_ability") == "set_amount_career_ability_each_career" and mod:get("set_amount_career_ability_ze"))
	if set_amount and self.amount_career_ability >= set_amount then
		local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
		local career_extension = ScriptUnit.extension(owner_unit, "career_system")
		career_extension:reset_cooldown()
		career_extension:set_activated_ability_cooldown_paused()
	end
	local owner_unit = self.owner_unit or Managers.player:local_player().player_unit
	local career_extension = ScriptUnit.extension(owner_unit, "career_system")
	if not mod:get("no_cooldown") and not career_extension:current_ability_paused() then
		career_extension._cooldown = 0
	end
end)

--Commands
--mod:command("active_mods", mod:localize("active_mods_command_description"), function() mod.active_mods() end)
mod:command("ree", mod:localize("ree_command_description"), function() mod.restart_level() end)