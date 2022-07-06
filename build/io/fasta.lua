local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local fasta = {Fasta = {}, }






function fasta.parse(input)
   local output = {}
   local identifier = ""
   local sequence = ""
   local start = true
   for line in string.gmatch(input, '[^\r\n]+') do
      local s = line:sub(1, 1)

      if s == ">" then

         if start then
            identifier = line:sub(2, -1)
            start = false
         else
            output[#output + 1] = { identifier = identifier, sequence = sequence }
            identifier = ""
            sequence = ""
         end

      elseif s ~= ">" and s ~= ";" then
         sequence = sequence .. line:gsub("%s+", "")
      end
   end

   output[#output + 1] = { identifier = identifier, sequence = sequence }
   return output
end

return fasta