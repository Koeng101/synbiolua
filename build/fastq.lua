local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string






local fastq = {Fastq = {}, }











function fastq.parse(input)
   local output = {}
   local identifier = ""
   local sequence = ""
   local quality = ""
   local quality_next = false
   local start = true
   for line in string.gmatch(input, '[^\r\n]+') do
      local s = line:sub(1, 1)

      if s == "@" then

         if start then
            identifier = line:sub(2, -1)
            start = false
         else
            output[#output + 1] = { identifier = identifier, sequence = sequence, quality = quality }
            identifier = ""
            sequence = ""
            quality = ""
         end

      elseif s ~= "@" then
         if quality_next == true then
            quality = line
            quality_next = false
         else
            if s == "+" then
               quality_next = true
            else
               sequence = sequence .. line:gsub("%s+", "")
            end
         end
      end
   end

   output[#output + 1] = { identifier = identifier, sequence = sequence, quality = quality }
   return output
end

return fastq