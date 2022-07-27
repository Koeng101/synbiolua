--[[---------------------------------------------------------------------------
The complement module provides functions for getting the reverse complement
of a given DNA sequence.
]]-----------------------------------------------------------------------------
local record complement
	COMPLEMENTS: {string:string}
end

--- complement.COMPLEMENTS are DNA base complements.
-- @table COMPLEMENTS
complement.COMPLEMENTS = {
	A = "T",
	B = "V",
	C = "G",
	D = "H",
	G = "C",
	H = "D",
	K = "M",
	M = "K",
	N = "N",
	R = "Y",
	S = "S",
	T = "A",
	U = "A",
	V = "B",
	W = "W",
	Y = "R",
}
for k, v in pairs(complement.COMPLEMENTS) do
	complement.COMPLEMENTS[k:lower()] = v:lower()
end

--- Returns reverse complement of a sequence, returns empty string if unknown character.
-- @param sequence the sequence to reverse complement
-- @return the reverse complement
-- @usage local s = complement.reverse_complement("ATGC")
function complement.reverse_complement(sequence: string): string
	local s: string = ""
	for i = 1, #sequence do
		if complement.COMPLEMENTS[sequence:sub(i,i)] == nil then return "" end
		s = s .. complement.COMPLEMENTS[sequence:sub(i,i)]
	end
	return s:reverse()
end

return complement
