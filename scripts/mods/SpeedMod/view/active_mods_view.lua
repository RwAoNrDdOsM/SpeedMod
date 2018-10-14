-- File that defines scenegraph and widgets
local definitions = dofile("scripts/mods/SpeedMod/view/active_mods_view_definitions")
local scenegraph_definition = definitions.scenegraph_definition
local console_cursor_definition = definitions.console_cursor_definition
local widget_definitions = definitions.widgets
local generic_input_actions = definitions.generic_input_actions
local mod = get_mod("SpeedMod")
-- The class that defines the view and it's behavior. Needs to provide pretty much the same API as other view classes
ActiveModsView = class(ActiveModsView)

-- Called once on game start/mod reload
function ActiveModsView:init(ingame_ui_context)
  self.ui_renderer = ingame_ui_context.ui_renderer
  self.ui_top_renderer = ingame_ui_context.ui_top_renderer
  self.ingame_ui = ingame_ui_context.ingame_ui
  self.statistics_db = ingame_ui_context.statistics_db
  self.render_settings = { snap_pixel_positions = true }

  -- Create input service
  local input_manager = ingame_ui_context.input_manager
  self.input_manager = input_manager

  -- Input service name can be chosen freely
  input_manager:create_input_service("active_mods_view", "IngameMenuKeymaps", "IngameMenuFilters")
  input_manager:map_device_to_service("active_mods_view", "keyboard")
  input_manager:map_device_to_service("active_mods_view", "mouse")
  input_manager:map_device_to_service("active_mods_view", "gamepad")

  -- Not 100% sure what this does, simply taken from "Okri's Challenges" view
  self.menu_input_description = MenuInputDescriptionUI:new(
    ingame_ui_context,
    self.ui_top_renderer,
    input_manager:get_service("active_mods_view"),
    3,
    100,
    generic_input_actions
  )
  self.menu_input_description:set_input_description(nil)

  self.wwise_world = Managers.world:wwise_world(ingame_ui_context.world_manager:world("level_world"))
end

-- Called when the view is opened
function ActiveModsView:on_enter()
  -- Enable mouse cursor while the view is open
  ShowCursorStack.push()

  local input_manager = self.input_manager
  input_manager:block_device_except_service("active_mods_view", "keyboard", 1)
  input_manager:block_device_except_service("active_mods_view", "mouse", 1)
  input_manager:block_device_except_service("active_mods_view", "gamepad", 1)

  self:create_ui_elements()
  -- Nice touch. Choose any sound you like
  self:play_sound("Play_gui_achivements_menu_open")
  input_manager:enable_gamepad_cursor()
end

-- Called when view is closed
function ActiveModsView:on_exit()
  local input_manager = self.input_manager
  input_manager:device_unblock_all_services("keyboard", 1)
  input_manager:device_unblock_all_services("mouse", 1)
  input_manager:device_unblock_all_services("gamepad", 1)

  ShowCursorStack.pop()
end

function ActiveModsView:create_ui_elements()
  self.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
  self._console_cursor_widget = UIWidget.init(console_cursor_definition)
  local widgets = {}
  local widgets_by_name = {}

  for name, widget_definition in pairs(widget_definitions) do
    if widget_definition then
      local widget = UIWidget.init(widget_definition)
      widgets[#widgets + 1] = widget
      widgets_by_name[name] = widget
    end
  end

  self._widgets = widgets
  self._widgets_by_name = widgets_by_name

  self._widgets_by_name.title_text.content.text = "Activated Mods"
  self._widgets_by_name.window_text.content.text = mod_table.name .. "\n"
  self._widgets_by_name.window_text.style.text.font_size = mod.CurrentLoreFontSize

  UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

function ActiveModsView:update(dt)
  self:_update_animations(dt)
  self:draw(dt, self:input_service())
  self:_handle_input(dt)
end

-- Update animations, simple buttons but also complex custom animations
-- See `HeroViewStateAchievements`, which has some animations on the `summary` screen
function ActiveModsView:_update_animations(dt)
  local widgets_by_name = self._widgets_by_name

  UIWidgetUtils.animate_default_button(widgets_by_name.exit_button, dt)
end

-- Draw widgets
function ActiveModsView:draw(dt, input_service)
  local ui_renderer = self.ui_renderer
  local ui_top_renderer = self.ui_top_renderer
  local ui_scenegraph = self.ui_scenegraph
  local input_manager = self.input_manager
  local render_settings = self.render_settings

  UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, render_settings)

  local snap_pixel_positions = render_settings.snap_pixel_positions
  local alpha_multiplier = render_settings.alpha_multiplier or 1

  for _, widget in ipairs(self._widgets) do
    if widget.snap_pixel_positions ~= nil then
      render_settings.snap_pixel_positions = widget.snap_pixel_positions
    end

    render_settings.alpha_multiplier = widget.alpha_multiplier or alpha_multiplier

    UIRenderer.draw_widget(ui_renderer, widget)

    render_settings.snap_pixel_positions = snap_pixel_positions
  end

  UIRenderer.end_pass(ui_renderer)

  render_settings.alpha_multiplier = alpha_multiplier

  -- Handle the gamepad cursor, if required
  local gamepad_active = input_manager:is_device_active("gamepad")
  if gamepad_active then
    self.menu_input_description:draw(ui_top_renderer, dt)
    UIRenderer.begin_pass(ui_top_renderer, ui_scenegraph, input_service, dt)
    UIRenderer.draw_widget(ui_top_renderer, self._console_cursor_widget)
    UIRenderer.end_pass(ui_top_renderer)
  end
end

-- Handle button hover and presses
function ActiveModsView:_handle_input(dt)
  local input_service = self:input_service()
  local gamepad_active = Managers.input:is_device_active("gamepad")

  local widgets_by_name = self._widgets_by_name
  local exit_button = widgets_by_name.exit_button

  if input_service:get("toggle_menu") or self:_is_button_pressed(exit_button) or (gamepad_active and input_service:get("back")) then
    self:close_menu()
  end

  if self:_is_button_hover_enter(exit_button) then
    self:play_sound("play_gui_equipment_button_hover")
  end

  -- TODO: Add other buttons here
end

function ActiveModsView:close_menu()
  Managers.player:local_player().network_manager.matchmaking_manager._ingame_ui:handle_transition("exit_menu")
end

function ActiveModsView:play_sound(event)
  WwiseWorld.trigger_event(self.wwise_world, event)
end

function ActiveModsView:input_service()
  return self.input_manager:get_service("active_mods_view")
end

function ActiveModsView:_is_button_hover_enter(widget)
  return widget.content.button_hotspot.on_hover_enter or false
end

function ActiveModsView:_is_button_pressed(widget)
  local content = widget.content
  local hotspot = content.button_hotspot or content.hotspot

  if hotspot.on_release then
    hotspot.on_release = false

    return true
  end

  return false
end