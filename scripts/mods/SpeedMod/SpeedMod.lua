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
      ingame = false,
    },
    -- There is no check for `nil` in `mod:register_new_views`, so even if empty, these have to be defined
    blocked_transitions = {
      inn = {},
      ingame = {},
    },
    --`settings_id`/`setting_name` which defines the keybind
    hotkey_name = "settings_id",
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


--[[From Prop Joe's Spawn Tweaks (Modified) --]]
mod:hook(DoorSystem, "update", function(func, self, context, t)
    if self.is_server then
        for map_section, _ in pairs(table.clone(self._active_groups)) do
            self:open_boss_doors(map_section)
            self._active_groups[map_section] = nil
        end
    end

    return func(self, context, t)
end)

--[[ Display Active Mods --]]
mod:hook(EndViewStateScore, "create_ui_elements", function(func, self, ...)
    if self.game_won then
        mod:active_mods()
    end
    return func(self, ...)
end)

mod.active_mods = function() 
  mod.open_active_mods_view
end

mod:command("active_mods", mod:localize("active_mods_command_description"), function() mod.active_mods() end)