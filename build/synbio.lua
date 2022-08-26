local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table



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
      if complement.COMPLEMENTS[sequence:sub(i, i)] == nil then return "" end
      s = s .. complement.COMPLEMENTS[sequence:sub(i, i)]
   end
   return s:reverse()
end

local json = {}










local encode

local escape_char_map = {
   ["\\"] = "\\",
   ["\""] = "\"",
   ["\b"] = "b",
   ["\f"] = "f",
   ["\n"] = "n",
   ["\r"] = "r",
   ["\t"] = "t",
}

local escape_char_map_inv = { ["/"] = "/" }
for k, v in pairs(escape_char_map) do
   escape_char_map_inv[v] = k
end

local function escape_char(c)
   return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end

local function encode_nil(_)
   return "null"
end

local function encode_table(val, stack)
   local res = {}
   stack = stack or {}


   if stack[val] then error("circular reference") end
   stack[val] = true

   if rawget(val, 1) ~= nil or next(val) == nil then

      local n = 0
      for k in pairs(val) do
         if type(k) ~= "number" then
            error("invalid table: mixed or invalid key types")
         end
         n = n + 1
      end
      if n ~= #val then
         error("invalid table: sparse array")
      end

      for _, v in ipairs(val) do
         table.insert(res, encode(v, stack))
      end
      stack[val] = nil
      return "[" .. table.concat(res, ",") .. "]"

   else

      for k, v in pairs(val) do
         if type(k) ~= "string" then
            error("invalid table: mixed or invalid key types")
         end
         local stack_value = encode(v, stack)
         if stack_value ~= nil then
            table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
         end
      end
      stack[val] = nil
      return "{" .. table.concat(res, ",") .. "}"
   end
end

local function encode_string(val)
   return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)

   if val ~= val or val <= -math.huge or val >= math.huge then
      error("unexpected number value '" .. tostring(val) .. "'")
   end
   return string.format("%.14g", val)
end


local type_func_map = {
   ["nil"] = encode_nil,
   ["table"] = encode_table,
   ["string"] = encode_string,
   ["number"] = encode_number,
   ["boolean"] = tostring,
}

encode = function(val, stack)
   local t = type(val)
   local f = type_func_map[t]
   if f then
      return f(val, stack)
   end
   if t ~= "function" then
      error("unexpected type '" .. t .. "'")
   end
end

function json.encode(val)
   return encode(val)
end

local parse

local function create_set(...)
   local res = {}
   for i = 1, select("#", ...) do
      res[select(i, ...)] = true
   end
   return res
end

local space_chars = create_set(" ", "\t", "\r", "\n")
local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals = create_set("true", "false", "null")

local literal_map = {
   ["true"] = true,
   ["false"] = false,
   ["null"] = nil,
}


local function next_char(str, idx, set, negate)
   for i = idx, #str do
      if set[str:sub(i, i)] ~= negate then
         return i
      end
   end
   return #str + 1
end


local function decode_error(str, idx, msg)
   local line_count = 1
   local col_count = 1
   for i = 1, idx - 1 do
      col_count = col_count + 1
      if str:sub(i, i) == "\n" then
         line_count = line_count + 1
         col_count = 1
      end
   end
   error(string.format("%s at line %d col %d", msg, line_count, col_count))
end


local function codepoint_to_utf8(n)

   local f = math.floor
   if n <= 0x7f then
      return string.char(n)
   elseif n <= 0x7ff then
      return string.char(f(n / 64) + 192, n % 64 + 128)
   elseif n <= 0xffff then
      return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
   elseif n <= 0x10ffff then
      return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
      f(n % 4096 / 64) + 128, n % 64 + 128)
   end
   error(string.format("invalid unicode codepoint '%x'", n))
end


local function parse_unicode_escape(s)
   local n1 = tonumber(s:sub(1, 4), 16)
   local n2 = tonumber(s:sub(7, 10), 16)

   if n2 then
      return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
   else
      return codepoint_to_utf8(n1)
   end
end


local function parse_string(str, i)
   local res = ""
   local j = i + 1
   local k = j

   while j <= #str do
      local x = str:byte(j)

      if x < 32 then
         decode_error(str, j, "control character in string")

      elseif x == 92 then
         res = res .. str:sub(k, j - 1)
         j = j + 1
         local c = str:sub(j, j)
         if c == "u" then
            local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1) or
            str:match("^%x%x%x%x", j + 1) or
            decode_error(str, j - 1, "invalid unicode escape in string")
            res = res .. parse_unicode_escape(hex)
            j = j + #hex
         else
            if not escape_chars[c] then
               decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
            end
            res = res .. escape_char_map_inv[c]
         end
         k = j + 1

      elseif x == 34 then
         res = res .. str:sub(k, j - 1)
         return res, j + 1
      end

      j = j + 1
   end

   decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
   local x = next_char(str, i, delim_chars)
   local s = str:sub(i, x - 1)
   local n = tonumber(s)
   if not n then
      decode_error(str, i, "invalid number '" .. s .. "'")
   end
   return n, x
end


local function parse_literal(str, i)
   local x = next_char(str, i, delim_chars)
   local word = str:sub(i, x - 1)
   if not literals[word] then
      decode_error(str, i, "invalid literal '" .. word .. "'")
   end
   return literal_map[word], x
end


local function parse_array(str, i)
   local res = {}
   local n = 1
   i = i + 1
   while 1 do
      local x = {}
      i = next_char(str, i, space_chars, true)

      if str:sub(i, i) == "]" then
         i = i + 1
         break
      end

      x, i = parse(str, i)
      res[n] = x
      n = n + 1

      i = next_char(str, i, space_chars, true)
      local chr = str:sub(i, i)
      i = i + 1
      if chr == "]" then break end
      if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
   end
   return res, i
end


local function parse_object(str, i)
   local res = {}
   i = i + 1
   while 1 do
      local key
      local val
      i = next_char(str, i, space_chars, true)

      if str:sub(i, i) == "}" then
         i = i + 1
         break
      end

      if str:sub(i, i) ~= '"' then
         decode_error(str, i, "expected string for key")
      end
      key, i = parse(str, i)

      i = next_char(str, i, space_chars, true)
      if str:sub(i, i) ~= ":" then
         decode_error(str, i, "expected ':' after key")
      end
      i = next_char(str, i + 1, space_chars, true)

      val, i = parse(str, i)

      res[key] = val

      i = next_char(str, i, space_chars, true)
      local chr = str:sub(i, i)
      i = i + 1
      if chr == "}" then break end
      if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
   end
   return res, i
end


local char_func_map = {
   ['"'] = parse_string,
   ["0"] = parse_number,
   ["1"] = parse_number,
   ["2"] = parse_number,
   ["3"] = parse_number,
   ["4"] = parse_number,
   ["5"] = parse_number,
   ["6"] = parse_number,
   ["7"] = parse_number,
   ["8"] = parse_number,
   ["9"] = parse_number,
   ["-"] = parse_number,
   ["t"] = parse_literal,
   ["f"] = parse_literal,
   ["n"] = parse_literal,
   ["["] = parse_array,
   ["{"] = parse_object,
}

parse = function(str, idx)
   local chr = str:sub(idx, idx)
   local f = char_func_map[chr]
   if f then
      local tbl, newIdx = f(str, idx)
      return tbl, newIdx
   end
   decode_error(str, idx, "unexpected character '" .. chr .. "'")
end

function json.decode(str)
   if type(str) ~= "string" then
      error("expected argument of type string, got " .. type(str))
   end
   local res, idx = parse(str, next_char(str, 1, space_chars, true))
   idx = next_char(str, idx, space_chars, true)
   if idx <= #str then
      decode_error(str, idx, "trailing garbage")
   end
   return res
end









local fasta = {Fasta = {}, }










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
   sequence = sequence:gsub("[^ATGC]", "")
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









local genbank = {Locus = {}, Reference = {}, Meta = {}, Location = {}, Feature = {}, Genbank = {}, }






























































genbank.GENBANK_MOLECULE_TYPES = {
   "DNA",
   "genomic DNA",
   "genomic RNA",
   "mRNA",
   "tRNA",
   "rRNA",
   "other RNA",
   "other DNA",
   "transcribed RNA",
   "viral cRNA",
   "unassigned DNA",
   "unassigned RNA",
}



genbank.GENBANK_DIVISIONS = {
   "PRI",
   "ROD",
   "MAM",
   "VRT",
   "INV",
   "PLN",
   "BCT",
   "VRL",
   "PHG",
   "SYN",
   "UNA",
   "EST",
   "PAT",
   "STS",
   "GSS",
   "HTG",
   "HTC",
   "ENV",
}





function genbank.parse(input)

   local function trim(s)
      return (s:gsub("^%s*(.-)%s*$", "%1"))
   end

   local function split(s, sep)
      if sep == nil then
         sep = "[^%s]+"
      end
      local l = {}
      for token in s:gmatch(sep) do
         l[#l + 1] = token
      end
      return l
   end

   local function deepcopy(obj)
      if type(obj) ~= 'table' then return obj end
      local obj_table = obj
      local res = setmetatable({}, getmetatable(obj))
      for k, v in pairs(obj_table) do res[deepcopy(k)] = deepcopy(v) end
      return res
   end

   local function count_leading_spaces(line)
      local i = 0
      for idx = 1, #line do
         if line:sub(idx, idx) == " " then
            i = i + 1
         else
            return i
         end
      end
   end

   local function parse_locus(locus_string)
      local locus = genbank.Locus

      local locus_split = split(trim(locus_string))
      local filtered_locus_split = {}
      for i, _ in ipairs(locus_split) do
         if locus_split[i] ~= "" then
            filtered_locus_split[#filtered_locus_split + 1] = locus_split[i]
         end

      end
      locus.name = filtered_locus_split[2]




      for _, genbank_molecule in ipairs(genbank.GENBANK_MOLECULE_TYPES) do
         if locus_string:find(genbank_molecule) then
            locus.molecule_type = genbank_molecule
         end
      end


      locus.circular = false
      if locus_string:find("circular") then
         locus.circular = true
      end


      for _, genbank_division in ipairs(genbank.GENBANK_DIVISIONS) do
         for i, locus_split_without_start in ipairs(locus_split) do
            if i > 2 then
               if locus_split_without_start:find(genbank_division) then
                  locus.genbank_division = genbank_division
               end
            end
         end
      end


      local start_date, end_date = locus_string:find("%d%d.%a%a%a.%d%d%d%d")
      locus.modification_date = locus_string:sub(start_date, end_date)

      return locus
   end

   local function parse_metadata(metadata)
      local output_metadata = ""
      if metadata == nil then
         return "."
      end
      if #metadata == 0 then
         return "."
      end
      for _, data in ipairs(metadata) do
         output_metadata = output_metadata .. trim(data) .. " "
      end
      output_metadata = output_metadata:sub(1, #output_metadata - 1)
      return output_metadata
   end

   local function parse_references(metadata_data)
      local function add_key(reference, reference_key, reference_value)

         if reference_key == "AUTHORS" then
            reference.authors = reference_value
         elseif reference_key == "TITLE" then
            reference.title = reference_value
         elseif reference_key == "JOURNAL" then
            reference.journal = reference_value
         elseif reference_key == "PUBMED" then
            reference.pubmed = reference_value
         elseif reference_key == "REMARK" then
            reference.remark = reference_value
         else
            error("Reference_key not in  [AUTHORS, TITLE, JOURNAL, PUBMED, REMARK]. Got: " .. reference_key)
         end
      end
      local reference = {}
      if #metadata_data == 1 then
         error("Got reference with no additional information")
      end

      local range_index = metadata_data[1]:find("%(")
      if range_index ~= nil then
         reference.range = metadata_data[1]:sub(range_index, -1)
      end

      local reference_key = split(trim(metadata_data[2]))[1]
      local reference_value = trim(metadata_data[2]:sub(reference_key:len() + 3, -1))


      for index = 3, #metadata_data do
         if metadata_data[index]:sub(4, 4) ~= " " then
            add_key(reference, reference_key, reference_value)
            reference_key = trim(split(trim(metadata_data[index]))[1])
            reference_value = trim(metadata_data[index]:sub(reference_key:len() + 3, -1))
         else
            reference_value = reference_value .. " " .. trim(metadata_data[index])
         end
      end
      add_key(reference, reference_key, reference_value)
      return reference
   end

   local function get_source_organism(metadata_data)
      local source = trim(metadata_data[1])
      local organism = ""
      local taxonomy = {}

      local data_line
      for iterator = 2, #metadata_data do
         data_line = metadata_data[iterator]
         local head_string = split(trim(data_line))[1]
         if head_string == "ORGANISM" then
            local _, index = data_line:find("ORGANISM")
            organism = trim(data_line:sub(index + 1, -1))
         else
            for _, taxonomy_data in ipairs(split(trim(data_line), "[^;]+")) do
               local taxonomy_data_trimmed = trim(taxonomy_data)

               if taxonomy_data_trimmed:len() > 1 then
                  if taxonomy_data_trimmed:sub(-1, -1) == "." then
                     taxonomy_data_trimmed = taxonomy_data_trimmed:sub(1, -2)
                  end
                  taxonomy[#taxonomy + 1] = taxonomy_data_trimmed
               end
            end
         end
      end
      return source, organism, taxonomy
   end

   local function parse_location(s)
      local location = {}
      location.sub_locations = {}
      if not s:find("%(") then
         if not s:find("%.") then
            local position = tonumber(s)
            location.location_start = position
            location.location_end = position
         else

            local start_end_split = split(s, "[^%.]+")
            location.location_start = tonumber(start_end_split[1])
            location.location_end = tonumber(start_end_split[2])
         end
      else
         local first_outer_parentheses = s:find("%(")
         local last_outer_parentheses = s:find("%)")
         local expression = s:sub(first_outer_parentheses + 1, last_outer_parentheses - 1)
         local command = s:sub(1, first_outer_parentheses - 1)
         if command == "join" then
            location.join = true

            if expression:find("%(") then
               local first_inner_parentheses = expression:find("%(")
               local parentheses_count = 1
               local comma = 0
               local i = 2
               while (parentheses_count > 0) do
                  comma = i
                  if expression:sub(first_inner_parentheses + i) == "(" then parentheses_count = parentheses_count + 1 end
                  if expression:sub(first_inner_parentheses + i) == ")" then parentheses_count = parentheses_count - 1 end
                  i = i + 1
               end
               local parse_left_location = parse_location(expression:sub(1, first_inner_parentheses + comma + 1))
               local parse_right_location = parse_location(expression:sub(2 + first_inner_parentheses + comma, -1))
               location.sub_locations[#location.sub_locations + 1] = parse_left_location
               location.sub_locations[#location.sub_locations + 1] = parse_right_location
            else
               for _, number_range in ipairs(split(expression, "[^,]+")) do
                  local join_location = parse_location(number_range)
                  location.sub_locations[#location.sub_locations + 1] = join_location
               end
            end
         end

         if command == "complement" then
            local sub_location = parse_location(expression)
            sub_location.complement = true
            location.sub_locations[#location.sub_locations + 1] = sub_location
         end
      end

      if s:find("%<") then
         location.five_prime_partial = true
      end
      if s:find("%>") then
         location.three_prime_partial = true
      end


      if location.location_start == 0 and location.location_end and not location.join and not location.complement then
         location = location.sub_locations[1]
      end
      return location
   end

   local ParseParameters = {}















   local function params_init()
      local params = {}
      params.new_location = true
      params.parse_step = "metadata"
      params.metadata_tag = ""
      params.genbank = genbank.Genbank
      params.genbank_started = false


      params.attribute_value = ""
      params.feature = genbank.Feature
      params.feature.attributes = {}
      params.features = {}


      params.genbank = genbank.Genbank
      params.genbank.meta = genbank.Meta
      params.genbank.meta.locus = genbank.Locus
      params.genbank.meta.other = {}
      params.genbank.meta.references = {}
      params.genbank.features = {}
      params.genbank.sequence = ""
      return params
   end
   local params = params_init()


   local genbanks = {}
   local copied_feature = {}
   local copied_genbank = {}
   local i = 0
   local continue = false


   for line in string.gmatch(input, '[^\r\n]+') do
      local split_line = split(trim(line))

      local previous_line = params.current_line
      params.current_line = line
      params.previous_line = previous_line


      if not params.genbank_started then
         if line:find("LOCUS") then
            params = params_init()
            params.genbank.meta.locus = parse_locus(line)
            params.genbank_started = true
         end
         continue = true
      end


      if params.parse_step == "metadata" and not continue then

         if line:len() == 0 then
            error("Empty metadata line on " .. i)
         end


         if line:sub(1, 1) ~= " " or params.metadata_tag == "FEATURES" then

            if params.metadata_tag == "DEFINITION" then
               params.genbank.meta.definition = parse_metadata(params.metadata_data)
            elseif params.metadata_tag == "ACCESSION" then
               params.genbank.meta.accession = parse_metadata(params.metadata_data)
            elseif params.metadata_tag == "VERSION" then
               params.genbank.meta.version = parse_metadata(params.metadata_data)
            elseif params.metadata_tag == "KEYWORDS" then
               params.genbank.meta.keywords = parse_metadata(params.metadata_data)
            elseif params.metadata_tag == "SOURCE" then
               params.genbank.meta.source, params.genbank.meta.organism, params.genbank.meta.taxonomy = get_source_organism(params.metadata_data)
            elseif params.metadata_tag == "REFERENCE" then
               params.genbank.meta.references[#params.genbank.meta.references + 1] = parse_references(params.metadata_data)
            elseif params.metadata_tag == "FEATURES" then
               params.parse_step = "features"


               params.feature.feature_type = trim(split_line[1])
               params.feature.gbk_location_string = trim(split_line[#split_line])
               params.new_location = true
               continue = true
            else
               if not continue then
                  if params.metadata_tag ~= "" then
                     params.genbank.meta.other[params.metadata_tag] = parse_metadata(params.metadata_data)
                  end
               end
            end
            if not continue then
               params.metadata_tag = trim(split_line[1])
               params.metadata_data = { trim(line:sub(params.metadata_tag:len() + 1)) }
            end
         else
            params.metadata_data[#params.metadata_data + 1] = line
         end
      end


      if params.parse_step == "features" and not continue then
         local trimmed_line

         if line:find("ORIGIN") then
            params.parse_step = "sequence"


            if params.attribute_value ~= nil then
               params.feature.attributes[params.attribute] = params.attribute_value
               copied_feature = deepcopy(params.feature)
               params.features[#params.features + 1] = copied_feature
               params.attribute_value = ""
               params.attribute = ""
               params.feature = genbank.Feature
            else
               copied_feature = deepcopy(params.feature)
               params.features[#params.features + 1] = copied_feature
            end


            for _, feature in ipairs(params.features) do
               feature.location = parse_location(feature.gbk_location_string)
               params.genbank.features[#params.genbank.features + 1] = feature
            end
            continue = true
         else

            trimmed_line = trim(line)
            if trimmed_line:len() < 1 then
               continue = true
            end
         end

         if not continue then

            if count_leading_spaces(params.current_line) < count_leading_spaces(params.previous_line) or params.previous_line == "FEATURES" then

               if params.attribute_value ~= "" then
                  params.feature.attributes[params.attribute] = params.attribute_value
                  copied_feature = deepcopy(params.feature)
                  params.features[#params.features + 1] = copied_feature
                  params.attribute_value = ""
                  params.attribute = ""
                  params.feature = {}
                  params.feature.attributes = {}
               end


               if params.feature.feature_type ~= nil then
                  copied_feature = deepcopy(params.feature)
                  params.features[#params.features + 1] = copied_feature
                  params.feature = {}
                  params.feature.attributes = {}
               end


               if #split_line < 2 then
                  error("Feature line malformed on line " .. i .. " . Got line: " .. line)
               end
               params.feature.feature_type = trim(split_line[1])
               params.feature.gbk_location_string = trim(split_line[#split_line])
               params.multi_line_feature = false

            elseif not params.current_line:find("/") then

               if not params.current_line:find("\"") and (count_leading_spaces(params.current_line) > count_leading_spaces(params.previous_line) or params.multi_line_feature) then
                  params.feature.gbk_location_string = params.feature.gbk_location_string .. trim(line)
                  params.multi_line_feature = true
               else
                  local remove_attribute_value_quotes = trimmed_line:gsub("\"", "")
                  params.attribute_value = params.attribute_value .. remove_attribute_value_quotes
               end
            elseif params.current_line:find("/") then
               if params.attribute_value ~= "" then
                  params.feature.attributes[params.attribute] = params.attribute_value
               end
               params.attribute_value = ""
               local split_attribute = split(line, "[^=]+")
               local trimmed_space_attribute = trim(split_attribute[1])
               local removed_forward_slash_attribute = trimmed_space_attribute:gsub("/", "")

               params.attribute = removed_forward_slash_attribute
               params.attribute_value = split_attribute[2]:gsub("\"", "")

               params.multi_line_feature = false
            end
         end
      end


      if params.parse_step == "sequence" and not continue then
         if #line < 2 then
            error("Too short line found while parsing genbank sequence on line " .. i .. ". Got line: " .. line)
         elseif line:sub(1, 3) == "//" then
            copied_genbank = deepcopy(params.genbank)
            genbanks[#genbanks + 1] = copied_genbank
            params.genbank_started = false
            params.genbank.sequence = ""
         else
            params.genbank.sequence = params.genbank.sequence .. line:gsub("[0-9]-[%s+]", "")
         end
      end
      continue = false
      i = i + 1
   end
   return genbanks
end

function genbank.feature_sequence(self, parent)
   local function get_location(location, sequence)
      local seq = ""
      if #location.sub_locations == 0 then
         seq = sequence:sub(location.location_start, location.location_end):upper()
      else
         for _, sub_location in ipairs(location.sub_locations) do
            seq = seq .. get_location(sub_location, sequence)
         end
      end
      if location.complement then
         seq = complement.reverse_complement(seq)
      end
      return seq
   end
   return get_location(self.location, parent.sequence)
end







function genbank.from_json(str)
   return json.decode(str)
end

function genbank.to_json(self)
   return json.encode(self)
end






local codon = {Codon = {}, AminoAcid = {}, CodonTable = {}, }
































































codon.CODON_TABLES = {
   [1] = { "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**--*----M---------------M----------------------------" },
   [2] = { "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG", "----------**--------------------MMMM----------**---M------------" },
   [3] = { "FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**----------------------MM---------------M------------" },
   [4] = { "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--MM------**-------M------------MMMM---------------M------------" },
   [5] = { "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG", "---M------**--------------------MMMM---------------M------------" },
   [6] = { "FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------" },
   [9] = { "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG", "----------**-----------------------M---------------M------------" },
   [10] = { "FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**-----------------------M----------------------------" },
   [11] = { "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**--*----M------------MMMM---------------M------------" },
   [12] = { "FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**--*----M---------------M----------------------------" },
   [13] = { "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG", "---M------**----------------------MM---------------M------------" },
   [14] = { "FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG", "-----------*-----------------------M----------------------------" },
   [16] = { "FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------*---*--------------------M----------------------------" },
   [21] = { "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG", "----------**-----------------------M---------------M------------" },
   [22] = { "FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "------*---*---*--------------------M----------------------------" },
   [23] = { "FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--*-------**--*-----------------M--M---------------M------------" },
   [24] = { "FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG", "---M------**-------M---------------M---------------M------------" },
   [25] = { "FFLLSSSSYY**CCGWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**-----------------------M---------------M------------" },
   [26] = { "FFLLSSSSYY**CC*WLLLAPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**--*----M---------------M----------------------------" },
   [27] = { "FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------" },
   [28] = { "FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**--*--------------------M----------------------------" },
   [29] = { "FFLLSSSSYYYYCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------" },
   [30] = { "FFLLSSSSYYEECC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------" },
   [31] = { "FFLLSSSSYYEECCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**-----------------------M----------------------------" },
   [33] = { "FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG", "---M-------*-------M---------------M---------------M------------" },
}







function codon.ncbi_standard_to_codon_table(amino_acids, starts)
   local base1 = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG"
   local base2 = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG"
   local base3 = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG"
   local amino_acid_table = {}
   local ct = {}
   ct.start_codons = {}
   for i = 1, #amino_acids do
      local triplet = base1:sub(i, i) .. base2:sub(i, i) .. base3:sub(i, i)

      if starts:sub(i, i) == "M" then
         local start_codon
         start_codon = { triplet = triplet, weight = 0 }
         ct.start_codons[#ct.start_codons + 1] = start_codon
      end

      local amino_acid = amino_acids:sub(i, i)
      if amino_acid_table[amino_acid] == nil then
         amino_acid_table[amino_acid] = { { triplet = triplet, weight = 0 } }
      else
         amino_acid_table[amino_acid][#amino_acid_table[amino_acid] + 1] = { triplet = triplet, weight = 0 }
      end
   end


   ct.amino_acids = {}
   for amino_acid, codons in pairs(amino_acid_table) do
      ct.amino_acids[#ct.amino_acids + 1] = { letter = amino_acid, codons = codons }
   end
   return ct
end





function codon.new_table(table_number)
   return codon.ncbi_standard_to_codon_table(codon.CODON_TABLES[table_number][1], codon.CODON_TABLES[table_number][2])
end































local synbio = {}










synbio.version = "0.0.1"
synbio.complement = complement
synbio.fasta = fasta
synbio.fastq = fastq
synbio.primers = primers
synbio.genbank = genbank
synbio.codon = codon
synbio.json = json

return synbio
