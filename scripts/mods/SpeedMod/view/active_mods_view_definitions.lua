local window_default_settings = UISettings.game_start_windows
local window_size = window_default_settings.large_window_size
local window_top_height = 200
local activated_mods = { }



-- Width of the default frame's border. Used for calculations
local frame_border_width = 22

local inner_window_width = window_size[1] - (2 * frame_border_width)

local title_text_style = {
  use_shadow = true,
  upper_case = true,
  localize = false,
  font_size = 28,
  horizontal_alignment = "center",
  vertical_alignment = "center",
  dynamic_font_size = true,
  font_type = "hell_shark_header",
  text_color = Colors.get_color_table_with_alpha("font_title", 255),
  offset = {
    0,
    0,
    2
  }
}

local window_text_style = {
  use_shadow = false,
  upper_case = false,
  localize = false,
  font_size = 54,
  horizontal_alignment = "center",
  vertical_alignment = "center",
  dynamic_font_size = false,
  word_wrap = true,
  font_type = "hell_shark_header",
  text_color = {
		255,
		255,
		255,
		255
},
  offset = {
    0,
    0,
    2
  }
}

local scenegraph_definition = {
  root = {
    is_root = true,
    size = {
      1920,
      1080
    },
    position = {
      0,
      0,
      UILayer.default
    }
  },
  menu_root = {
    vertical_alignment = "center",
    parent = "root",
    horizontal_alignment = "center",
    size = {
      1920,
      1080
    },
    position = {
      0,
      0,
      0
    }
  },
  screen = {
    scale = "fit",
    size = {
      1920,
      1080
    },
    position = {
      0,
      0,
      UILayer.default
    }
  },
  console_cursor = {
    vertical_alignment = "center",
    parent = "screen",
    horizontal_alignment = "center",
    size = {
      1920,
      1080
    },
    position = {
      0,
      0,
      0
    }
  },
  header = {
    vertical_alignment = "top",
    parent = "menu_root",
    horizontal_alignment = "center",
    size = {
      1920,
      50
    },
    position = {
      0,
      -20,
      100
    }
  },
  window = {
    vertical_alignment = "center",
    parent = "screen",
    horizontal_alignment = "center",
    size = window_size,
    position = {
      0,
      0,
      1
    }
  },
  window_background = {
    vertical_alignment = "center",
    parent = "window",
    horizontal_alignment = "center",
    size = {
      window_size[1] - 5,
      window_size[2] - 5
    },
    position = {
      0,
      0,
      0
    }
  },
  exit_button = {
    vertical_alignment = "bottom",
    parent = "window",
    horizontal_alignment = "center",
    size = {
      380,
      42
    },
    position = {
      0,
      -16,
      42
    }
  },
  title = {
    vertical_alignment = "top",
    parent = "window",
    horizontal_alignment = "center",
    size = {
      658,
      60
    },
    position = {
      0,
      34,
      46
    }
  },
  title_bg = {
    vertical_alignment = "top",
    parent = "title",
    horizontal_alignment = "center",
    size = {
      410,
      40
    },
    position = {
      0,
      -15,
      -1
    }
  },
  title_text = {
    vertical_alignment = "center",
    parent = "title",
    horizontal_alignment = "center",
    size = {
      350,
      50
    },
    position = {
      0,
      -3,
      2
    }
  },
  -- TODO: Add scenegraph definitions for your widgets here
  activated_mods_text = {
    vertical_alignment = "center",
    parent = "window",
    horizontal_alignment = "center",
    size = {
      1920,
      1080
    },
    position = {
      0,
      0,
      0
    }
  },
}

-- In the for loop
for index, mod_table in ipairs(Managers.mod._mods) do
  if mod_table.enabled then
      table.insert(activated_mods, mod_table.name)
  end
end

-- And finally, concat it all, separated by newlines.
activated_mods = table.concat(activated_mods, "\n")

local disable_with_gamepad = true
local widgets = {
  window = UIWidgets.create_frame("window", scenegraph_definition.window.size, "menu_frame_11", 40),
	window_background = UIWidgets.create_tiled_texture("window_background", "menu_frame_bg_01", {
		960,
		1080
	}, nil, nil, {
		255,
		100,
		100,
		100
	}),
  -- Close button at the bottom
  exit_button = UIWidgets.create_default_button(
    "exit_button",
    scenegraph_definition.exit_button.size,
    nil,
    nil,
    Localize("menu_close"),
    24,
    nil,
    "button_detail_04",
    34,
    disable_with_gamepad
  ),
  -- Title at top
  title = UIWidgets.create_simple_texture("frame_title_bg", "title"),
  title_bg = UIWidgets.create_background("title_bg", scenegraph_definition.title_bg.size, "menu_frame_bg_02"),
  -- TODO: Move to mod:localize
  title_text = UIWidgets.create_simple_text("Activated Mods", "title_text", nil, nil, title_text_style),
  activated_mods_text = UIWidgets.create_simple_text(activated_mods, "activated_mods_text", nil, nil, window_text_style),
}

local generic_input_actions = {
  {
    input_action = "confirm",
    priority = 2,
    description_text = "input_description_select"
  },
  {
    input_action = "back",
    priority = 3,
    description_text = "input_description_close"
  }
}

return {
  scenegraph_definition = scenegraph_definition,
  widgets = widgets,
  generic_input_actions = generic_input_actions,
  console_cursor_definition = UIWidgets.create_console_cursor("console_cursor"),
}