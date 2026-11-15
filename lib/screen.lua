-- lib/screen.lua

icons = {
  -- Overview Icons
  play = {
    {0,1,0,0,0,0}, {0,1,1,0,0,0}, {0,1,1,1,0,0}, {0,1,1,0,0,0}, {0,1,0,0,0,0}
  },
  pause = {
    {0,1,0,1,0,0}, {0,1,0,1,0,0}, {0,1,0,1,0,0}, {0,1,0,1,0,0}, {0,1,0,1,0,0}
  },
  recording = {
    {0,0,1,1,1,0}, {0,1,1,1,1,1}, {0,1,1,1,1,1}, {0,1,1,1,1,1}, {0,0,1,1,1,0}
  },
  looping = {
    {0,0,1,1,1,0}, {0,0,0,0,0,1}, {0,1,0,0,0,1}, {0,1,0,0,0,0}, {0,0,1,1,1,0}
  },
  barenforce = {
    {0,0,0,1,0,1}, {0,1,0,1,0,1}, {0,0,0,1,0,1}, {0,1,0,1,0,1}, {0,0,0,1,0,1}
  },
  -- Note Icons
  sharp = {
    {0,1,0,1,0,0}, {1,1,1,1,1,0}, {0,1,0,1,0,0}, {1,1,1,1,1,0}, {0,1,0,1,0,0}
  },
  flat = {
    {0,1,0,0,0}, {0,1,0,0,0}, {0,1,1,0,0}, {0,1,0,1,0}, {0,1,1,0,0}
  },
  -- Rhythm Icons
  thirtysecond = {
    {0,0,0,1,1,1}, {0,0,0,1,0,0}, {0,0,1,1,0,1}, {0,1,1,1,0,0}, {0,0,1,0,0,1}
  },
  sixteenth = {
    {0,0,0,1,1,1}, {0,0,0,1,0,0}, {0,0,1,1,0,1}, {0,1,1,1,0,0}, {0,0,1,0,0,0}
  },
  eigth = {
    {0,0,0,1,1,1}, {0,0,0,1,0,0}, {0,0,1,1,0,0}, {0,1,1,1,0,0}, {0,0,1,0,0,0}
  },
  quarter = {
    {0,0,0,1,0,0}, {0,0,0,1,0,0}, {0,0,1,1,0,0}, {0,1,1,1,0,0}, {0,0,1,0,0,0}
  },
  half = {
    {0,0,0,1,0,0}, {0,0,0,1,0,0}, {0,0,1,1,0,0}, {0,1,0,1,0,0}, {0,0,1,0,0,0}
  },
  whole = {
    {0,0,0,0,0,0}, {0,0,0,0,0,0}, {0,0,1,1,0,0}, {0,1,0,0,1,0}, {0,0,1,1,0,0}
  },
  rest = {
    {0,0,0,1,0,0}, {0,0,0,1,0,0}, {0,0,1,0,0,0}, {0,0,0,1,0,0}, {0,0,1,0,0,0}
  },
  rest_32 = {
    {0,0,0,1,0,1}, {0,0,0,0,1,1}, {0,0,1,0,0,1}, {0,0,0,1,1,0}, {0,1,0,0,1,0}
  },
  rest_16 = {
    {0,0,1,0,1,0}, {0,0,0,1,1,0}, {0,1,0,0,1,0}, {0,0,1,1,0,0}, {0,0,0,1,0,0}
  },
  rest_8 = {
    {0,1,0,1,0,0}, {0,0,1,1,0,0}, {0,0,0,1,0,0}, {0,0,1,0,0,0}, {0,0,1,0,0,0}
  },
  rest_4 = {
    {0,0,0,1,0,0}, {0,0,0,1,0,0}, {0,0,1,0,0,0}, {0,0,0,1,0,0}, {0,0,1,0,0,0}
  },
  rest_2 = {
    {0,0,0,0,0,0}, {0,0,0,0,0,0}, {0,0,1,1,1,0}, {0,1,1,1,1,1}, {0,0,0,0,0,0}
  },
  rest_1 = {
    {0,1,1,1,1,1}, {0,0,1,1,1,0}, {0,0,0,0,0,0}, {0,0,0,0,0,0}, {0,0,0,0,0,0}
  },
  tie = {
    {0,0,0,0,0,0}, {0,0,1,1,0,0}, {0,1,0,0,1,0}, {0,0,0,0,0,0}, {0,0,0,0,0,0}
  },
  dotted = {
    {0,0,0,0,0,0}, {0,0,1,1,0,0}, {0,0,1,1,0,0}, {0,0,0,0,0,0}, {0,0,0,0,0,0}
  },
  triplet = {
    {0,0,1,0,0,0}, {0,1,0,1,0,0}, {0,0,0,0,0,0}, {0,1,1,1,1,0}, {0,1,0,0,1,0}
  },
  rush = {
    {0,0,0,0,1,0}, {0,0,1,0,1,0}, {0,1,0,0,1,0}, {0,0,1,0,1,0}, {0,0,0,0,1,0}
  },
  drag = {
    {0,1,0,0,0,0}, {0,1,0,1,0,0}, {0,1,0,0,1,0}, {0,1,0,1,0,0}, {0,1,0,0,0,0}
  },
  -- Chord Icons
  global = {
    {0,1,1,1,1,0}, {0,0,0,0,0,0}, {0,1,1,1,1,0}, {0,0,0,0,0,0}, {0,1,1,1,1,0}
  },
  minor = {
    {0,0,0,0,0,0}, {0,1,1,0,1,0}, {0,1,0,1,0,1}, {0,1,0,1,0,1}, {0,1,0,1,0,1}
  },
  dominant = {
    {0,1,1,1,0,0}, {0,0,0,1,0,0}, {0,0,1,0,0,0}, {0,0,1,0,0,0}, {0,0,0,0,0,0}
  },
  dominantflatfive = {
    {1,0,0,1,1,0}, {1,1,0,1,0,0}, {1,1,0,0,1,0}, {0,0,0,1,0,0}, {0,0,0,0,0,0}
  },
  halfdim = {
    {0,0,1,1,0,0}, {0,1,1,0,1,0}, {0,1,0,1,1,0}, {0,0,1,1,0,0}, {0,0,0,0,0,0}
  },
  fulldim = {
    {0,0,1,1,0,0}, {0,1,0,0,1,0}, {0,1,0,0,1,0}, {0,0,1,1,0,0}, {0,0,0,0,0,0}
  },
  majminor = {
    {0,1,1,0,1,0}, {0,1,0,1,0,1}, {0,1,0,1,0,1}, {0,0,0,0,0,0}, {0,1,1,1,1,1},
  },
  augmented = {
    {0,0,1,0,0,0}, {0,1,1,1,0,0}, {0,0,1,0,0,0}, {0,0,0,0,0,0}, {0,0,0,0,0,0}
  },
  majaugmented = {
    {0,0,1,0,0,0}, {0,1,1,1,0,0}, {0,0,1,0,0,0}, {0,0,0,0,0,0}, {0,1,1,1,0,0}
  },
  -- Voicing Icons
  firstinversion = {
    {0,0,0,1,0,0}, {0,0,0,1,1,0}, {0,0,0,1,0,0}, {0,0,0,1,0,0}, {0,1,0,1,0,0}
  },
  secondinversion = {
    {0,0,0,1,0,0}, {0,0,0,1,1,0}, {0,1,0,1,0,0}, {0,0,0,1,0,0}, {0,1,0,1,0,0}
  },
  thirdinversion = {
    {0,1,0,1,0,0}, {0,0,0,1,1,0}, {0,1,0,1,0,0}, {0,0,0,1,0,0}, {0,1,0,1,0,0}
  },
  droptwo = {
    {0,0,1,0,1,0}, {0,0,1,0,0,1}, {0,0,1,0,0,0}, {0,1,1,0,0,0}, {0,0,1,0,0,0}
  },
  dropfour = {
    {0,0,1,0,1,0}, {0,0,1,0,0,1}, {0,0,1,0,0,0}, {0,1,1,0,1,0}, {0,0,1,0,0,1}
  },
  noroot = {
    {0,0,0,1,1,0}, {0,0,0,0,1,0}, {1,1,0,0,1,0}, {0,0,0,0,1,0}, {0,0,0,0,1,0}
  },
  shell = {
    {0,0,0,1,1,1}, {0,0,0,1,0,0}, {1,1,0,1,1,1}, {0,0,0,0,0,1}, {0,0,0,1,1,0}
  },
  sustwo = {
    {0,0,0,0,1,0}, {0,0,1,0,0,1}, {0,1,0,0,1,0}, {0,0,1,0,1,1}, {0,1,0,0,0,0}
  },
  susfour = {
    {0,0,0,0,1,0}, {0,0,1,0,1,1}, {0,1,0,0,1,1}, {0,0,1,0,0,1}, {0,1,0,0,0,0}
  },
  -- Octave Icons
  negone = {
    {0,0,0,1,1,0}, {0,0,0,0,1,0}, {1,1,1,0,1,0}, {0,0,0,0,1,0}, {0,0,0,0,1,0}
  },
  posone = {
    {0,0,0,1,1,0}, {0,1,0,0,1,0}, {1,1,1,0,1,0}, {0,1,0,0,1,0}, {0,0,0,0,1,0}
  },
  octdblsub = {
    {0,0,0,0,0,0}, {0,0,1,1,0,0}, {0,0,0,0,0,0}, {0,0,0,0,0,0}, {0,0,1,1,0,0}
  },
  octdblup = {
    {0,0,1,1,0,0}, {0,0,0,0,0,0}, {0,0,0,0,0,0}, {0,0,1,1,0,0}, {0,0,0,0,0,0}
  },
  -- Velocity Icons
  ppp = {
    {0,0,1,0,0,1}, {0,1,0,1,0,0}, {0,1,0,1,0,1}, {0,1,1,0,0,0}, {0,1,0,0,0,1}
  },
  pp = {
    {0,0,1,0,0,1}, {0,1,0,1,0,0}, {0,1,0,1,0,1}, {0,1,1,0,0,0}, {0,1,0,0,0,0}
  },
  p = {
    {0,0,1,0,0,1}, {0,1,0,1,0,0}, {0,1,0,1,0,0}, {0,1,1,0,0,0}, {0,1,0,0,0,0}
  },
  mp = {
    {0,0,0,0,0,0}, {0,0,0,0,0,0}, {0,1,1,0,1,0}, {0,1,0,1,0,1}, {0,1,0,1,0,1}
  },
  mf = {
    {0,0,0,0,0,0}, {0,1,1,0,1,0}, {0,1,0,1,0,1}, {0,1,0,1,0,1}, {0,1,0,1,0,1}
  },
  f = {
    {0,0,0,1,0,1}, {0,0,1,0,0,0}, {0,0,1,1,0,0}, {0,0,1,0,0,0}, {0,1,0,0,0,0}
  },
  ff = {
    {0,0,0,1,0,1}, {0,0,1,0,0,0}, {0,0,1,1,0,1}, {0,0,1,0,0,0}, {0,1,0,0,0,0}
  },
  fff = {
    {0,0,0,1,0,1}, {0,0,1,0,0,0}, {0,0,1,1,0,1}, {0,0,1,0,0,0}, {0,1,0,0,0,1}
  },
  velup = {
    {0,0,0,0,0,0}, {0,0,0,1,0,0}, {0,0,1,1,1,0}, {0,0,0,1,0,0}, {0,0,0,0,0,0}
  },
  veldown = {
    {0,0,0,0,0,0}, {0,0,0,0,0,0}, {0,0,1,1,1,0}, {0,0,0,0,0,0}, {0,0,0,0,0,0}
  },
  -- Ornament Icons
  sustain = {
    {0,0,1,0,1,0}, {0,0,0,1,0,0}, {0,0,1,0,1,0}, {0,1,0,0,0,1}, {0,1,1,1,1,1}
  },
  tremolotwo = {
    {0,0,0,0,0,0}, {0,0,0,1,1,0}, {0,1,1,0,0,0}, {0,0,0,0,0,0}, {0,0,0,0,0,0}
  },
  tremolothree = {
    {0,0,0,1,1,0}, {0,1,1,0,0,0}, {0,0,0,1,1,0}, {0,1,1,0,0,0}, {0,0,0,0,0,0}
  },
  trill = {
    {0,0,0,0,0,0}, {0,1,0,0,0,0}, {0,1,1,0,1,1}, {0,1,0,0,1,0}, {0,1,1,0,1,0}
  },
  graceabove = {
    {0,0,0,1,0,1}, {0,0,1,1,1,0}, {0,1,0,1,0,0}, {0,0,1,1,0,0}, {0,0,1,1,0,0}
  },
  gracebelow = {
    {0,0,1,1,0,0}, {0,0,1,1,0,0}, {1,0,1,0,0,0}, {0,1,1,1,0,0}, {0,0,1,0,1,0}
  },
  ghostnote = {
    {0,0,0,1,0,0}, {0,0,0,1,0,0}, {0,1,0,1,0,0}, {0,0,1,0,0,0}, {0,1,0,1,0,0}
  },
  mordent = {
    {0,0,0,0,0,0}, {0,0,1,0,1,0}, {0,1,1,1,1,0}, {0,1,0,1,0,0}, {0,0,0,0,0,0}
  },
  scalerun = {
    {0,0,0,0,0,0}, {0,0,0,0,1,0}, {0,0,0,1,0,1}, {0,0,1,0,0,0}, {0,1,0,0,0,0}
  },
  arpup = {
    {0,0,0,1,0,0}, {0,0,1,1,1,0}, {0,0,0,1,0,0}, {0,0,1,0,0,0}, {0,0,0,1,0,0}
  },
  arpdown = {
    {0,0,0,1,0,0}, {0,0,0,0,1,0}, {0,0,0,1,0,0}, {0,0,1,1,1,0}, {0,0,0,1,0,0}
  },
  repeater = {
    {0,0,0,0,1,0}, {0,0,1,0,1,0}, {0,0,0,0,1,0}, {0,0,1,0,1,0}, {0,0,0,0,1,0}
  }
}

rhythm_icons_list = {
  icons.thirtysecond, icons.sixteenth, icons.eigth, icons.quarter, icons.half, icons.whole,
  icons.dotted, icons.triplet, icons.rest, icons.tie, icons.rush, icons.drag
}

-- Draw Icons
function draw_icon(icon_map, x, y, level)
  screen.level(level)
  for row = 1, #icon_map do
    for col = 1, #icon_map[row] do
      if icon_map[row][col] == 1 then
        screen.rect(x + col - 1, y + row - 1, 1, 1)
      end
    end
  end
  screen.fill()
end

-- Draw Labels
function draw_label(item, x, base_y, level)
  if type(item) == "string" then
    screen.level(level)
    screen.move(x, base_y)
    screen.text(item)
  elseif type(item) == "table" then
    draw_icon(item, x - 1, base_y - 5, level)
  end
end

-- Norns Screen Redraw
function redraw()
  screen.clear()
  screen.aa(0)
  
  -- Page Titles
  screen.level(10)
  screen.move(1, 8)
  
  if show_param_name and screen_page >= 3 and screen_page <= 9 and param_names[screen_page] then
    screen.text(param_names[screen_page][param_sel] or "")
  else
    screen.text(string.upper(pages[screen_page]))
  end
  
  screen.level(10)
  screen.move(0, 11)
  screen.line(83, 11)
  screen.stroke()
  
  for i = 1, 10 do
    if i == screen_page then
      screen.level(10)
    else
      screen.level(2)
    end
    screen.rect(86, 3 + (i - 1) * 6, 1, 4)
    screen.fill()
  end
  
  -- Key/Scale
  if screen_page == 1 then
    local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
    
    local labels = {"Key:", "Scale:"}
    local vals = {
      roots[seq[display_ch].root_idx],
      scales[seq[display_ch].scale_idx]
    }
    
    for i = 1, 2 do
      local y = 10 + (i * 10)
      if i == param_sel then screen.level(15) else screen.level(3) end
      screen.move(1, y)
      screen.text(labels[i])
      screen.move(82, y)
      screen.text_right(vals[i])
    end
    
    local is_black = {false, true, false, true, false, false, true, false, true, false, true, false}
    local key_labels = {"C", icons.sharp, "D", icons.sharp, "E", "F", icons.sharp, "G", icons.sharp, "A", icons.sharp, "B"}
    
    for i = 1, 12 do
      local x = 1 + (i - 1) * 7
      local y = is_black[i] and 42 or 46
      
      local is_active = seq[display_ch].notes[i]
      
      if is_active then
        screen.level(10)
        screen.rect(x, y, 4, 8)
        screen.fill()
      else
        screen.level(3) 
        screen.rect(x, y, 4, 8)
        screen.fill()
        screen.level(0)
        screen.rect(x + 1, y + 1, 2, 6)
        screen.fill()
      end
      
      if param_sel == (i + 2) then
        screen.level(15)
        screen.move(x - 1, 57)
        screen.line(x + 5, 57)
        screen.stroke()
      end
      
      local label_lvl = is_active and 15 or 3
      draw_label(key_labels[i], x, 64, label_lvl)
    end
  
  -- Clock/Bar
  elseif screen_page == 2 then
    local src_idx = params:get("clock_source")
    local src_names = {"INT", "MIDI", "LINK", "CROW"}
    local labels = {"Tempo:", "Clock Division:", "Swing:", "Time Signature:", "Bar Enforce:"}
    local current_src = src_names[src_idx]
    
    screen.level(10)
    screen.move(82, 8)
    screen.text_right(current_src)
    
    local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
    
    local bpm_val = params:get("clock_tempo")
    local bpm_str = bpm_val
    
    local vals = {
      bpm_str,
      "/" .. clock_options.div[seq[display_ch].div_idx],
      clock_options.swing[seq[display_ch].swing_idx] .. "%",
      clock_options.sig[seq[display_ch].sig_idx],
      seq[display_ch].bar_enforce .. "%"
    }
    
    for i = 1, 5 do
      local y = 10 + (i * 10)

      if i == param_sel then
        screen.level(15)
      else
        screen.level(3)
      end
      
      screen.move(1, y)
      screen.text(labels[i])
      
      screen.move(82, y)
      screen.text_right(vals[i])
    end
  
  -- Probability Pages
  elseif screen_page >= 3 and screen_page <= 9 then
    local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
    
    local page_config = {
      [3] = {key = "note_prob", cols = 12, track = "active_note", labels = {"C", icons.sharp, "D", icons.sharp, "E", "F", icons.sharp, "G", icons.sharp, "A", icons.sharp, "B"}},
      [4] = {key = "rhythm_prob", cols = 12, track = "active_rhythm", labels = {icons.thirtysecond, icons.sixteenth, icons.eigth, icons.quarter, icons.half, icons.whole, icons.dotted, icons.triplet, icons.rest, icons.tie, icons.rush, icons.drag}},
      [5] = {key = "chord_prob", cols = 12, track = "active_chord", labels = {icons.global, "3", "7", "M", icons.minor, icons.dominant, icons.dominantflatfive, icons.halfdim, icons.fulldim, icons.majminor, icons.augmented, icons.majaugmented}},
      [6] = {key = "voicing_prob", cols = 12, track = "active_voicing", labels = {icons.firstinversion, icons.secondinversion, icons.thirdinversion, icons.droptwo, icons.dropfour, "6", "8", "9", icons.noroot, icons.shell, icons.sustwo, icons.susfour}},
      [7] = {key = "octave_prob", cols = 11, track = "active_octave", labels = {"4", "3", "2", icons.negone, "0", icons.posone, "2", "3", "4", icons.octdblsub, icons.octdblup}},
      [8] = {key = "velocity_prob", cols = 10, track = "active_velocity", labels = {icons.ppp, icons.pp, icons.p, icons.mp, icons.mf, icons.f, icons.ff, icons.fff, icons.velup, icons.veldown}},
      [9] = {key = "ornament_prob", cols = 12, track = "active_ornaments", labels = {icons.sustain, icons.tremolotwo, icons.tremolothree, icons.trill, icons.graceabove, icons.gracebelow, icons.ghostnote, icons.mordent, icons.scalerun, icons.arpup, icons.arpdown, icons.repeater}}
    }
    
    local cfg = page_config[screen_page]
    local current_val = seq[display_ch][cfg.key][param_sel]
    
    local display_str = current_val
    -- Removed the (screen_page == 8 and param_sel >= 9) override so it pools correctly
    local is_absolute = (screen_page == 5 and param_sel == 1) or 
                        (screen_page == 6 and (param_sel >= 6 and param_sel <= 10)) or
                        (screen_page == 9 and (param_sel == 1 or param_sel == 12))
    
    if is_absolute then
      display_str = current_val .. "%"
    else
      local pool_sum = 0
      
      -- Note
      if screen_page == 3 then
        for i = 1, 12 do if seq[display_ch].notes[i] then pool_sum = pool_sum + seq[display_ch].note_prob[i] end end
      
      -- Rhythm
      elseif screen_page == 4 then
        if param_sel <= 6 then
          for i = 1, 6 do pool_sum = pool_sum + seq[display_ch].rhythm_prob[i] end
        elseif param_sel >= 7 and param_sel <= 8 then
          for i = 7, 8 do pool_sum = pool_sum + seq[display_ch].rhythm_prob[i] end
          pool_sum = math.max(100, pool_sum)
        elseif param_sel >= 9 and param_sel <= 10 then
          for i = 9, 10 do pool_sum = pool_sum + seq[display_ch].rhythm_prob[i] end
          pool_sum = math.max(100, pool_sum)
        elseif param_sel >= 11 and param_sel <= 12 then
          for i = 11, 12 do pool_sum = pool_sum + seq[display_ch].rhythm_prob[i] end
          pool_sum = math.max(100, pool_sum)
        end
      
      -- Chord
      elseif screen_page == 5 then
        if param_sel >= 2 and param_sel <= 3 then
          for i = 2, 3 do pool_sum = pool_sum + seq[display_ch].chord_prob[i] end
        elseif param_sel >= 4 and param_sel <= 12 then
          for i = 4, 12 do pool_sum = pool_sum + seq[display_ch].chord_prob[i] end
        end
      
      -- Voicing
      elseif screen_page == 6 then
        if param_sel >= 1 and param_sel <= 3 then
          for i = 1, 3 do pool_sum = pool_sum + seq[display_ch].voicing_prob[i] end
          pool_sum = math.max(100, pool_sum)
        elseif param_sel >= 4 and param_sel <= 5 then
          for i = 4, 5 do pool_sum = pool_sum + seq[display_ch].voicing_prob[i] end
          pool_sum = math.max(100, pool_sum)
        elseif param_sel >= 11 and param_sel <= 12 then
          for i = 11, 12 do pool_sum = pool_sum + seq[display_ch].voicing_prob[i] end
          pool_sum = math.max(100, pool_sum)
        end
      
      -- Octave
      elseif screen_page == 7 then
        if param_sel <= 9 then
          for i = 1, 9 do pool_sum = pool_sum + seq[display_ch].octave_prob[i] end
        else
          for i = 10, 11 do pool_sum = pool_sum + seq[display_ch].octave_prob[i] end
          pool_sum = math.max(100, pool_sum)
        end
      
      -- Velocity (Added pooling for columns 9 and 10)
      elseif screen_page == 8 then
        if param_sel <= 8 then
          for i = 1, 8 do pool_sum = pool_sum + seq[display_ch].velocity_prob[i] end
        elseif param_sel >= 9 and param_sel <= 10 then
          for i = 9, 10 do pool_sum = pool_sum + seq[display_ch].velocity_prob[i] end
          pool_sum = math.max(100, pool_sum)
        end
      
      -- Ornament  
      elseif screen_page == 9 then
        if param_sel >= 2 and param_sel <= 4 then
          for i = 2, 4 do pool_sum = pool_sum + seq[display_ch].ornament_prob[i] end
          pool_sum = math.max(100, pool_sum)
        elseif param_sel >= 5 and param_sel <= 9 then
          for i = 5, 9 do pool_sum = pool_sum + seq[display_ch].ornament_prob[i] end
          pool_sum = math.max(100, pool_sum)
        elseif param_sel >= 10 and param_sel <= 11 then
          for i = 10, 11 do pool_sum = pool_sum + seq[display_ch].ornament_prob[i] end
          pool_sum = math.max(100, pool_sum)
        end
      end
      
      -- Show % for Probability
      local actual_pct = pool_sum > 0 and math.floor((current_val / pool_sum) * 100 + 0.5) or 0
      display_str =  actual_pct .. "%"
    end
    
    screen.level(10)
    screen.move(82, 8)
    screen.text_right(display_str)
    
    -- Highlight Current Playing Column
    local playing_col = seq[display_ch][cfg.track]
    
    for i = 1, cfg.cols do
      local x = 1 + (i - 1) * 7
      local prob = seq[display_ch][cfg.key][i]
      local is_note_active = (screen_page == 3) and seq[display_ch].notes[i] or false
      
      local is_playing_col = false
      if seq[display_ch].playing then
        if type(playing_col) == "table" then
          for _, active_col in ipairs(playing_col) do
            if i == active_col then is_playing_col = true end
          end
        elseif i == playing_col then
          is_playing_col = true
        end
        
        if screen_page == 4 and seq[display_ch].active_base_rhythm == i then is_playing_col = true
        elseif screen_page == 8 and seq[display_ch].active_base_velocity == i then is_playing_col = true
        end
      end
      
      local max_h = 40
      local h = math.floor((prob / 100) * max_h)
      local y_bottom = 54
      local y_top = y_bottom - h
      
      if h > 0 then
        if screen_page ~= 3 or is_note_active then
          screen.level(is_playing_col and 15 or 7)
          screen.rect(x, y_top, 4, h)
          screen.fill()
        else 
          screen.level(is_playing_col and 15 or 3)
          screen.rect(x, y_top, 4, h)
          screen.fill()
          if h > 2 then
            screen.level(0)
            screen.rect(x + 1, y_top + 1, 2, h - 2)
            screen.fill()
          end
        end
      end
      
      if param_sel == i then
        screen.level(15)
        screen.move(x - 1, 57)
        screen.line(x + 5, 57)
        screen.stroke()
      end
      
      local label_lvl = 3
      if is_playing_col then
        label_lvl = 15
      elseif screen_page == 3 then
        label_lvl = is_note_active and 8 or 3
      else
        label_lvl = prob > 0 and 8 or 3
      end
      
      draw_label(cfg.labels[i], x, 64, label_lvl)
    end
  
  -- Loop  
  elseif screen_page == 10 then
    local display_ch = (not ch1_edit and ch2_edit) and 2 or 1
    
    local loop_status = seq[display_ch].is_locked and "Locked" or (seq[display_ch].playing and "Recording" or "Armed")
    screen.level(10)
    screen.move(82, 8)
    screen.text_right(loop_status)
    
    screen.level(param_sel == 1 and 15 or 4)
    screen.move(1, 20)
    screen.text("Start: " .. seq[display_ch].start_step)
    
    screen.level(param_sel == 2 and 15 or 4)
    screen.move(53, 20)
    screen.text("End:")
    screen.move(82, 20)
    screen.text_right(seq[display_ch].end_step)
    
    screen.level(param_sel == 3 and 15 or 4)
    screen.move(1, 30)
    screen.text("Order:")
    screen.move(82, 30)
    screen.text_right(order_options[seq[display_ch].play_order])
    
    screen.level(param_sel == 4 and 15 or 4)
    screen.move(1, 40)
    screen.text("Improvise:")
    screen.move(82, 40)
    screen.text_right(seq[display_ch].improvise .. "%")
    
    for i = 1, 64 do
      local idx = i - 1
      local col = idx % 16
      local row = math.floor(idx / 16)
      
      local gap_bonus = math.floor(col / 4)
      local x = 1 + (col * 5) + gap_bonus
      local y = 46 + (row * 5)
      
      local start_s = seq[display_ch].start_step
      local end_s = seq[display_ch].end_step
      local cur_s = seq[display_ch].current_step
      
      local is_active = false
      if start_s <= end_s then
        is_active = (i >= start_s and i <= end_s)
      else
        is_active = (i >= start_s or i <= end_s)
      end
      local is_playing = (i == cur_s)
      
      local mem = seq[display_ch].loop_buffer[i]
      local is_empty = (not mem or not mem.base_idx)
      
      if is_playing then
        screen.level(15)
        screen.rect(x, y, 3, 3)
        screen.fill()
      elseif is_active then
        if is_empty then
          screen.level(2) 
          screen.rect(x, y, 3, 3)
          screen.fill()
          
          screen.level(0)
          screen.rect(x + 1, y + 1, 1, 1)
          screen.fill()
        else
          screen.level(8) 
          screen.rect(x, y, 3, 3)
          screen.fill()
        end
      else
        if is_empty then
          screen.level(1) 
          screen.rect(x, y, 3, 3)
          screen.fill()
          
          screen.level(0)
          screen.rect(x + 1, y + 1, 2, 2)
          screen.fill()
        else
          screen.level(2) 
          screen.rect(x, y, 3, 3)
          screen.fill()
        end
      end
    end
  end
  
  -- Ch 1 & Ch 2 Overview
  for ch = 1, 2 do
    local is_editing = (ch == 1 and ch1_edit) or (ch == 2 and ch2_edit)
    local y_offset = (ch - 1) * 33
    
    screen.level(is_editing and 10 or 3)
    screen.rect(91, 1 + y_offset, 37, 30)
    screen.stroke()
    
    screen.level(3)
    screen.rect(91, 1 + y_offset, 36, 9)
    screen.fill()
    
    screen.level(is_editing and 10 or 3)
    screen.move(91, 11 + y_offset)
    screen.line(127, 11 + y_offset)
    screen.stroke()
    
    local header_lvl = is_editing and 10 or 0
    screen.level(header_lvl)
    screen.move(93, 8 + y_offset)
    screen.text("Ch" .. ch)
    
    local play_icon = seq[ch].playing and icons.play or icons.pause
    draw_icon(play_icon, 112, 3 + y_offset, header_lvl)
    
    if seq[ch].is_locked then
      draw_icon(icons.looping, 119, 3 + y_offset, header_lvl)
    elseif seq[ch].playing then
      draw_icon(icons.recording, 119, 3 + y_offset, header_lvl)
    end
    
    screen.level(is_editing and 15 or 3)
    screen.move(93, 19 + y_offset)
    
    local display_note = seq[ch].active_note_str or "---"
    screen.text(display_note)
    
    local item_lvl = is_editing and 15 or 3
    local active_r = seq[ch].active_rhythm
    
    local base_r = seq[ch].active_base_rhythm
    base_r = (base_r > 0 and base_r <= 6) and base_r or 4
    
    local r_icon 
    if seq[ch].is_resting then
      local rest_icons = {icons.rest_32, icons.rest_16, icons.rest_8, icons.rest_4, icons.rest_2, icons.rest_1}
      r_icon = rest_icons[base_r] or icons.rest_4
    else
      r_icon = rhythm_icons_list[base_r]
    end
    
    local mod_idx = 0
    if type(active_r) == "table" then
      for _, val in ipairs(active_r) do
        if val == 7 or val == 8 then 
          mod_idx = val 
          break 
        end
      end
    elseif type(active_r) == "number" then
      if active_r == 7 or active_r == 8 then mod_idx = active_r end
    end
    
    local cursor_x = 92
    
    if seq[ch].is_tied_ui then
      draw_icon(icons.tie, cursor_x, 23 + y_offset, item_lvl)
      cursor_x = cursor_x + 6 
    end
    
    draw_icon(r_icon, cursor_x, 23 + y_offset, item_lvl)
    cursor_x = cursor_x + 6
    
    if mod_idx > 0 then
      draw_icon(rhythm_icons_list[mod_idx], cursor_x, 23 + y_offset, item_lvl)
      cursor_x = cursor_x + 6
    end
    
    local orn_x = cursor_x + 1
    local ornament_icons = {icons.sustain, icons.tremolotwo, icons.tremolothree, icons.trill, icons.graceabove, icons.gracebelow, icons.ghostnote, icons.mordent, icons.scalerun, icons.arpup, icons.arpdown, icons.repeater}
    
    for _, slot_idx in ipairs(seq[ch].active_ornaments or {}) do
      if slot_idx >= 2 and slot_idx <= 9 then 
        draw_icon(ornament_icons[slot_idx], orn_x, 23 + y_offset, item_lvl)
        orn_x = orn_x + 7 
      end
    end
    
    if seq[ch].bar_enforced_this_bar then
      draw_icon(icons.barenforce, 119, 23 + y_offset, item_lvl)
    end
  end
  
  screen.update()
end