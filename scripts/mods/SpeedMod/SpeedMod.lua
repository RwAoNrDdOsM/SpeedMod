local mod = get_mod("SpeedMod")
dofile("scripts/mods/SpeedMod/view/active_mods_view")

-- Custom view
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


--From Prop Joe's Spawn Tweaks (Modified)
mod:hook(DoorSystem, "update", function(func, self, context, t)
    if self.is_server then
        for map_section, _ in pairs(table.clone(self._active_groups)) do
            self:open_boss_doors(map_section)
            self._active_groups[map_section] = nil
        end
    end

    return func(self, context, t)
end)

TerrorEventBlueprints.farmlands_rat_ogre = {
  {
    "set_master_event_running",
    name = "farmlands_boss_barn"
  },
  {
    "spawn_at_raw",
    spawner_id = "farmlands_rat_ogre",
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
    flow_event_name = "farmlands_barn_boss_spawned"
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

--Active Mods on cutscene
mod:hook(CutsceneUI, "set_letterbox_enabled", function(func, self, ...)
  local is_in_inn = self.is_in_inn
  local cutscene_system = Managers.state.entity:system("cutscene_system")

  if not self.is_in_inn and cutscene_system.active_camera then
    mod.active_mods()
  end
  return func(self, ...)
end)

--Active Mods View Opening
mod.active_mods = function() 
  ingame_ui:handle_transition("active_mods_view")
end

-- Active Mods Command
mod:command("active_mods", mod:localize("active_mods_command_description"), function() mod.active_mods() end)