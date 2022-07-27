local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string



local complement = {}



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





function complement.reverse_complement(sequence)
   local s = ""
   for i = 1, #sequence do
      s = s .. complement.COMPLEMENTS[sequence:sub(i, i)]
   end
   return s:reverse()
end

return complement