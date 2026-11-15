-- lib/engine.lua

-- Strong Beat for Time Signatures
local function is_strong_beat(num, den, bar_pos)
  if bar_pos < 0.001 then return true end
  
  if den == 8 and (num == 6 or num == 9 or num == 12) then
    local remainder = bar_pos % 1.5
    if remainder < 0.001 or remainder > 1.499 then return true end
  end
  
  if num == 4 and (den == 4 or den == 2) then
    local target = 2.0 * (4 / den)
    if math.abs(bar_pos - target) < 0.001 then return true end
  end
  
  if num == 5 and den == 4 and math.abs(bar_pos - 3.0) < 0.001 then return true end
  if num == 7 and den == 4 and math.abs(bar_pos - 4.0) < 0.001 then return true end
  
  return false
end

-- Build Scale
function build_scale(ch)
  for i = 1, 12 do
    seq[ch].notes[i] = false
    seq[ch].note_prob[i] = 0
  end
  
  local root_midi = 60 + (seq[ch].root_idx - 1)
  local scale_name = mu_scales[seq[ch].scale_idx]
  
  local generated_notes = mu.generate_scale(root_midi, scale_name, 1)
  
  for i = 1, #generated_notes do
    local note_midi = generated_notes[i]
    local note_idx = (generated_notes[i] % 12) + 1
    local interval = (note_midi - root_midi) % 12
    
    seq[ch].notes[note_idx] = true
    seq[ch].note_prob[note_idx] = interval_weights[interval]
  end
end

-- Get Weighted Choice
function get_weighted_choice(weights, active_mask)
  local total = 0
  local pool = {}
  
  for i = 1, #weights do
    if (active_mask == nil or active_mask[i] == true) and weights[i] > 0 then
      total = total + weights[i]
      table.insert(pool, {idx = i, w = weights[i]})
    end
  end
  
  if total == 0 then return nil end
  
  local draw = math.random(1, total)
  local sum = 0
  
  for i = 1, # pool do
    sum = sum + pool[i].w
    if draw <= sum then
      return pool[i].idx
    end
  end
end

-- Update Queue
function update_queue()
  if #pend_hits > 0 then
    table.sort(pend_hits, function(a, b) return a.t < b.t end)
    local delay = pend_hits[1].t - util.time()
    perf_m:start(math.max(0.001, delay), 1)
  end
end

-- Crow Integration
function crow_mono_tracker(ch, note, vel, is_on)
  local stack = crow_active_notes[ch]
  
  if is_on then
    for i = #stack, 1, -1 do
      if stack[i].note == note then table.remove(stack, i) end
    end
    table.insert(stack, {note = note, vel = vel})
  else
    for i = #stack, 1, -1 do
      if stack[i].note == note then table.remove(stack, i) end
    end
  end
  
  local out_note, out_vel, out_gate
  if #stack > 0 then
    local top = stack[#stack]
    out_note = top.note
    out_vel = top.vel
    out_gate = true
  else
    out_note = 60
    out_vel = 0
    out_gate = false
  end
  
  for i = 1, 4 do
    local opt = params:get("crow_out_" .. i)
    local target_ch = (opt >= 2 and opt <= 5) and 1 or 2
    
    if ch == target_ch then
      if opt == 2 or opt == 6 then 
        if out_gate then crow.output[i].volts = (out_note - 60) / 12 end
      elseif opt == 3 or opt == 7 then 
        crow.output[i].volts = out_gate and 5 or 0
      elseif opt == 4 or opt == 8 then 
        if out_gate then crow.output[i].volts = (out_vel / 127) * 8 end
      end
    end
  end
end

-- Perf Callback to Play Notes
function perf_callback()
  local now = util.time()
  local due, rem = {}, {}
  
  for _, h in ipairs(pend_hits) do 
    table.insert(h.t <= now + 0.005 and due or rem, h) 
  end
  pend_hits = rem
  
  for _, h in ipairs(due) do
    local target_ch = params:get(h.ch == 1 and "midi_out_1" or "midi_out_2")
    
    if h.type == "on" then 
      m:note_on(h.note, h.vel, target_ch)
      crow_mono_tracker(h.ch, h.note, h.vel, true)
      
      local p = params:lookup_param(h.ch == 1 and "nb_voice_1" or "nb_voice_2"):get_player()
      if p ~= nil then p:note_on(h.note, h.vel / 127) end
      
    elseif h.type == "off" then 
      m:note_off(h.note, 0, target_ch)
      crow_mono_tracker(h.ch, h.note, 0, false)
      
      local p = params:lookup_param(h.ch == 1 and "nb_voice_1" or "nb_voice_2"):get_player()
      if p ~= nil then p:note_off(h.note) end
      
    elseif h.type == "cc" then
      m:cc(h.cc, h.val, target_ch)
      
    elseif h.type == "crow_clock" then
      for i = 1, 4 do
        local opt = params:get("crow_out_" .. i)
        local out_ch = (opt >= 2 and opt <= 5) and 1 or 2
        if h.ch == out_ch and (opt == 5 or opt == 9) then
           crow.output[i]()
        end
      end
    end
  end
  
  update_queue()
end

-- Wrap Steps on Loop Lock
function step_wrap(s, e, val, delta)
  local len = s <= e and (e - s + 1) or ((64 - s + 1) + e)
  if len <= 0 then return s end
  
  local idx = 0
  if val >= s then idx = val - s
  elseif s > e and val <= e then idx = (64 - s + 1) + val - 1
  else idx = 0 end
  
  idx = (idx + delta) % len
  
  local res = s + idx
  if res > 64 then res = res - 64 end
  return res
end

-- Sub Step
function get_initial_sub_step(ch)
  local o = seq[ch].play_order
  if o == 4 or o == 5 then return 2
  elseif o == 6 or o == 7 then return 4
  else return 1 end
end

-- Sequencer Engine
function seq_engine(ch)
  while true do
    if seq[ch].playing then
      
      local base_idx, mod_roll, tuplet_count, time_mult
      local rp = seq[ch].rhythm_prob
      local live_step = nil
      local step_locked = seq[ch].is_locked
      
      local s = seq[ch].start_step
      local e = seq[ch].end_step
      
      if seq[ch].bounds_set == nil then
         seq[ch].bounds_set = false
      end

      if not step_locked then
        if seq[ch].reset_hold then
          seq[ch].reset_hold = false
          if not seq[ch].bounds_set then
             seq[ch].end_step = seq[ch].current_step
             e = seq[ch].end_step
          end
        else
          if not seq[ch].bounds_set then
            -- Grow Loop Unless Set
            seq[ch].current_step = seq[ch].current_step + 1
            if seq[ch].current_step > 64 then 
               seq[ch].current_step = 1 
               seq[ch].bounds_set = true
               seq[ch].end_step = 64
               e = 64
            else
               seq[ch].end_step = seq[ch].current_step
               e = seq[ch].end_step
            end
          else
            -- Record Loop Between Start and End Points
            seq[ch].current_step = step_wrap(s, e, seq[ch].current_step, 1)
          end
        end
        
        local base_weights = {table.unpack(rp, 1, 6)}
        base_idx = get_weighted_choice(base_weights) or 4
        seq[ch].active_base_rhythm = base_idx 
        
        local mod_norm = math.max(0, 100 - (rp[7] + rp[8]))
        mod_roll = get_weighted_choice({rp[7], rp[8], mod_norm}) or 3
        
        tuplet_count = (mod_roll == 2) and 3 or 1
        time_mult = (mod_roll == 1) and 1.5 or 1.0
        
        live_step = {base_idx = base_idx, mod_roll = mod_roll, tuplet_count = tuplet_count, time_mult = time_mult, sub_steps = {}}
        seq[ch].loop_buffer[seq[ch].current_step] = live_step
        seq[ch].loop_head = seq[ch].current_step
        
      else
        if seq[ch].reset_hold then
           seq[ch].reset_hold = false
        else
           local o = seq[ch].play_order
           seq[ch].play_sub_step = seq[ch].play_sub_step or 1
           seq[ch].pendulum_dir = seq[ch].pendulum_dir or 1
           
           if o == 1 then 
              seq[ch].loop_head = step_wrap(s, e, seq[ch].loop_head, 1)
           elseif o == 2 then 
              seq[ch].loop_head = step_wrap(s, e, seq[ch].loop_head, -1)
           elseif o == 3 then 
              local len = s <= e and (e - s + 1) or ((64 - s + 1) + e)
              if len <= 1 then
                  seq[ch].loop_head = s
              else
                  local next_head = step_wrap(s, e, seq[ch].loop_head, seq[ch].pendulum_dir)
                  if next_head == e and seq[ch].pendulum_dir == 1 then
                      seq[ch].pendulum_dir = -1
                  elseif next_head == s and seq[ch].pendulum_dir == -1 then
                      seq[ch].pendulum_dir = 1
                  end
                  seq[ch].loop_head = next_head
              end
           elseif o == 4 then 
              local deltas = {2, -1}
              seq[ch].loop_head = step_wrap(s, e, seq[ch].loop_head, deltas[seq[ch].play_sub_step])
              seq[ch].play_sub_step = (seq[ch].play_sub_step % 2) + 1
           elseif o == 5 then 
              local deltas = {-2, 1}
              seq[ch].loop_head = step_wrap(s, e, seq[ch].loop_head, deltas[seq[ch].play_sub_step])
              seq[ch].play_sub_step = (seq[ch].play_sub_step % 2) + 1
           elseif o == 6 then 
              local deltas = {1, 1, 1, -1}
              seq[ch].loop_head = step_wrap(s, e, seq[ch].loop_head, deltas[seq[ch].play_sub_step])
              seq[ch].play_sub_step = (seq[ch].play_sub_step % 4) + 1
           elseif o == 7 then 
              local deltas = {-1, -1, -1, 1}
              seq[ch].loop_head = step_wrap(s, e, seq[ch].loop_head, deltas[seq[ch].play_sub_step])
              seq[ch].play_sub_step = (seq[ch].play_sub_step % 4) + 1
           elseif o == 8 then 
              local len = s <= e and (e - s + 1) or ((64 - s + 1) + e)
              if len > 0 then
                  local rand_offset = math.random(0, len - 1)
                  seq[ch].loop_head = step_wrap(s, e, s, rand_offset)
              end
           end
        end
        
        seq[ch].current_step = seq[ch].loop_head
        
        local mem = seq[ch].loop_buffer[seq[ch].loop_head]
        if not mem or not mem.base_idx then 
           mem = {base_idx=4, mod_roll=3, tuplet_count=1, time_mult=1, sub_steps={{a_idx=1, hum_roll=3, will_tie=false}}} 
        end
        
        base_idx = mem.base_idx
        mod_roll = mem.mod_roll
        tuplet_count = mem.tuplet_count
        time_mult = mem.time_mult
      end
      
      -- Math Clamp & Boundary Logic 
      local sig = clock_options.sig[seq[ch].sig_idx]
      local top, bottom = sig:match("(%d+)/(%d+)")
      local num, den = tonumber(top), tonumber(bottom)
      local measure_length = num * (4 / den)
      
      local current_bar_pos = seq[ch].beat_counter
      local is_downbeat = (current_bar_pos < 0.001)
      
      local total_step_beats = rhythm_bases[base_idx] * time_mult * clock_options.div[seq[ch].div_idx]
      
      if not step_locked and seq[ch].bar_enforced_this_bar then
        local space_remaining = measure_length - current_bar_pos
        if space_remaining < 0.001 then space_remaining = measure_length end
        if total_step_beats > space_remaining then
          total_step_beats = space_remaining
        end
      end
      
      local sub_step_beats = total_step_beats / tuplet_count
      local note_sec = sub_step_beats * clock.get_beat_sec()
      
      for sub = 1, tuplet_count do
        seq[ch].active_ornaments = {}
        
        local pre_sub_bar_pos = seq[ch].beat_counter
        
        seq[ch].beat_counter = seq[ch].beat_counter + sub_step_beats
        while seq[ch].beat_counter >= measure_length - 0.001 do
          seq[ch].beat_counter = seq[ch].beat_counter - measure_length
          
          -- Bar Enforce Across Bar Line
          if not step_locked then
            local enforce_pct = seq[ch].bar_enforce or 0
            seq[ch].bar_enforced_this_bar = (enforce_pct > 0 and math.random(1, 100) <= enforce_pct)
          end
        end
        
        -- Calculate or Retrieve Humanize Timing
        local hum_roll = 3
        if not step_locked then
          local hum_norm = math.max(0, 100 - (rp[11] + rp[12]))
          hum_roll = get_weighted_choice({rp[11], rp[12], hum_norm}) or 3
        else
          local mem = seq[ch].loop_buffer[seq[ch].loop_head]
          if mem and mem.sub_steps and mem.sub_steps[sub] and mem.sub_steps[sub].hum_roll then
            hum_roll = mem.sub_steps[sub].hum_roll
          end
        end
        
        local is_offbeat = (seq[ch].beat_counter % 0.5) >= 0.24 
        local swing_pct = clock_options.swing[seq[ch].swing_idx]
        local swing_delay = is_offbeat and ((swing_pct - 50) / 50) * (clock.get_beat_sec() / 4) or 0
        local human_offset = (hum_roll == 1 and -0.03) or (hum_roll == 2 and 0.03) or 0
        local scheduled_time = util.time() + swing_delay + human_offset
        
        table.insert(pend_hits, {t = scheduled_time, type = "crow_clock", ch = ch})
        
        seq[ch].active_rhythm = {}
        if mod_roll == 1 then table.insert(seq[ch].active_rhythm, 7)
        elseif mod_roll == 2 then table.insert(seq[ch].active_rhythm, 8) end
        if hum_roll == 1 then table.insert(seq[ch].active_rhythm, 11)
        elseif hum_roll == 2 then table.insert(seq[ch].active_rhythm, 12) end
        
        local a_idx
        local mem_sub = nil
        
        -- Independent Probabilties
        if not step_locked then
          -- Previous Tie
          if seq[ch].next_a_idx == 2 then 
            a_idx = 2 
          else
            -- Note vs Rest
            if rp[9] > 0 and math.random(1, 100) <= rp[9] then
              a_idx = 1
            else
              a_idx = 3
            end
          end
          
          -- Hard Lock Rhythm Anchor (Forces Note on downbeat)
          if pre_sub_bar_pos < 0.001 and seq[ch].bar_enforced_this_bar and sub == 1 then
             a_idx = 3
          end
          
          -- Tie Next Note
          if rp[10] > 0 and math.random(1, 100) <= rp[10] then
             seq[ch].next_a_idx = 2
          else
             seq[ch].next_a_idx = 3
          end
        else
          local mem = seq[ch].loop_buffer[seq[ch].loop_head]
          if mem and mem.sub_steps then mem_sub = mem.sub_steps[sub] end
          if not mem_sub then mem_sub = {a_idx = 1, hum_roll = 3, will_tie = false} end 
          a_idx = mem_sub.a_idx
          seq[ch].next_a_idx = mem_sub.will_tie and 2 or 3
        end
        
        local will_tie = (seq[ch].next_a_idx == 2)
        
        if a_idx == 1 then 
          seq[ch].is_tied_ui = false
          seq[ch].is_resting = true
          seq[ch].active_note = 0
          seq[ch].active_note_str = "---"
          
          seq[ch].active_chord = {}
          seq[ch].active_voicing = {}
          seq[ch].active_octave = {}
          seq[ch].active_base_velocity = 0
          seq[ch].active_velocity = {}
          seq[ch].active_ornaments = {}
          
          table.insert(seq[ch].active_rhythm, 9)
          
          for _, n in ipairs(seq[ch].active_midi_notes or {}) do
            table.insert(pend_hits, {t = scheduled_time, type = "off", note = n, ch = ch})
          end
          seq[ch].active_midi_notes = {}
          
          -- Handle Ties in Loop Lock
          if not step_locked then table.insert(live_step.sub_steps, {a_idx = 1, hum_roll = hum_roll, will_tie = will_tie}) end
          
        elseif a_idx == 2 then 
          seq[ch].is_tied_ui = true
          
          if seq[ch].is_resting then
            table.insert(seq[ch].active_rhythm, 9)
          end
          table.insert(seq[ch].active_rhythm, 10)
          
          if not will_tie then
            for _, n in ipairs(seq[ch].active_midi_notes or {}) do
              table.insert(pend_hits, {t = scheduled_time + (note_sec * 0.9), type = "off", note = n, ch = ch})
            end
          end
          
          if not step_locked then table.insert(live_step.sub_steps, {a_idx = 2, hum_roll = hum_roll, will_tie = will_tie}) end
          
        elseif a_idx == 3 then 
          seq[ch].is_tied_ui = false
          seq[ch].is_resting = false
          
          local note_idx, vel, vel_base_idx, oct_idx, dbl_sub, dbl_up
          local chord_notes = {}
          local hat_a, hat_b, hat_c, is_sustain, is_repeater
          local root_raw
          
          if not step_locked then
            seq[ch].is_improvising = false
            note_idx = get_weighted_choice(seq[ch].note_prob, seq[ch].notes)
            seq[ch].active_note = note_idx or 0
            
            if note_idx then
              local vel_base_weights = {table.unpack(seq[ch].velocity_prob, 1, 8)}
              vel_base_idx = get_weighted_choice(vel_base_weights) or 5
              seq[ch].active_base_velocity = vel_base_idx
              seq[ch].active_velocity = {vel_base_idx}
              
              vel = velocity_vals[vel_base_idx]
              
              -- Velocity Humanization (+/- 1 to 10)
              local v_hum_plus = seq[ch].velocity_prob[9]
              local v_hum_minus = seq[ch].velocity_prob[10]
              local v_hum_norm = math.max(0, 100 - (v_hum_plus + v_hum_minus))
              local v_hum_roll = get_weighted_choice({v_hum_plus, v_hum_minus, v_hum_norm}) or 3
              
              if v_hum_roll == 1 then
                vel = vel + math.random(1, 10)
                table.insert(seq[ch].active_velocity, 9)
              elseif v_hum_roll == 2 then
                vel = vel - math.random(1, 10)
                table.insert(seq[ch].active_velocity, 10)
              end
              
              -- Smart Accent
              if seq[ch].bar_enforced_this_bar and is_strong_beat(num, den, pre_sub_bar_pos) then 
                 vel = vel + params:get("bar_accent")
              end
              
              vel = util.clamp(vel, 1, 127)
              
              local oct_base_weights = {table.unpack(seq[ch].octave_prob, 1, 9)}
              oct_idx = get_weighted_choice(oct_base_weights) or 5
              
              local oct_offset = oct_idx - 5 
              local base_midi = 60 + (note_idx - 1) + (oct_offset * 12)
              
              local op10 = seq[ch].octave_prob[10]
              local op11 = seq[ch].octave_prob[11]
              local dbl_norm = math.max(0, 100 - (op10 + op11))
              local dbl_roll = get_weighted_choice({op10, op11, dbl_norm})
              dbl_sub = (dbl_roll == 1)
              dbl_up = (dbl_roll == 2)
              
              seq[ch].active_octave = {oct_idx}
              if dbl_sub then table.insert(seq[ch].active_octave, 10) end
              if dbl_up then table.insert(seq[ch].active_octave, 11) end
              
              local play_chord = (seq[ch].chord_prob[1] > 0) and (math.random(1, 100) <= seq[ch].chord_prob[1])
              seq[ch].active_chord = {}
              
              if play_chord then
                local size_weights = {seq[ch].chord_prob[2], seq[ch].chord_prob[3]}
                local size_roll = get_weighted_choice(size_weights) or 1
                local note_count = (size_roll == 1) and 3 or 4
                
                local quality_weights = {table.unpack(seq[ch].chord_prob, 4, 12)}
                local quality_roll = get_weighted_choice(quality_weights) or 1
                local quality_idx = quality_roll + 3 
                
                seq[ch].active_chord = {1, size_roll + 1, quality_idx}
                
                local intervals = chord_intervals[quality_idx]
                for i = 1, note_count do table.insert(chord_notes, base_midi + intervals[i]) end
                
                local chord_names = {[4]="Maj", [5]="m", [6]="Dom", [7]="7b5", [8]="m7b5", [9]="dim", [10]="mM", [11]="Aug", [12]="M#5"}
                seq[ch].active_note_str = roots[note_idx] .. chord_names[quality_idx] .. (note_count == 4 and "7" or "")
              else
                table.insert(chord_notes, base_midi)
                seq[ch].active_note_str = roots[note_idx]
              end
              
              seq[ch].active_voicing = {}
              if play_chord then
                local vp = seq[ch].voicing_prob
                local base = base_midi
                
                local inv_norm = math.max(0, 100 - (vp[1] + vp[2] + vp[3]))
                local inv_roll = get_weighted_choice({vp[1], vp[2], vp[3], inv_norm})
                if inv_roll and inv_roll <= 3 then table.insert(seq[ch].active_voicing, inv_roll) end
                
                local drop_norm = math.max(0, 100 - (vp[4] + vp[5]))
                local drop_roll = get_weighted_choice({vp[4], vp[5], drop_norm})
                if drop_roll == 1 then table.insert(seq[ch].active_voicing, 4)
                elseif drop_roll == 2 then table.insert(seq[ch].active_voicing, 5) end
                
                local sus_norm = math.max(0, 100 - (vp[11] + vp[12]))
                local sus_roll = get_weighted_choice({vp[11], vp[12], sus_norm})
                if sus_roll == 1 then table.insert(seq[ch].active_voicing, 11)
                elseif sus_roll == 2 then table.insert(seq[ch].active_voicing, 12) end
                
                if sus_roll == 1 and #chord_notes >= 2 then chord_notes[2] = base + 2 end
                if sus_roll == 2 and #chord_notes >= 2 then chord_notes[2] = base + 5 end
                
                if math.random(1, 100) <= vp[6] then table.insert(chord_notes, base + 9); table.insert(seq[ch].active_voicing, 6) end
                if math.random(1, 100) <= vp[7] then table.insert(chord_notes, base + 12); table.insert(seq[ch].active_voicing, 7) end
                if math.random(1, 100) <= vp[8] then table.insert(chord_notes, base + 14); table.insert(seq[ch].active_voicing, 8) end
                
                if math.random(1, 100) <= vp[10] then
                  table.insert(seq[ch].active_voicing, 10)
                  for i = #chord_notes, 1, -1 do
                    local diff = chord_notes[i] - base
                    if diff == 6 or diff == 7 or diff == 8 then table.remove(chord_notes, i) end
                  end
                end
                if math.random(1, 100) <= vp[9] then
                  table.insert(seq[ch].active_voicing, 9)
                  for i = #chord_notes, 1, -1 do
                    if chord_notes[i] == base then table.remove(chord_notes, i) end
                  end
                end
                
                table.sort(chord_notes) 
                
                if inv_roll == 1 and #chord_notes >= 2 then
                  chord_notes[1] = chord_notes[1] + 12
                elseif inv_roll == 2 and #chord_notes >= 3 then
                  chord_notes[1] = chord_notes[1] + 12; chord_notes[2] = chord_notes[2] + 12
                elseif inv_roll == 3 and #chord_notes >= 4 then
                  chord_notes[1] = chord_notes[1] + 12; chord_notes[2] = chord_notes[2] + 12; chord_notes[3] = chord_notes[3] + 12
                end
                
                table.sort(chord_notes) 
                
                if drop_roll == 1 and #chord_notes >= 2 then      
                  chord_notes[#chord_notes - 1] = chord_notes[#chord_notes - 1] - 12
                elseif drop_roll == 2 and #chord_notes >= 4 then  
                  chord_notes[#chord_notes - 3] = chord_notes[#chord_notes - 3] - 12
                end
                
                table.sort(chord_notes) 
              end
              
              local op = seq[ch].ornament_prob
              is_sustain = (op[1] > 0) and (math.random(1, 100) <= op[1])
              is_repeater = (op[12] > 0) and (math.random(1, 100) <= op[12])
              
              local a_norm = math.max(0, 100 - (op[2] + op[3] + op[4]))
              hat_a = get_weighted_choice({op[2], op[3], op[4], a_norm})
              local b_norm = math.max(0, 100 - (op[5] + op[6] + op[7] + op[8] + op[9]))
              hat_b = get_weighted_choice({op[5], op[6], op[7], op[8], op[9], b_norm})
              hat_c = 3
              if #chord_notes > 1 then
                local c_norm = math.max(0, 100 - (op[10] + op[11]))
                hat_c = get_weighted_choice({op[10], op[11], c_norm})
              end
              
              root_raw = chord_notes[1]
              
              table.insert(live_step.sub_steps, {
                 a_idx = 3, hum_roll = hum_roll, note_idx = note_idx, vel = vel,
                 vel_base_idx = vel_base_idx, oct_idx = oct_idx, dbl_sub = dbl_sub, dbl_up = dbl_up,
                 chord_notes = {table.unpack(chord_notes)}, hat_a = hat_a, hat_b = hat_b, hat_c = hat_c,
                 is_sustain = is_sustain, is_repeater = is_repeater, root_raw = root_raw,
                 active_note_str = seq[ch].active_note_str, active_voicing = {table.unpack(seq[ch].active_voicing)},
                 active_velocity = {table.unpack(seq[ch].active_velocity)},
                 will_tie = will_tie
              })
            end
            
          else
            note_idx = mem_sub.note_idx or 1
            seq[ch].active_note = note_idx
            
            vel_base_idx = mem_sub.vel_base_idx or 5
            seq[ch].active_base_velocity = vel_base_idx
            
            oct_idx = mem_sub.oct_idx or 5
            dbl_sub = mem_sub.dbl_sub or false
            dbl_up = mem_sub.dbl_up or false
            
            seq[ch].active_octave = {oct_idx}
            if dbl_sub then table.insert(seq[ch].active_octave, 10) end
            if dbl_up then table.insert(seq[ch].active_octave, 11) end
            
            chord_notes = mem_sub.chord_notes and {table.unpack(mem_sub.chord_notes)} or {60}
            root_raw = mem_sub.root_raw or 60
            seq[ch].active_note_str = mem_sub.active_note_str or "-"
            seq[ch].active_voicing = mem_sub.active_voicing and {table.unpack(mem_sub.active_voicing)} or {}
            
            seq[ch].is_improvising = false
            
            if seq[ch].improvise > 0 and math.random(1, 100) <= seq[ch].improvise then
              seq[ch].is_improvising = true
              
              -- Improvise Velocity on Loop Lock
              local temp_vel = velocity_vals[vel_base_idx]
              seq[ch].active_velocity = {vel_base_idx}
              
              local v_hum_plus = seq[ch].velocity_prob[9]
              local v_hum_minus = seq[ch].velocity_prob[10]
              local v_hum_norm = math.max(0, 100 - (v_hum_plus + v_hum_minus))
              local v_hum_roll = get_weighted_choice({v_hum_plus, v_hum_minus, v_hum_norm}) or 3
              
              if v_hum_roll == 1 then
                temp_vel = temp_vel + math.random(1, 10)
                table.insert(seq[ch].active_velocity, 9)
              elseif v_hum_roll == 2 then
                temp_vel = temp_vel - math.random(1, 10)
                table.insert(seq[ch].active_velocity, 10)
              end
              
              -- Bar Enforce for Locked Loop
              if seq[ch].bar_enforced_this_bar and is_strong_beat(num, den, pre_sub_bar_pos) then 
                 temp_vel = temp_vel + params:get("bar_accent")
              end
              
              vel = util.clamp(temp_vel, 1, 127)
              
              -- Improvise Ornaments on Loop Lock
              local op = seq[ch].ornament_prob
              is_sustain = (op[1] > 0) and (math.random(1, 100) <= op[1])
              is_repeater = (op[12] > 0) and (math.random(1, 100) <= op[12])
              local a_norm = math.max(0, 100 - (op[2] + op[3] + op[4]))
              hat_a = get_weighted_choice({op[2], op[3], op[4], a_norm})
              local b_norm = math.max(0, 100 - (op[5] + op[6] + op[7] + op[8] + op[9]))
              hat_b = get_weighted_choice({op[5], op[6], op[7], op[8], op[9], b_norm})
              hat_c = 3
              if #chord_notes > 1 then
                local c_norm = math.max(0, 100 - (op[10] + op[11]))
                hat_c = get_weighted_choice({op[10], op[11], c_norm})
              end
            else
              -- Standard Loop Lock
              vel = mem_sub.vel or 64
              seq[ch].active_velocity = mem_sub.active_velocity and {table.unpack(mem_sub.active_velocity)} or {vel_base_idx}
              
              hat_a = mem_sub.hat_a or 4
              hat_b = mem_sub.hat_b or 6
              hat_c = mem_sub.hat_c or 3
              is_sustain = mem_sub.is_sustain or false
              is_repeater = mem_sub.is_repeater or false
            end
          end
          
          if note_idx then
            seq[ch].active_ornaments = {}
            if is_sustain then table.insert(seq[ch].active_ornaments, 1) end
            if hat_a < 4 then table.insert(seq[ch].active_ornaments, hat_a + 1) end
            if hat_b < 6 then table.insert(seq[ch].active_ornaments, hat_b + 4) end
            if hat_c < 3 then table.insert(seq[ch].active_ornaments, hat_c + 9) end
            if is_repeater then table.insert(seq[ch].active_ornaments, 12) end
            
            if is_repeater and seq[ch].last_event then
              chord_notes = {table.unpack(seq[ch].last_event)}
            else
              seq[ch].last_event = {table.unpack(chord_notes)}
            end
            
            if is_sustain then
              table.insert(pend_hits, {t = scheduled_time, type = "cc", cc = 64, val = 127, ch = ch})
              local sus_dur = note_sec
              if seq[ch].bar_enforced_this_bar then
                local beats_left = measure_length - pre_sub_bar_pos
                if beats_left < 0.001 then beats_left = measure_length end
                sus_dur = beats_left * clock.get_beat_sec()
              end
              table.insert(pend_hits, {t = scheduled_time + (sus_dur * 0.95), type = "cc", cc = 64, val = 0, ch = ch})
            end
            
            local function get_scale_neighbor(midi_val, step_dir)
              local test_val = midi_val
              for i = 1, 11 do
                test_val = test_val + step_dir
                local wrap = test_val
                while wrap > 127 do wrap = wrap - 12 end
                while wrap < 0 do wrap = wrap + 12 end
                if seq[ch].notes[(wrap % 12) + 1] then return test_val end
              end
              return midi_val + step_dir 
            end
            
            local main_delay = 0
            local b_step_dur = 0.03
            
            if hat_b < 6 then
              local b_events = {}
              if hat_b == 1 then
                table.insert(b_events, get_scale_neighbor(root_raw, 1))
                main_delay = 0.04
              elseif hat_b == 2 then
                table.insert(b_events, get_scale_neighbor(root_raw, -1))
                main_delay = 0.04
              elseif hat_b == 3 then
                table.insert(pend_hits, {t = scheduled_time, type = "on", note = root_raw, vel = math.floor(vel * 0.4), ch = ch})
                table.insert(pend_hits, {t = scheduled_time + 0.03, type = "off", note = root_raw, ch = ch})
                main_delay = 0.05
              elseif hat_b == 4 then
                table.insert(b_events, root_raw)
                table.insert(b_events, get_scale_neighbor(root_raw, 1))
                b_step_dur = 0.04
                main_delay = 0.08
              elseif hat_b == 5 then
                if seq[ch].last_midi_val then
                  local start_n = seq[ch].last_midi_val
                  local dir = (root_raw > start_n) and 1 or -1
                  local dist = math.abs(root_raw - start_n)
                  if dist > 0 and dist < 24 then
                     local run_note = start_n
                     local run_count = 0
                     while run_note ~= root_raw and run_count < 6 do 
                       run_note = get_scale_neighbor(run_note, dir)
                       if run_note ~= root_raw then
                         table.insert(b_events, run_note)
                         run_count = run_count + 1
                       end
                     end
                  end
                end
                if #b_events > 0 then
                  local sixteenth = clock.get_beat_sec() / 4
                  local max_allowed = note_sec / (#b_events + 1.5) 
                  b_step_dur = math.min(sixteenth, max_allowed)
                  main_delay = (#b_events * b_step_dur)
                end
              end
              
              for i, f_note in ipairs(b_events) do
                 local f_t = scheduled_time + ((i-1) * b_step_dur)
                 local safe_f = f_note
                 while safe_f > 127 do safe_f = safe_f - 12 end
                 while safe_f < 0 do safe_f = safe_f + 12 end
                 
                 local f_pitches = {safe_f}
                 if dbl_sub and (safe_f - 12 >= 0) then table.insert(f_pitches, safe_f - 12) end
                 if dbl_up and (safe_f + 12 <= 127) then table.insert(f_pitches, safe_f + 12) end
                 
                 for _, p in ipairs(f_pitches) do
                     table.insert(pend_hits, {t = f_t, type = "on", note = p, vel = math.floor(vel * 0.7), ch = ch})
                     table.insert(pend_hits, {t = f_t + (b_step_dur * 0.8), type = "off", note = p, ch = ch})
                 end
              end
            end
            
            seq[ch].last_midi_val = root_raw
            
            local strum_gap = 0
            if hat_c == 1 then strum_gap = 0.03 
            elseif hat_c == 2 then strum_gap = -0.03 end 
            
            seq[ch].active_midi_notes = {}
            for chord_i, raw_midi in ipairs(chord_notes) do
              local final_on_t = scheduled_time + main_delay
              
              local stagger = 0
              if hat_c == 1 then stagger = (chord_i - 1) * strum_gap
              elseif hat_c == 2 then stagger = (#chord_notes - chord_i) * math.abs(strum_gap) end
              final_on_t = final_on_t + stagger
              
              local function get_doubled_pitches(base_p)
                  local safe_base = base_p
                  while safe_base > 127 do safe_base = safe_base - 12 end
                  while safe_base < 0 do safe_base = safe_base + 12 end
                  
                  local p_list = {safe_base}
                  if chord_i == 1 then 
                      if dbl_sub and (safe_base - 12 >= 0) then table.insert(p_list, safe_base - 12) end
                      if dbl_up and (safe_base + 12 <= 127) then table.insert(p_list, safe_base + 12) end
                  end
                  return p_list
              end
              
              if hat_a < 4 then
                if hat_a == 3 then
                   local trill_dur = note_sec * 0.9
                   local trill_speed = 0.1 
                   local t_steps = math.max(2, math.floor(trill_dur / trill_speed))
                   local t_step_dur = trill_dur / t_steps
                   for i=1, t_steps do
                     local t_pitch = raw_midi
                     if i % 2 == 0 then t_pitch = get_scale_neighbor(raw_midi, 1) end
                     local t_on = final_on_t + ((i-1) * t_step_dur)
                     for _, p in ipairs(get_doubled_pitches(t_pitch)) do
                         table.insert(pend_hits, {t = t_on, type = "on", note = p, vel = vel, ch = ch})
                         if not will_tie or i < t_steps then
                           table.insert(pend_hits, {t = t_on + (t_step_dur * 0.8), type = "off", note = p, ch = ch})
                         end
                     end
                   end
                else
                   local strikes = (hat_a == 1) and 2 or 3
                   local t_step_dur = (note_sec * 0.9) / strikes
                   for i=1, strikes do
                     local t_on = final_on_t + ((i-1) * t_step_dur)
                     for _, p in ipairs(get_doubled_pitches(raw_midi)) do
                         table.insert(pend_hits, {t = t_on, type = "on", note = p, vel = vel, ch = ch})
                         if not will_tie or i < strikes then
                           table.insert(pend_hits, {t = t_on + (t_step_dur * 0.8), type = "off", note = p, ch = ch})
                         end
                     end
                   end
                end
              else
                for _, p in ipairs(get_doubled_pitches(raw_midi)) do
                    table.insert(seq[ch].active_midi_notes, p)
                    table.insert(pend_hits, {t = final_on_t, type = "on", note = p, vel = util.clamp(vel, 1, 127), ch = ch})
                    if not will_tie then
                      table.insert(pend_hits, {t = scheduled_time + (note_sec * 0.9), type = "off", note = p, ch = ch})
                    end
                end
              end
            end
          end
        end
        
        update_queue()
        if screen_page >= 3 and screen_page <= 10 then grid_redraw() end
        redraw()
        clock.sleep(note_sec)
      end
      
    else
      clock.sync(1/16)
    end
  end
end

-- Trigger Reset
function trigger_reset(ch)
  if seq[ch].engine_clock then 
    clock.cancel(seq[ch].engine_clock) 
    seq[ch].engine_clock = nil
  end
  
  for i = #pend_hits, 1, -1 do
    if pend_hits[i].ch == ch then
      if pend_hits[i].type == "on" then
        table.remove(pend_hits, i)
      else
        pend_hits[i].t = util.time()
      end
    end
  end
  
  for _, n in ipairs(seq[ch].active_midi_notes or {}) do
     table.insert(pend_hits, {t = util.time(), type = "off", note = n, ch = ch})
  end
  seq[ch].active_midi_notes = {}
  
  local p = params:lookup_param(ch == 1 and "nb_voice_1" or "nb_voice_2"):get_player()
  if p ~= nil then p:stop_all() end
  
  if update_queue then update_queue() end
  
  if crow_active_notes then crow_active_notes[ch] = {} end
  for i = 1, 4 do
    local opt = params:get("crow_out_" .. i)
    local target_ch = (opt >= 2 and opt <= 5) and 1 or 2
    if target_ch == ch and (opt == 3 or opt == 7) then crow.output[i].volts = 0 end
  end
  
  seq[ch].last_event = nil
  seq[ch].last_midi_val = nil
  seq[ch].next_a_idx = nil
  
  seq[ch].beat_counter = 0
  seq[ch].pendulum_dir = 1
  
  local enforce_pct = seq[ch].bar_enforce or 0
  seq[ch].bar_enforced_this_bar = (enforce_pct > 0 and math.random(1, 100) <= enforce_pct)
  
  local visual_start = seq[ch].start_step
  if seq[ch].is_locked then
    local o = seq[ch].play_order
    if o == 2 or o == 5 or o == 7 then 
      visual_start = seq[ch].end_step 
    end
  end
  
  if seq[ch].is_locked then
    seq[ch].loop_head = visual_start
    seq[ch].play_sub_step = get_initial_sub_step(ch)
    seq[ch].current_step = visual_start 
    seq[ch].reset_hold = true 
  else
    seq[ch].current_step = visual_start
    seq[ch].reset_hold = true 
  end
  
  seq[ch].engine_clock = clock.run(seq_engine, ch)
end