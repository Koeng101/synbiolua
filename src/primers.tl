--[[---------------------------------------------------------------------------
This module provides functions for calculating primer melting temperatures.
--]]---------------------------------------------------------------------------
local complement = require("complement")
local record primers
	-- thermodynamics stores enthalpy (dH, kcal/mol) and entropy (dS, cal/mol-K) values for nucleotide pairs
	record thermodynamics
		h: number
		s: number
	end

	-- This section contains various penalties applied when calculating primer
	-- melting temperature using the SantaLucia algorithm.
	nearest_neighbors_thermodynamics: {string: thermodynamics} -- penalties for nearest neighbor effects
	initial_thermodynamic_penalty: thermodynamics -- penalty for initiating helix
	symmetry_thermodynamic_penalty: thermodynamics -- penalty for self-complementarity
	terminal_at_thermodynamic_penalty: thermodynamics -- penalty for 3' AT

	-- santa_lucia calculates the melting point of a short DNA sequence (15-200
	-- bp), using the Nearest Neighbors method 
	-- [SantaLucia, J. (1998) PNAS, doi:10.1073/pnas.95.4.1460]
	santa_lucia: function(string, number, number, number): number

	-- marmur_doty calculates the melting point of an extremely short DNA
	-- sequence (<15 bp) using a modified Marmur Doty formula 
	-- [Marmur J & Doty P (1962). Determination of the base composition of 
	-- deoxyribonucleic acid from its thermal denaturation temperature. J Mol Biol, 5, 109-118.]
	marmur_doty: function(string, number)

	-- melting_temp calls SantaLucia with default inputs for primer and salt
	-- concentration.
	melting_temp: function(string): number
end

primers.nearest_neighbors_thermodynamics = {
    AA = {h = -7.6, s = -21.3},
    TT = {h = -7.6, s = -21.3},
    AT = {h = -7.2, s = -20.4},
    TA = {h = -7.2, s = -21.3},
    CA = {h = -8.5, s = -22.7},
    TG = {h = -8.5, s = -22.7},
    GT = {h = -8.4, s = -22.4},
    AC = {h = -8.4, s = -22.4},
    CT = {h = -7.8, s = -21.0},
    AG = {h = -7.8, s = -21.0},
    GA = {h = -8.2, s = -22.2},
    TC = {h = -8.2, s = -22.2},
    CG = {h = -10.6, s = -27.2},
    GC = {h = -9.8, s = -24.4},
    GG = {h = -8.0, s = -19.9},
    CC = {h = -8.0, s = -19.9},
}
primers.initial_thermodynamic_penalty = {h = 0.2, s = -5.7}
primers.symmetry_thermodynamic_penalty = {h = 0, s = -1.4}
primers.terminal_at_thermodynamic_penalty = {h = 2.2, s = 6.9}

--- Returns the melting temperature of a primer given primer concentration, salt concentration, and magnesium concentration
-- @param sequence sequence of the primer
-- @param primer_concentration concentration of the primer
-- @param salt_concentration concentration of salt in buffer
-- @param magnesium_concentration concentration of magnesium in buffer
-- @return melting temperature
-- @usage local melting_temperature = primers.santa_lucia("CAGGAAACAGCTATGAC", 0.0000001, 0.350, 0)
function primers.santa_lucia(sequence: string, primer_concentration: number, salt_concentration: number, magnesium_concentration: number): number
	-- Initialize outputs
	local melting_temperature: number = 0
	local dH: number = 0
	local dS: number = 0

	sequence = sequence:upper()
    sequence = sequence:gsub("[^ATGC]", "")
	local gas_constant = 1.9872 -- gas constant (cal / mol - K)
	local symmetry_factor = 4

	-- apply initialization penalty
	dH = dH + primers.initial_thermodynamic_penalty.h
	dS = dS + primers.initial_thermodynamic_penalty.s
	-- apply symmetry penalty if sequence is self-complementary
	if sequence == complement.reverse_complement(sequence) then
		dH = dH + primers.symmetry_thermodynamic_penalty.h
		dS = dS + primers.symmetry_thermodynamic_penalty.s
		symmetry_factor = 1
	end
	-- apply penalty if 3' nucleotides are A or T
	if sequence:sub(-1,-1) == "A" or sequence:sub(-1,-1) == "T" then
		dH = dH + primers.terminal_at_thermodynamic_penalty.h
		dS = dS + primers.terminal_at_thermodynamic_penalty.s
	end
	-- apply salt penalty ; von Ahsen et al 1999
	local salt_effect = salt_concentration + (magnesium_concentration * 140)
	dS = dS + ((0.368 * (sequence:len() - 1)) * math.log(salt_effect))
	-- calculate penalty for nearest neighbor effects
	for i=1,sequence:len()-1,1 do
		local dT = primers.nearest_neighbors_thermodynamics[sequence:sub(i,i+1)]
		dH = dH + dT.h
		dS = dS + dT.s
	end

	melting_temperature = dH*1000/(dS+gas_constant*math.log(primer_concentration/symmetry_factor)) - 273.15
	return melting_temperature
end

--- Returns the melting temperature of an extremely short DNA sequence (<15bp)
-- @param sequence the primer sequence
-- @return melting temperature
-- @usage local melting_temperature = primers.marmur_doty("ACGTCCGGACTT")
function primers.marmur_doty(sequence: string): number
	sequence = sequence:upper()
	local _, a_count = sequence:gsub("A","")
	local _, t_count = sequence:gsub("T","")
	local _, g_count = sequence:gsub("G","")
	local _, c_count = sequence:gsub("C","")
	return 2*(a_count+t_count) + 4*(g_count+c_count) - 7.0
end

--- Returns the melting temperature using Santa Lucia with reasonable defaults
-- @param sequence the primer sequence
-- @return melting temperature
-- @usage local melting_temperature = primers.melting_temp("ACGTCCGGACTT")
function primers.melting_temp(sequence: string): number
	local primer_concentration = 0.000000500 -- 500e-9, 500 nM (nanomolar) primer concentration
	local salt_concentration = 0.050 -- 50e-3, 50 mM (millimolar) sodium concentration
	local magnesium_concentration = 0.0 -- 0 mM (millimolar) magnesium concentration
	return primers.santa_lucia(sequence, primer_concentration, salt_concentration, magnesium_concentration)
end
return primers
