-- lib/grid.lua

-- Grid Key Blink for Tap Tempo & Loop Fill
function blink_tap()
  while true do
    clock.sync(1/4)
    blink_step = blink_step + 1
    
    local do_redraw = false
    
    if screen_page == 2 and params:get("clock_source") == 1 then
      do_redraw = true
    elseif screen_page == 10 then
      local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
      if not seq[display_ch].is_locked then do_redraw = true end
    end
    
    if do_redraw then grid_redraw() end
  end
end

-- Grid Keys Functionality
function g.key(x, y, z)
  -- Reset Button
  if x == 16 and y == 7 then
    grid_reset_btn_down = (z == 1)
    
    if z == 1 then
      for ch = 1, 2 do
        if (ch == 1 and ch1_edit) or (ch == 2 and ch2_edit) then
          trigger_reset(ch)
        end
      end
    end
    
    redraw()
    grid_redraw()
    return
  end
  
  if z == 1 then
    -- Page Navigation
    if (x == 15 or x == 16) and y <=5 then
      local selected_page = (y - 1) * 2 + (x - 14)
      screen_page = selected_page
      param_sel = 1
      show_param_name = false
      if param_timer then clock.cancel(param_timer) end
      redraw()
      grid_redraw()
    end
    
    if y == 7 then
      -- Play Pause
      if x == 15 then
        if ch1_edit then seq[1].playing = not seq[1].playing end
        if ch2_edit then seq[2].playing = not seq[2].playing end
        redraw()
        grid_redraw()
      end
    end
    
    if y == 8 then
      -- Channel Select
      if x == 15 then
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
      
      -- Loop Lock  
      elseif x == 16 then
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
    
    if screen_page == 1 and x <= 12 then
      local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
      
      if y == 1 then
        if ch1_edit then seq[1].root_idx = x; build_scale(1) end
        if ch2_edit then seq[2].root_idx = x; build_scale(2) end
        param_sel = 1
      end
      
      if y == 3 then
        if ch1_edit then seq[1].scale_idx = x; build_scale(1) end
        if ch2_edit then seq[2].scale_idx = x; build_scale(2) end
        param_sel = 2
      end
      
      local is_black = {false, true, false, true, false, false, true, false, true, false, true, false}
      local expected_y = is_black[x] and 7 or 8
      
      if y == expected_y then
        local current_state = seq[display_ch].notes[x]
        if ch1_edit then seq[1].notes[x] = not current_state end
        if ch2_edit then seq[2].notes[x] = not current_state end
        param_sel = x + 2
      end
      
      redraw()
      grid_redraw()
    end
    
    if screen_page == 2 and x <= 12 then
      local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
      
      if x == 1 then
        if params:get("clock_source") == 1 then 
          local current_tempo = params:get("clock_tempo")
          
          if y == 1 then
            local current_time = util.time()
            if last_tap > 0 then
              local delta = current_time - last_tap
              if delta < 2.5 then
                local bpm = math.floor(60 / delta + 0.5)
                params:set("clock_tempo", util.clamp(bpm, 30, 300))
              end
            end
            last_tap = current_time
          
          elseif y == 3 then params:set("clock_tempo", util.clamp(current_tempo + 1, 30, 300))
          elseif y == 4 then params:set("clock_tempo", util.clamp(current_tempo - 1, 30, 300))
          elseif y == 6 then params:set("clock_tempo", util.clamp(current_tempo + 10, 30, 300))
          elseif y == 7 then params:set("clock_tempo", util.clamp(current_tempo - 10, 30, 300))
          end
        end
      end
      
      if y == 1 and x >= 3 and x <= 10 then
        local idx = x - 2
        if ch1_edit then seq[1].div_idx = idx end
        if ch2_edit then seq[2].div_idx = idx end
        param_sel = 2
      end
      
      if y == 3 and x >= 3 and x <= 12 then
        local idx = x - 2
        if ch1_edit then seq[1].swing_idx = idx end
        if ch2_edit then seq[2].swing_idx = idx end
        param_sel = 3
      end
      
      if (y == 5 or y == 6) and x >= 3 and x <= 10 then
        local idx = (x - 2) + (y == 6 and 8 or 0)
        if ch1_edit then seq[1].sig_idx = idx end
        if ch2_edit then seq[2].sig_idx = idx end
        param_sel = 4
      end
      
      if y == 8 and x >= 3 and x <= 12 then
        local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
        local current_enforce = seq[display_ch].bar_enforce
        local current_h = math.floor((current_enforce / 100) * 10 + 0.5)
        local pressed_h = x - 2
        local new_enforce = (pressed_h == current_h) and 0 or (pressed_h * 10)
        
        if ch1_edit then seq[1].bar_enforce = new_enforce end
        if ch2_edit then seq[2].bar_enforce = new_enforce end
        param_sel = 5
      end
      
      redraw()
      grid_redraw()
    end
    
    if screen_page >= 3 and screen_page <= 9 then
      local config = {
        [3] = {key = "note_prob", cols = 12}, 
        [4] = {key = "rhythm_prob", cols = 12},
        [5] = {key = "chord_prob", cols = 12},
        [6] = {key = "voicing_prob", cols = 12}, 
        [7] = {key = "octave_prob", cols = 11},
        [8] = {key = "velocity_prob", cols = 10}, 
        [9] = {key = "ornament_prob", cols = 12}
      }
      
      local max_cols = config[screen_page].cols
      
      if x <= max_cols then
        local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
        local edit_key = config[screen_page].key
        
        local current_prob = seq[display_ch][edit_key][x]
        local current_h = math.floor((current_prob / 100) * 8 + 0.5)
        local pressed_h = 9 - y 
        local new_prob = (pressed_h == current_h) and 0 or math.floor((pressed_h / 8) * 100)
        
        if ch1_edit then seq[1][edit_key][x] = new_prob end
        if ch2_edit then seq[2][edit_key][x] = new_prob end
        
        param_sel = x 
        flash_param_name()
        redraw()
        grid_redraw()
      end
    end
    
    if screen_page == 10 then
      local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
      
      if x == 10 and y <= #order_options then
        if ch1_edit then seq[1].play_order = y end
        if ch2_edit then seq[2].play_order = y end
        param_sel = 3
        redraw()
        grid_redraw()
      elseif x == 12 and y <= 8 then
        local current_imp = seq[display_ch].improvise
        local current_h = math.floor((current_imp / 100) * 8 + 0.5)
        local pressed_h = 9 - y
        
        local new_imp = (pressed_h == current_h) and 0 or math.floor((pressed_h / 8) * 100)
        
        if ch1_edit then seq[1].improvise = new_imp end
        if ch2_edit then seq[2].improvise = new_imp end
        param_sel = 4
        redraw()
        grid_redraw()
      end
      
      if x <= 8 and y <= 8 then
        local step = (y - 1) * 8 + x
        
        if held_step == 0 then
          held_step = step
          param_sel = 1
        else
          for ch = 1, 2 do
            if (ch == 1 and ch1_edit) or (ch == 2 and ch2_edit) then
              seq[ch].start_step = held_step
              seq[ch].end_step = step
              seq[ch].bounds_set = (seq[ch].start_step ~= 1 or seq[ch].end_step ~= 1)
              
              local s = seq[ch].start_step
              local e = seq[ch].end_step
              local cur = seq[ch].is_locked and seq[ch].loop_head or seq[ch].current_step
              
              local is_outside = false
              if s <= e then is_outside = (cur < s or cur > e)
              else is_outside = (cur < s and cur > e) end
              
              if is_outside then
                local snap = s
                local o = seq[ch].play_order
                if o == 2 or o == 5 or o == 7 then snap = e end
                
                if seq[ch].is_locked then
                  seq[ch].loop_head = snap
                  seq[ch].play_sub_step = get_initial_sub_step(ch)
                  seq[ch].pendulum_dir = 1
                else
                  seq[ch].current_step = snap
                end
              end
            end
          end
          param_sel = 2
          held_step = -1
        end
        redraw()
        grid_redraw()
      end
    end
  end
  
  if z == 0 and screen_page == 10 and x <= 8 and y <=8 then
    local step = (y - 1) * 8 + x
    if step == held_step then
      for ch = 1, 2 do
        if (ch == 1 and ch1_edit) or (ch == 2 and ch2_edit) then
          seq[ch].start_step = step
          seq[ch].end_step = step
          seq[ch].bounds_set = (step ~= 1)
          
          local cur = seq[ch].is_locked and seq[ch].loop_head or seq[ch].current_step
          if cur ~= step then
            if seq[ch].is_locked then
              seq[ch].loop_head = step
              seq[ch].play_sub_step = get_initial_sub_step(ch)
              seq[ch].pendulum_dir = 1
            else
              seq[ch].current_step = step
            end
          end
        end
      end
      held_step = 0
      redraw()
      grid_redraw()
    elseif held_step == -1 then
      held_step = 0
    end
  end
end

-- Grid UI Redraw
function grid_redraw()
  g:all(0)
  
  for i = 1, 10 do
    local led_x = 15 + ((i - 1) % 2)
    local led_y = math.floor((i - 1) / 2) + 1
    g:led(led_x, led_y, i == screen_page and 15 or 4)
  end
  
  local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
  
  g:led(15, 7, seq[display_ch].playing and 15 or 4)
  g:led(16, 7, 0)
  
  local ch_lvl = 4
  if ch1_edit and not ch2_edit then ch_lvl = 6
  elseif not ch1_edit and ch2_edit then ch_lvl = 10
  elseif ch1_edit and ch2_edit then ch_lvl = 15 end
  
  g:led(15, 8, ch_lvl)
  g:led(16, 8, seq[display_ch].is_locked and 15 or 0)
  g:led(16, 7, grid_reset_btn_down and 15 or 4)
  
  if screen_page == 1 then
    local is_black = {false, true, false, true, false, false, true, false, true, false, true, false}
    for x = 1, 12 do
      g:led(x, 1, seq[display_ch].root_idx == x and 15 or 4)
      g:led(x, 3, seq[display_ch].scale_idx == x and 15 or 4)
      local y = is_black[x] and 7 or 8
      g:led(x, y, seq[display_ch].notes[x] and 10 or 2)
    end
    
  elseif screen_page == 2 then
    local is_int_clock = params:get("clock_source") == 1
    local tc_lvl = is_int_clock and 6 or 2
    local tap_lvl = 2
    if is_int_clock then
      local pulse = (blink_step % 4 == 1) and 15 or 5
      tap_lvl = pulse
    end
    g:led(1, 1, tap_lvl)
    
    g:led(1, 3, tc_lvl)
    g:led(1, 4, tc_lvl)
    g:led(1, 6, tc_lvl)
    g:led(1, 7, tc_lvl)
    
    for i = 1, #clock_options.div do
      g:led(i + 2, 1, seq[display_ch].div_idx == i and 15 or 4)
    end
    
    for i = 1, #clock_options.swing do
      g:led(i + 2, 3, seq[display_ch].swing_idx == i and 15 or 4)
    end
    
    for i = 1, #clock_options.sig do
      local sig_x = ((i - 1) % 8) + 3
      local sig_y = math.floor((i - 1) / 8) + 5
      g:led(sig_x, sig_y, seq[display_ch].sig_idx == i and 15 or 4)
    end
    
    local enforce_h = math.floor((seq[display_ch].bar_enforce / 100) * 10 + 0.5)
    
    for i = 1, 10 do
      local lvl = 2
      if enforce_h >= i then lvl = 6 end
      if enforce_h == i then lvl = 15 end
      g:led(i + 2, 8, lvl)
    end
    
  elseif screen_page >= 3 and screen_page <= 9 then
    local config = {
        [3] = {key = "note_prob", cols = 12, track = "active_note"}, 
        [4] = {key = "rhythm_prob", cols = 12, track = "active_rhythm"},
        [5] = {key = "chord_prob", cols = 12, track = "active_chord"},
        [6] = {key = "voicing_prob", cols = 12, track = "active_voicing"}, 
        [7] = {key = "octave_prob", cols = 11, track = "active_octave"},
        [8] = {key = "velocity_prob", cols = 10, track = "active_velocity"}, 
        [9] = {key = "ornament_prob", cols = 12, track = "active_ornaments"}
      }
    
    local max_cols = config[screen_page].cols
    local edit_key = config[screen_page].key
    local track_key = config[screen_page].track
    local playing_col = seq[display_ch][track_key]
    
    for x = 1, max_cols do
      local prob = seq[display_ch][edit_key][x]
      local is_active = true
      if screen_page == 3 then
        is_active = seq[display_ch].notes[x]
      end
      
      local h = math.floor((prob / 100) * 8 + 0.5)
      
      for y = 1, 8 do
        local inverted_y = 9 - y 
        if inverted_y <= h then
          local lvl = is_active and 6 or 2
          if type(playing_col) == "table" then
            for _, active_col in ipairs(playing_col) do
              if x == active_col then lvl = 15 end
            end
          elseif x == playing_col then 
            lvl = 15 
          end
          if screen_page == 4 and x == seq[display_ch].active_base_rhythm then
            lvl = 15
          elseif screen_page == 8 and x == seq[display_ch].active_base_velocity then
            lvl = 15
          end
          g:led(x, y, lvl)
        end
      end
    end
    
  elseif screen_page == 10 then
    local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
    
    local start_s = seq[display_ch].start_step
    local end_s = seq[display_ch].end_step
    local cur_s = seq[display_ch].current_step
    
    if held_step > 0 then
      start_s = held_step
      end_s = held_step
    end

    for i = 1, #order_options do
      if seq[display_ch].is_locked then
        g:led(10, i, (seq[display_ch].play_order == i) and 15 or 4)
      else
        if i == 1 then
          local pulse = (blink_step % 2 == 0) and 10 or 2
          g:led(10, i, pulse)
        else
          g:led(10, i, 2)
        end
      end
    end
    
    local current_imp = seq[display_ch].improvise
    local imp_h = math.floor((current_imp / 100) * 8 + 0.5)
    
    for y = 1, 8 do
      local inverted_y = 9 - y
      if inverted_y <= imp_h and current_imp > 0 then
        g:led(12, y, seq[display_ch].is_improvising and 15 or 6)
      else
        g:led(12, y, 0)
      end
    end
    
    for y = 1, 8 do
      for x = 1, 8 do
        local step = (y - 1) * 8 + x
        local is_active = false
        
        if start_s <= end_s then
          is_active = (step >= start_s and step <= end_s)
        else
          is_active = (step >= start_s or step <= end_s)
        end
        
        local mem = seq[display_ch].loop_buffer[step]
        local is_empty = (not mem or not mem.base_idx)
        
        local lvl = 0
        if step == cur_s then
          lvl = 15
        elseif is_active then
          if is_empty then
            lvl = 1 
          else
            lvl = 6 
          end
        else
          if is_empty then
            lvl = 0 
          else
            lvl = 2 
          end
        end
        
        g:led(x, y, lvl)
      end
    end
  end
  
  g:refresh()
end