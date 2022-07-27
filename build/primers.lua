local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string


local complement = require("complement")
local primers = {thermodynamics = {}, }





























primers.nearest_neighbors_thermodynamics = {
   AA = { h = -7.6, s = -21.3 },
   TT = { h = -7.6, s = -21.3 },
   AT = { h = -7.2, s = -20.4 },
   TA = { h = -7.2, s = -21.3 },
   CA = { h = -8.5, s = -22.7 },
   TG = { h = -8.5, s = -22.7 },
   GT = { h = -8.4, s = -22.4 },
   AC = { h = -8.4, s = -22.4 },
   CT = { h = -7.8, s = -21.0 },
   AG = { h = -7.8, s = -21.0 },
   GA = { h = -8.2, s = -22.2 },
   TC = { h = -8.2, s = -22.2 },
   CG = { h = -10.6, s = -27.2 },
   GC = { h = -9.8, s = -24.4 },
   GG = { h = -8.0, s = -19.9 },
   CC = { h = -8.0, s = -19.9 },
}
primers.initial_thermodynamic_penalty = { h = 0.2, s = -5.7 }
primers.symmetry_thermodynamic_penalty = { h = 0, s = -1.4 }
primers.terminal_at_thermodynamic_penalty = { h = 2.2, s = 6.9 }








function primers.santa_lucia(sequence, primer_concentration, salt_concentration, magnesium_concentration)

   local melting_temperature = 0
   local dH = 0
   local dS = 0

   sequence = sequence:upper()
   local gas_constant = 1.9872
   local symmetry_factor = 4


   dH = dH + primers.initial_thermodynamic_penalty.h
   dS = dS + primers.initial_thermodynamic_penalty.s

   if sequence == complement.reverse_complement(sequence) then
      dH = dH + primers.symmetry_thermodynamic_penalty.h
      dS = dS + primers.symmetry_thermodynamic_penalty.s
      symmetry_factor = 1
   end

   if sequence:sub(-1, -1) == "A" or sequence:sub(-1, -1) == "T" then
      dH = dH + primers.terminal_at_thermodynamic_penalty.h
      dS = dS + primers.terminal_at_thermodynamic_penalty.s
   end

   local salt_effect = salt_concentration + (magnesium_concentration * 140)
   dS = dS + ((0.368 * (sequence:len() - 1)) * math.log(salt_effect))

   for i = 1, sequence:len() - 1, 1 do
      local dT = primers.nearest_neighbors_thermodynamics[sequence:sub(i, i + 1)]
      dH = dH + dT.h
      dS = dS + dT.s
   end

   melting_temperature = dH * 1000 / (dS + gas_constant * math.log(primer_concentration / symmetry_factor)) - 273.15
   return melting_temperature
end





function primers.marmur_doty(sequence)
   sequence = sequence:upper()
   local _, a_count = sequence:gsub("A", "")
   local _, t_count = sequence:gsub("T", "")
   local _, g_count = sequence:gsub("G", "")
   local _, c_count = sequence:gsub("C", "")
   return 2 * (a_count + t_count) + 4 * (g_count + c_count) - 7.0
end





function primers.melting_temp(sequence)
   local primer_concentration = 0.000000500
   local salt_concentration = 0.050
   local magnesium_concentration = 0.0
   return primers.santa_lucia(sequence, primer_concentration, salt_concentration, magnesium_concentration)
end
return primers