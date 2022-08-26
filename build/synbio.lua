local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string



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

   function trim(s)
      return (s:gsub("^%s*(.-)%s*$", "%1"))
   end

   function split(s, sep)
      if sep == nil then
         sep = "[^%s]+"
      end
      local l = {}
      for token in s:gmatch(sep) do
         l[#l + 1] = token
      end
      return l
   end

   function deepcopy(obj)
      if type(obj) ~= 'table' then return obj end
      local obj_table = obj
      local res = setmetatable({}, getmetatable(obj))
      for k, v in pairs(obj_table) do res[deepcopy(k)] = deepcopy(v) end
      return res
   end

   function count_leading_spaces(line)
      local i = 0
      for idx = 1, #line do
         if line:sub(idx, idx) == " " then
            i = i + 1
         else
            return i
         end
      end
   end

   function parse_locus(locus_string)
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

   function parse_metadata(metadata)
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

   function parse_references(metadata_data)
      function add_key(reference, reference_key, reference_value)

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

   function get_source_organism(metadata_data)
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
            goto cont
         end
         for _, taxonomy_data in ipairs(split(trim(data_line), "[^;]+")) do
            local taxonomy_data_trimmed = trim(taxonomy_data)

            if taxonomy_data_trimmed:len() > 1 then
               if taxonomy_data_trimmed:sub(-1, -1) == "." then
                  taxonomy_data_trimmed = taxonomy_data_trimmed:sub(1, -2)
               end
               taxonomy[#taxonomy + 1] = taxonomy_data_trimmed
            end
         end
         ::cont::
      end
      return source, organism, taxonomy
   end

   function parse_location(s)
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















   function params_init()
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
         goto continue
      end


      if params.parse_step == "metadata" then

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
               goto continue
            else
               if params.metadata_tag ~= "" then
                  params.genbank.meta.other[params.metadata_tag] = parse_metadata(params.metadata_data)
               end
            end

            params.metadata_tag = trim(split_line[1])
            params.metadata_data = { trim(line:sub(params.metadata_tag:len() + 1)) }
         else
            params.metadata_data[#params.metadata_data + 1] = line
         end
      end


      if params.parse_step == "features" then

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
            goto continue
         end


         local trimmed_line = trim(line)
         if trimmed_line:len() < 1 then
            goto continue
         end


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


      if params.parse_step == "sequence" then
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
      ::continue::
      i = i + 1
   end
   return genbanks
end

function genbank.feature_sequence(self, parent)
   function get_location(location, sequence)
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

return synbio