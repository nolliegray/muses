-- Muses
-- Ver 1.0.0
--
-- A Probabilistic, Melodic,
-- Generative Sequencer
--
-- Optional: Grid & Crow
-- 
-- K1: Play/Pause (Long Hold)
-- K2: Channel Select
-- K3: Capture/Release Loop
-- K3: Reset (Long Hold)
--
-- E1: Navigate Pages
-- E2: Select Parameters
-- E3: Edit Parameter Value

-- Global Hardware and Includes
g = grid.connect()
mu = require("musicutil")
m = midi.connect(1)
nb = include("lib/nb/lib/nb")

include("lib/globals")
include("lib/engine")
include("lib/screen")
include("lib/grid")

-- Global State Variables
last_tap = 0
metro_blink = nil
blink_step = 1
held_step = 0
k1_hold = nil
grid_reset_btn_down = false
show_param_name = false
param_timer = nil
k3_timer = nil
k3_reset_fired = false

pend_hits = {}
perf_m = nil
crow_active_notes = { {}, {} }

screen_page = 1
param_sel = 1
ch1_edit = true
ch2_edit = false
seq = {}

function flash_param_name()
  show_param_name = true
  if param_timer then clock.cancel(param_timer) end
  param_timer = clock.run(function()
    clock.sleep(1.5) 
    show_param_name = false
    redraw()
  end)
end

-- Initialization
function init()
  perf_m = metro.init(perf_callback, 0.01, 1)
  
  local midi_devices = {}
  for i = 1, #midi.vports do
    midi_devices[i] = i .. ": " .. midi.vports[i].name
  end
  
  -- Params Menu
  params:add_separator("Muses")
  
  params:add_option("midi_device", "MIDI Device", midi_devices, 1)
  params:set_action("midi_device", function(val)
    m = midi.connect(val)
  end)
  
  params:add_number("midi_out_1", "MIDI Out for Ch1", 1, 16, 1)
  params:add_number("midi_out_2", "MIDI Out for Ch2", 1, 16, 2)
  
  params:add_number("bar_accent", "Bar Enforce Accent", 0, 127, 32)
  
  params:add_separator("Crow")
  local crow_opts = {"Off", "Ch1 CV", "Ch1 Gate", "Ch1 Velocity", "Ch1 Trigger", "Ch2 CV", "Ch2 Gate", "Ch2 Velocity", "Ch2 Trigger"}
  
  for i = 1, 4 do
    local default_opt = (i == 1) and 2 or ((i == 2) and 3 or ((i == 3) and 6 or 7))
    params:add_option("crow_out_" .. i, "Crow Out " .. i, crow_opts, default_opt)
    params:set_action("crow_out_" .. i, function(val)
      if val == 5 or val == 9 then
        crow.output[i].action = "pulse(0.01, 5, 1)" 
      end
    end)
  end
  
  crow.input[2].mode("change", 2.0, 0.1, "rising")
  crow.input[2].change = function(state)
    if state then
      for ch = 1, 2 do trigger_reset(ch) end
    end
  end
  
  params:add_separator("NB Voices")
  nb:init()
  nb:add_param("nb_voice_1", "Ch1 Voice")
  nb:add_param("nb_voice_2", "Ch2 Voice")
  nb:add_player_params()
  
  -- Ch1 and Ch2 Initial States
  local ch1_probs = {
    note_prob     = {100, 0, 60, 0, 85, 75, 0, 95, 0, 70, 0, 50},
    rhythm_prob   = {0, 0, 10, 100, 0, 0, 0, 0, 5, 0, 0, 0},
    chord_prob    = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    voicing_prob  = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    octave_prob   = {0, 0, 0, 0, 100, 50, 0, 0, 0, 0, 0},
    velocity_prob = {0, 25, 37, 50, 75, 12, 0, 0, 50, 50},
    ornament_prob = {25, 10, 0, 0, 10, 0, 25, 0, 10, 0, 0, 25}
  }

  local ch2_probs = {
    note_prob     = {100, 0, 0, 0, 85, 0, 0, 95, 0, 0, 0, 0},
    rhythm_prob   = {0, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0},
    chord_prob    = {100, 50, 0, 25, 0, 0, 0, 0, 0, 0, 0, 0},
    voicing_prob  = {37, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    octave_prob   = {0, 0, 25, 100, 0, 0, 0, 0, 0, 0, 0},
    velocity_prob = {0, 37, 50, 75, 37, 0, 0, 0, 50, 50},
    ornament_prob = {25, 0, 0, 0, 0, 0, 0, 0, 0, 25, 0, 10}
  }

  local function get_shared_state()
    return {
      root_idx = 1, scale_idx = 2, div_idx = 1, sig_idx = 6, swing_idx = 5, bar_enforce = 0, 
      notes = {true, false, true, false, true, true, false, true, false, true, false, true},
      note_prob = {}, rhythm_prob = {}, chord_prob = {}, voicing_prob = {}, 
      octave_prob = {}, velocity_prob = {}, ornament_prob = {},
      current_step = 0, playing = false, active_note_str = "-", is_resting = false, beat_counter = 0, 
      is_tied = false, last_midi_val = 60, active_note = 0, active_base_rhythm = 0, active_rhythm = {}, 
      active_chord = 0, active_voicing = 0, active_octave = {}, active_base_velocity = 0, active_velocity = 0, 
      active_ornaments = {}, last_event = nil, sustain_active = false, loop_head = 1, loop_buffer = {}, 
      start_step = 1, end_step = 1, play_order = 1, is_locked = false, has_locked = false, play_sub_step = 1, 
      pendulum_dir = 1, improvise = 12, is_improvising = false, bar_enforced_this_bar = false
    }
  end

  seq = { get_shared_state(), get_shared_state() }
  
  -- Loop Buffer
  for ch = 1, 2 do
    for i = 1, 64 do seq[ch].loop_buffer[i] = {} end
  end
  
  -- Build Scale
  build_scale(1)
  build_scale(2)
  
  -- Build Initial State Array
  for key, array in pairs(ch1_probs) do seq[1][key] = array end
  for key, array in pairs(ch2_probs) do seq[2][key] = array end
  
  redraw()
  grid_redraw()
  clock.run(blink_tap)
  seq[1].engine_clock = clock.run(seq_engine, 1)
  seq[2].engine_clock = clock.run(seq_engine, 2)
  
  -- Params Saved as Presets
  local function get_savable_state()
    local save_data = {}
    for ch = 1, 2 do
      save_data[ch] = {
        root_idx      = seq[ch].root_idx,
        scale_idx     = seq[ch].scale_idx,
        div_idx       = seq[ch].div_idx,
        sig_idx       = seq[ch].sig_idx,
        swing_idx     = seq[ch].swing_idx,
        bar_enforce   = seq[ch].bar_enforce,
        
        notes         = {table.unpack(seq[ch].notes)},
        note_prob     = {table.unpack(seq[ch].note_prob)},
        rhythm_prob   = {table.unpack(seq[ch].rhythm_prob)},
        chord_prob    = {table.unpack(seq[ch].chord_prob)},
        voicing_prob  = {table.unpack(seq[ch].voicing_prob)},
        octave_prob   = {table.unpack(seq[ch].octave_prob)},
        velocity_prob = {table.unpack(seq[ch].velocity_prob)},
        ornament_prob = {table.unpack(seq[ch].ornament_prob)}
      }
    end
    return save_data
  end

  params.action_write = function(filename, name, pset_number)
    local state = get_savable_state()
    local data_file = norns.state.data .. "pset_" .. pset_number .. ".data"
    tab.save(state, data_file)
  end
  
  params.action_read = function(filename, silent, pset_number)
    local data_file = norns.state.data .. "pset_" .. pset_number .. ".data"
    local loaded_state = tab.load(data_file)
    
    if loaded_state then
      for ch = 1, 2 do
        seq[ch].root_idx      = loaded_state[ch].root_idx
        seq[ch].scale_idx     = loaded_state[ch].scale_idx
        seq[ch].div_idx       = loaded_state[ch].div_idx
        seq[ch].sig_idx       = loaded_state[ch].sig_idx
        seq[ch].swing_idx     = loaded_state[ch].swing_idx
        seq[ch].bar_enforce   = loaded_state[ch].bar_enfoce or 0
        
        build_scale(ch)
        
        seq[ch].notes         = {table.unpack(loaded_state[ch].notes)}
        seq[ch].note_prob     = {table.unpack(loaded_state[ch].note_prob)}
        seq[ch].rhythm_prob   = {table.unpack(loaded_state[ch].rhythm_prob)}
        seq[ch].chord_prob    = {table.unpack(loaded_state[ch].chord_prob)}
        seq[ch].voicing_prob  = {table.unpack(loaded_state[ch].voicing_prob)}
        seq[ch].octave_prob   = {table.unpack(loaded_state[ch].octave_prob)}
        seq[ch].velocity_prob = {table.unpack(loaded_state[ch].velocity_prob)}
        seq[ch].ornament_prob = {table.unpack(loaded_state[ch].ornament_prob)}
        
      end
      
      redraw()
      if screen_page >= 3 and screen_page <= 10 then grid_redraw() end
    end
  end
  
  -- params:read(1)
end

-- Norns Encoder Functionality
function enc(n, delta)
  if n == 1 then
    screen_page = util.clamp(screen_page + delta, 1, 10)
    param_sel = 1
    show_param_name = false
    if param_timer then clock.cancel(param_timer) end

  elseif n == 2 then
    if screen_page >= 3 and screen_page <= 9 then flash_param_name() end
    
    local page_max_params = {
      [1] = 14, [2] = 5, [3] = 12, [4] = 12, [5] = 12, 
      [6] = 12, [7] = 11, [8] = 10, [9] = 12, [10] = 4
    }
    
    local max_p = page_max_params[screen_page] or 1
    local step = delta > 0 and 1 or -1
    param_sel = util.clamp(param_sel + step, 1, max_p)

  elseif n == 3 then
    if screen_page >= 3 and screen_page <= 9 then flash_param_name() end
    
    if screen_page == 1 then
      if param_sel == 1 then
        if ch1_edit then 
          seq[1].root_idx = util.clamp(seq[1].root_idx + delta, 1, #roots) 
          build_scale(1)
        end
        if ch2_edit then 
          seq[2].root_idx = util.clamp(seq[2].root_idx + delta, 1, #roots)
          build_scale(2)
        end
      elseif param_sel == 2 then
        if ch1_edit then 
          seq[1].scale_idx = util.clamp(seq[1].scale_idx + delta, 1, #scales) 
          build_scale(1)
        end
        if ch2_edit then 
          seq[2].scale_idx = util.clamp(seq[2].scale_idx + delta, 1, #scales) 
          build_scale(2)
        end
      elseif param_sel >= 3 and param_sel <= 14 then
        local note_idx = param_sel - 2
        local active_state = (delta > 0)
        if ch1_edit then seq[1].notes[note_idx] = active_state end
        if ch2_edit then seq[2].notes[note_idx] = active_state end
      end
      
    elseif screen_page == 2 then
      if param_sel == 1 then
        if params:get("clock_source") == 1 then
          local current_tempo = params:get("clock_tempo")
          local new_tempo = util.clamp(current_tempo + delta, 30, 300)
          params:set("clock_tempo", new_tempo)
        end
      elseif param_sel == 2 then
        if ch1_edit then seq[1].div_idx = util.clamp(seq[1].div_idx + delta, 1, #clock_options.div) end
        if ch2_edit then seq[2].div_idx = util.clamp(seq[2].div_idx + delta, 1, #clock_options.div) end
      elseif param_sel == 3 then
        if ch1_edit then seq[1].swing_idx = util.clamp(seq[1].swing_idx + delta, 1, #clock_options.swing) end
        if ch2_edit then seq[2].swing_idx = util.clamp(seq[2].swing_idx + delta, 1, #clock_options.swing) end
      elseif param_sel == 4 then
        if ch1_edit then seq[1].sig_idx = util.clamp(seq[1].sig_idx + delta, 1, #clock_options.sig) end
        if ch2_edit then seq[2].sig_idx = util.clamp(seq[2].sig_idx + delta, 1, #clock_options.sig) end
      elseif param_sel == 5 then
        local accel = delta * math.abs(delta)
        if ch1_edit then seq[1].bar_enforce = util.clamp(seq[1].bar_enforce + accel, 0, 100) end
        if ch2_edit then seq[2].bar_enforce = util.clamp(seq[2].bar_enforce + accel, 0, 100) end
      end
      
    elseif screen_page >= 3 and screen_page <= 9 then
      local page_keys = {
        [3] = "note_prob", [4] = "rhythm_prob", [5] = "chord_prob",
        [6] = "voicing_prob", [7] = "octave_prob", [8] = "velocity_prob", [9] = "ornament_prob"
      }
      local edit_key = page_keys[screen_page]
      local accel = delta * math.abs(delta)
      
      if ch1_edit then
        seq[1][edit_key][param_sel] = util.clamp(seq[1][edit_key][param_sel] + accel, 0, 100)
      end
      
      if ch2_edit then
        if ch1_edit then
          seq[2][edit_key][param_sel] = seq[1][edit_key][param_sel]
        else
          seq[2][edit_key][param_sel] = util.clamp(seq[2][edit_key][param_sel] + accel, 0, 100)
        end
      end
      
    elseif screen_page == 10 then
      local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
      
      if param_sel == 1 then
        seq[display_ch].start_step = util.clamp(seq[display_ch].start_step + delta, 1, 64)
        seq[display_ch].bounds_set = (seq[display_ch].start_step ~= 1 or seq[display_ch].end_step ~= 1)
        if ch1_edit and ch2_edit then 
          seq[ch1_edit and 2 or 1].start_step = seq[display_ch].start_step 
          seq[ch1_edit and 2 or 1].bounds_set = seq[display_ch].bounds_set
        end
        
      elseif param_sel == 2 then
        seq[display_ch].end_step = util.clamp(seq[display_ch].end_step + delta, 1, 64)
        seq[display_ch].bounds_set = (seq[display_ch].start_step ~= 1 or seq[display_ch].end_step ~= 1)
        if ch1_edit and ch2_edit then 
          seq[ch1_edit and 2 or 1].end_step = seq[display_ch].end_step 
          seq[ch1_edit and 2 or 1].bounds_set = seq[display_ch].bounds_set
        end
        
      elseif param_sel == 3 then
        seq[display_ch].play_order = util.clamp(seq[display_ch].play_order + delta, 1, #order_options)
        if ch1_edit and ch2_edit then seq[ch1_edit and 2 or 1].play_order = seq[display_ch].play_order end
        
      elseif param_sel == 4 then
        local accel = delta * math.abs(delta)
        seq[display_ch].improvise = util.clamp(seq[display_ch].improvise + accel, 0, 100)
        if ch1_edit and ch2_edit then seq[ch1_edit and 2 or 1].improvise = seq[display_ch].improvise end
      end
    end
  end
  
  redraw()
  grid_redraw()
end

-- Norns Key Functionality
function key(n, z)
  if n == 1 then
    if z == 1 then
      k1_hold = clock.run(function()
        clock.sleep(0.5)
        if ch1_edit then seq[1].playing = not seq[1].playing end
        if ch2_edit then seq[2].playing = not seq[2].playing end
        redraw()
        grid_redraw()
      end)
    elseif z == 0 then
      if k1_hold ~= nil then
        clock.cancel(k1_hold)
        k1_hold = nil
      end
    end
    
  elseif n == 2 then
    if z == 1 then
      if ch1_edit and not ch2_edit then
        ch1_edit = false
        ch2_edit = true
      elseif not ch1_edit and ch2_edit then
        ch1_edit = true
        ch2_edit = true
      else
        ch1_edit = true
        ch2_edit = false
      end
      redraw()
      grid_redraw()
    end
    
  elseif n == 3 then
    if z == 1 then
      k3_reset_fired = false
      k3_timer = clock.run(function()
        clock.sleep(0.5)
        k3_reset_fired = true
        
        for ch = 1, 2 do
          if (ch == 1 and ch1_edit) or (ch == 2 and ch2_edit) then
            trigger_reset(ch)
          end
        end
        
        redraw()
        if screen_page >= 3 and screen_page <= 10 then grid_redraw() end
      end)
    elseif z == 0 then
      if k3_timer then clock.cancel(k3_timer) end
      if not k3_reset_fired then
        for ch = 1, 2 do
           if (ch == 1 and ch1_edit) or (ch == 2 and ch2_edit) then
             seq[ch].is_locked = not seq[ch].is_locked
             if seq[ch].is_locked then
               seq[ch].bounds_set = true
               if not seq[ch].has_locked then
                 seq[ch].play_sub_step = get_initial_sub_step(ch)
                 seq[ch].pendulum_dir = 1
                 seq[ch].has_locked = true
               end
             end
           end
        end
        redraw()
        grid_redraw()
      end
    end
  end
end

function cleanup()
  params:write(1)
end
