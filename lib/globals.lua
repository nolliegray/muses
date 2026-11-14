-- lib/globals.lua

mu_scales = {
  "chromatic", "major", "minor", "melodic minor", "harmonic minor",
  "major pentatonic", "minor pentatonic", "whole tone", "diminished whole half",
  "diminished half whole", "blues scale", "major blues"
}

-- Inject custom scales into the musicutil library
table.insert(mu.SCALES, { name = "Major Blues", intervals = {0, 2, 3, 4, 7, 9} })

interval_weights = {
  [0] = 100, -- Root
  [1] = 40,  -- Minor 2nd (High Tension)
  [2] = 60,  -- Major 2nd (Passing)
  [3] = 80,  -- Minor 3rd (Chord Tone)
  [4] = 85,  -- Major 3rd (Chord Tone)
  [5] = 75,  -- Perfect 4th (Suspension)
  [6] = 30,  -- Tritone (Max Tension)
  [7] = 95,  -- Perfect 5th (Dominant)
  [8] = 65,  -- Minor 6th (Color)
  [9] = 70,  -- Major 6th (Color)
  [10] = 75, -- Minor 7th (Dominant 7)
  [11] = 50  -- Major 7th (Leading Tone)
}

-- Chord Definitions (Root, 3rd, 5th, 7th) in semitones from root
chord_intervals = {
  [4]  = {0, 4, 7, 11}, -- M (Major 7)
  [5]  = {0, 3, 7, 10}, -- Minor (Minor 7)
  [6]  = {0, 4, 7, 10}, -- Dominant (Dom 7)
  [7]  = {0, 4, 6, 10}, -- Dominant Flat 5 (Dom 7b5)
  [8]  = {0, 3, 6, 10}, -- Half Dim (Min 7b5)
  [9]  = {0, 3, 6, 9},  -- Full Dim (Dim 7)
  [10] = {0, 3, 7, 11}, -- Maj/Min (Min/Maj 7)
  [11] = {0, 4, 8, 10}, -- Augmented (Aug 7 / Dom 7#5)
  [12] = {0, 4, 8, 11}  -- Maj Augmented (Maj 7#5)
}

pages = {
  "KEY/SCALE", "CLOCK/BAR", "NOTE", "RHYTHM", "CHORD",
  "VOICING", "OCTAVE", "VELOCITY", "ORNAMENT", "LOOP"
}

roots = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

scales = {
  "Chromatic", "Major", "Nat Minor", "Mel Minor", "Harm Minor",
  "Major Pent", "Minor Pent", "Whole Tone", "W Tone Dim",
  "Half W Dim", "Minor Blues", "Major Blues"
}

clock_options = {
  div = {1, 2, 3, 4, 6, 8, 12, 16},
  swing = {25, 33, 42, 46, 50, 54, 58, 66, 71, 75},
  sig = {"2/2", "3/2", "4/2", "2/4", "3/4", "4/4", "5/4", "6/4", "7/4", "9/4", "3/8", "4/8", "6/8", "9/8", "12/4", "12/8"}
}

order_options = {
  "Linear Fwd", "Linear Rev", "Pendulum", "Leap Fwd", "Leap Rev", "Shift Fwd", "Shift Rev", "Random"
}

param_names = {
  [3] = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"},
  [4] = {"32nd", "16th", "Eighth", "Quarter", "Half", "Whole", "Dotted", "Triplet", "Rest", "Tie", "Rush", "Drag"},
  [5] = {"Chord Prob", "Triad", "Seventh", "Major", "Minor", "Dom 7", "Dom 7b5", "Half Dim", "Fully Dim", "Min/Maj", "Aug", "Maj Aug"},
  [6] = {"1st Inversion", "2nd Inversion", "3rd Inversion", "Drop 2", "Drop 4", "Add 6", "Add 8", "Add 9", "No Root", "Shell", "Sus 2", "Sus 4"},
  [7] = {"-4 Oct", "-3 Oct", "-2 Oct", "-1 Oct", "0 Oct", "+1 Oct", "+2 Oct", "+3 Oct", "+4 Oct", "Doubled Sub", "Doubled Up"},
  [8] = {"Pianississimo", "Pianissimo", "Piano", "Mezzo-Piano", "Mezzo-Forte", "Forte", "Fortissimo", "Fortississimo", "Humanize +", "Humanize -"},
  [9] = {"Sustain Pedal", "Tremolo 2x", "Tremolo 3x", "Trill", "Grace Above", "Grace Below", "Ghost Note", "Mordent", "Scale Run", "Arpeggio Up", "Arpeggio Down", "Repeat"}
}

rhythm_bases = {1/8, 1/4, 1/2, 1, 2, 4}
velocity_vals = {16, 32, 48, 64, 80, 96, 112, 127}