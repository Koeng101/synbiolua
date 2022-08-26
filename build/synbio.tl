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

--[[---------------------------------------------------------------------------
This module provides a parser for working with FASTA formatted genetic
sequences.

FASTA is a flat text file format developed in 1985 to store nucleotide and
amino acid sequences. It is extremely simple and well-supported across many
languages.
--]]---------------------------------------------------------------------------
local record fasta
    record Fasta
        identifier: string
        sequence: string
    end
end

--- Parses a given FASTA string into a list of FASTA tables.
-- @param input the input FASTA string
-- @return a list of FASTA tables, each containing an identifier and a sequence.
-- @usage local fastas = fasta.parse(">test\natgtaa")
function fasta.parse(input: string): {fasta.Fasta}
    local output: {fasta.Fasta} = {}
    local identifier: string = ""
    local sequence: string = ""
    local start:boolean = true
    for line in string.gmatch(input, '[^\r\n]+') do
        local s: string = line:sub(1,1)
        -- Process identifier lines
        if s == ">" then
            -- Process first line
            if start then
                identifier = line:sub(2,-1)
                start = false
            else
                output[#output+1] = {identifier = identifier, sequence = sequence}
                identifier = ""
                sequence = ""
            end
        -- Process sequence lines
        elseif s ~= ">" and s ~= ";" then
            sequence = sequence .. line:gsub("%s+", "") -- Remove whitespace from sequence
        end
    end
    -- final output
    output[#output+1] = {identifier = identifier, sequence = sequence}
    return output
end

--[[---------------------------------------------------------------------------
This module provides a parser for working with FASTQ formatted sequencing
files.

FASTQ is a flat file format developed by the Wellcome Trust Sanger Institute in
~2000 to store sequencing data along with quality data.
--]]---------------------------------------------------------------------------
local record fastq
    record Fastq
        identifier: string
        sequence: string
        quality: string
    end
end

--- Parses a given FASTQ string into a list of FASTQ tables.
-- @param input the input FASTQ string
-- @return a list of FASTQ tables, each containing an identifier, a sequence, and a quality score.
-- @usage local fastqs = fastq.parse("@SEQ_ID\nATGTAA\n+\n!''*%+")
function fastq.parse(input: string): {fastq.Fastq}
    local output: {fastq.Fastq} = {}
    local identifier: string = ""
    local sequence: string = ""
    local quality: string = ""
    local quality_next:boolean = false
    local start:boolean = true
    for line in string.gmatch(input, '[^\r\n]+') do
        local s: string = line:sub(1,1)
        -- Process identifier lines
        if s == "@" then
            -- Process first line
            if start then
                identifier = line:sub(2,-1)
                start = false
            else
                output[#output+1] = {identifier = identifier, sequence = sequence, quality = quality}
                identifier = ""
                sequence = ""
                quality = ""
            end
        -- Process sequence lines
        elseif s ~= "@" then
            if quality_next == true then
                quality = line
                quality_next = false
            else
                if s == "+" then
                    quality_next = true
                else
                    sequence = sequence .. line:gsub("%s+", "") -- Remove whitespace from sequence
                end
            end
        end
    end
    -- final output
    output[#output+1] = {identifier = identifier, sequence = sequence, quality = quality}
    return output
end

--[[---------------------------------------------------------------------------
This module provides functions for calculating primer melting temperatures.
--]]---------------------------------------------------------------------------
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
--[[---------------------------------------------------------------------------
This module provides a parser for working with GenBank formatted genetic
sequences.

GenBank is a flat text file format developed in the 1980s to annotate genetic
sequences, and has since become the standard for sharing annotated genetic
sequences.
--]]---------------------------------------------------------------------------

local record genbank
    record Locus
        name: string
        molecule_type: string
        genbank_division: string
        modification_date: string
        sequence_coding: string
        circular: boolean
    end
    record Reference
        authors: string
        title: string
        journal: string
        pubmed: string
        remark: string
        range: string
    end
    record Meta
        date: string
        definition: string
        accession: string
        version: string
        keywords: string
        organism: string
        source: string
        taxonomy: {string}
        origin: string
        locus: Locus
        references: {Reference}
        other: {string:string}
        name: string
    end
    record Location
        location_start: number -- integer
        location_end: number -- integer
        complement: boolean
        join: boolean
        five_prime_partial: boolean
        three_prime_partial: boolean
        sub_locations: {Location}
    end
    record Feature
        feature_type: string
        description: string
        attributes: {string:string}
        gbk_location_string: string
        location: Location
        sequence: function(Genbank): string
    end
    record Genbank
        meta: Meta
        features: {Feature}
        sequence: string
    end
    GENBANK_MOLECULE_TYPES: {string}
    GENBANK_DIVISIONS: {string}
end

--- Genbank molecule types; mirrors poly's genbank parser.
-- @table genbank.GENBANK_MOLECULE_TYPES
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

--- Genbank divisions; mirrors poly's genbank parser.
-- @table genbank.GENBANK_DIVISIONS
genbank.GENBANK_DIVISIONS = {
        "PRI", --primate sequences
        "ROD", --rodent sequences
        "MAM", --other mamallian sequences
        "VRT", --other vertebrate sequences
        "INV", --invertebrate sequences
        "PLN", --plant, fungal, and algal sequences
        "BCT", --bacterial sequences
        "VRL", --viral sequences
        "PHG", --bacteriophage sequences
        "SYN", --synthetic sequences
        "UNA", --unannotated sequences
        "EST", --EST sequences (expressed sequence tags)
        "PAT", --patent sequences
        "STS", --STS sequences (sequence tagged sites)
        "GSS", --GSS sequences (genome survey sequences)
        "HTG", --HTG sequences (high-throughput genomic sequences)
        "HTC", --unfinished high-throughput cDNA sequencing
        "ENV", --environmental sampling sequences
}

--- Parses a given genbank string into a list of genbank tables
-- @param input the input genbank string
-- @return a list of genbank tables
-- @usage local plasmids = genbank.parse(plasmids_gbk_string)
function genbank.parse(input: string): {genbank.Genbank}
    -- Start helper functions
    local function trim(s: string): string -- from PiL2 20.4
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
    
    local function split(s: string, sep: any): {string}
        if sep == nil then
            sep = "[^%s]+"
        end
        local l: {string} = {}
        for token in s:gmatch(sep as string) do
            l[#l+1] = token
        end
        return l
    end
    
    local function deepcopy(obj:any): any
        if type(obj) ~= 'table' then return obj end
        local obj_table: {any:any} = obj as {any:any}
        local res = setmetatable({} as {any:any}, getmetatable(obj as {any:any}))
        for k, v in pairs(obj_table) do res[deepcopy(k)] = deepcopy(v) end
        return res
    end

    local function count_leading_spaces(line: string): integer
        local i: integer = 0
        for idx = 1, #line do
            if line:sub(idx,idx) == " " then
                i = i + 1
            else
                return i
            end
        end
    end
    
    local function parse_locus(locus_string: string): genbank.Locus
        local locus = genbank.Locus
    
        local locus_split = split(trim(locus_string))
        local filtered_locus_split: {string} = {}
        for i, _ in ipairs(locus_split) do
            if locus_split[i] ~= "" then
                filtered_locus_split[#filtered_locus_split+1] = locus_split[i]
            end
    
        end
        locus.name = filtered_locus_split[2]
    
        -- We do not trust the locus sequence length, so it is not included.

        -- get molecule type
        for _, genbank_molecule in ipairs(genbank.GENBANK_MOLECULE_TYPES) do
            if locus_string:find(genbank_molecule) then
                locus.molecule_type = genbank_molecule
            end
        end

        -- circularity flag
        locus.circular = false
        if locus_string:find("circular") then
            locus.circular = true
        end

        -- genbank division
        for _, genbank_division in ipairs(genbank.GENBANK_DIVISIONS) do
            for i, locus_split_without_start in ipairs(locus_split) do
                if i > 2 then
                    if locus_split_without_start:find(genbank_division) then
                        locus.genbank_division = genbank_division
                    end
                end
            end
        end

        -- modification date
        local start_date, end_date = locus_string:find("%d%d.%a%a%a.%d%d%d%d")
        locus.modification_date = locus_string:sub(start_date, end_date)

        return locus
    end
    
    local function parse_metadata(metadata: {string}): string
        local output_metadata: string = ""
        if metadata == nil then
            return "."
        end
        if #metadata == 0 then
            return "."
        end
        for _, data in ipairs(metadata) do
            output_metadata = output_metadata .. trim(data) .. " "
        end
        output_metadata = output_metadata:sub(1,#output_metadata-1) -- Remove trailing metadata
        return output_metadata
    end
    
    local function parse_references(metadata_data: {string}): genbank.Reference
        local function add_key(reference: genbank.Reference, reference_key: string, reference_value: string): nil
            -- TODO improve seed using table lookup
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
        local reference: genbank.Reference = {}
        if #metadata_data == 1 then
            error("Got reference with no additional information")
        end

        local range_index = metadata_data[1]:find("%(") -- Need to escape " https://stackoverflow.com/questions/9790688/escaping-strings-for-gsub
        if range_index ~= nil then
            reference.range = metadata_data[1]:sub(range_index,-1)
        end

        local reference_key = split(trim(metadata_data[2]))[1]
        local reference_value = trim(metadata_data[2]:sub(reference_key:len()+3,-1))

        -- Significant amount of magic numbers here. See poly reference.
        for index=3,#metadata_data do
            if metadata_data[index]:sub(4,4) ~= " " then
                add_key(reference, reference_key, reference_value)
                reference_key = trim(split(trim(metadata_data[index]))[1])
                reference_value = trim(metadata_data[index]:sub(reference_key:len()+3,-1))
            else
                reference_value = reference_value .. " " .. trim(metadata_data[index])
            end
        end
        add_key(reference, reference_key, reference_value)
        return reference
    end

    local function get_source_organism(metadata_data: {string}): string, string, {string}
        local source:string = trim(metadata_data[1])
        local organism:string = ""
        local taxonomy:{string} = {}

        local data_line: string
        for iterator=2,#metadata_data do
            data_line = metadata_data[iterator]
            local head_string = split(trim(data_line))[1]
            if head_string == "ORGANISM" then
                local _, index = data_line:find("ORGANISM")
                organism = trim(data_line:sub(index+1,-1))
                goto cont
            end
            for _, taxonomy_data in ipairs(split(trim(data_line), "[^;]+")) do
                local taxonomy_data_trimmed = trim(taxonomy_data)
                -- Taxonomy ends with a ".", which we check for here
                if taxonomy_data_trimmed:len() > 1 then
                    if taxonomy_data_trimmed:sub(-1,-1) == "." then
                        taxonomy_data_trimmed = taxonomy_data_trimmed:sub(1, -2)
                    end
                    taxonomy[#taxonomy+1] = taxonomy_data_trimmed
                end
            end
            ::cont::
        end
        return source, organism, taxonomy
    end

    local function parse_location(s: string): genbank.Location
        local location: genbank.Location = {}
		location.sub_locations = {}
        if not s:find("%(") then
            if not s:find("%.") then
                local position = tonumber(s)
                location.location_start = position
                location.location_end = position
            else
                -- to remove FivePrimePartial and ThreePrimePartial indicators from start and end before converting to int.
                local start_end_split = split(s, "[^%.]+")
                location.location_start = tonumber(start_end_split[1])
                location.location_end = tonumber(start_end_split[2])
            end
        else
            local first_outer_parentheses = s:find("%(")
			local last_outer_parentheses = s:find("%)")
	    	local expression = s:sub(first_outer_parentheses+1, last_outer_parentheses-1)
	    	local command = s:sub(1, first_outer_parentheses-1)
	    	if command == "join" then
			    location.join = true
			    -- This case checks for join(complement(x..x),complement(x..x)), or any more complicated derivatives
			    if expression:find("%(") then
				    local first_inner_parentheses = expression:find("%(")
				    local parentheses_count = 1
				    local comma = 0
				    local i = 2
				    while(parentheses_count > 0) do
					    comma = i
					    if expression:sub(first_inner_parentheses + i) == "(" then parentheses_count = parentheses_count + 1 end
					    if expression:sub(first_inner_parentheses + i) == ")" then parentheses_count = parentheses_count - 1 end
					    i = i + 1
				    end
				    local parse_left_location = parse_location(expression:sub(1, first_inner_parentheses+comma+1))
				    local parse_right_location = parse_location(expression:sub(2+first_inner_parentheses+comma, -1))
				    location.sub_locations[#location.sub_locations+1] = parse_left_location
				    location.sub_locations[#location.sub_locations+1] = parse_right_location
			    else -- This is the default join(x..x,x..x)
					for _, number_range in ipairs(split(expression, "[^,]+")) do
						local join_location = parse_location(number_range)
						location.sub_locations[#location.sub_locations+1] = join_location
					end
			    end
	    	end

			if command == "complement" then
				local sub_location = parse_location(expression)
				sub_location.complement = true
				location.sub_locations[#location.sub_locations+1] = sub_location
        	end
		end

		if s:find("%<") then
			location.five_prime_partial = true
		end
		if s:find("%>") then
			location.three_prime_partial = true
		end

		-- if excess root node then trim node. Maybe should just be handled with second arg?
		if location.location_start == 0 and location.location_end and not location.join and not location.complement then
			location = location.sub_locations[1]
		end
		return location
    end

    local record ParseParameters
        new_location: boolean
        quote_active: boolean
        attribute: string
        attribute_value: string
        parse_step: string
        genbank: genbank.Genbank
        feature: genbank.Feature
        features: {genbank.Feature}
        metadata_tag: string
        metadata_data: {string}
        genbank_started: boolean
        current_line: string
        previous_line: string
        multi_line_feature: boolean
    end
    local function params_init(): ParseParameters
        local params: ParseParameters = {}
        params.new_location = true
        params.parse_step = "metadata"
        params.metadata_tag = ""
        params.genbank = genbank.Genbank
        params.genbank_started = false

        -- Init features
        params.attribute_value = ""
        params.feature = genbank.Feature
        params.feature.attributes = {}
        params.features = {}

        -- Init Genbank
        params.genbank = genbank.Genbank
        params.genbank.meta = genbank.Meta
        params.genbank.meta.locus = genbank.Locus
        params.genbank.meta.other = {}
        params.genbank.meta.references = {}
        params.genbank.features = {}
        params.genbank.sequence = ""
        return params
    end
    local params: ParseParameters = params_init()

    -- Setup basic parse parameters
    local genbanks: {genbank.Genbank} = {}
    local copied_feature: genbank.Feature = {}
    local copied_genbank: genbank.Genbank = {}
    local i: integer = 0

    -- Iterate line by line
    for line in string.gmatch(input,'[^\r\n]+') do
        local split_line: {string} = split(trim(line))

        local previous_line: string = params.current_line
        params.current_line = line
        params.previous_line = previous_line

        -- keep scanning until we find start of first record
        if not params.genbank_started then
            if line:find("LOCUS") then
                params = params_init()
                params.genbank.meta.locus = parse_locus(line)
                params.genbank_started = true
            end
            goto continue
        end

        -- Parse metadata
        if params.parse_step == "metadata" then
            -- Handle empty lines
            if line:len() == 0 then
                error("Empty metadata line on " .. i)
            end

            -- If we are currently reading a line, figure out if it is a new meta line.
            if line:sub(1,1) ~= " " or params.metadata_tag == "FEATURES" then
                -- TODO: The following code can be made far more efficient: http://lua-users.org/wiki/SwitchStatement
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
                    params.genbank.meta.references[#params.genbank.meta.references+1] = parse_references(params.metadata_data)
                elseif params.metadata_tag == "FEATURES" then
                    params.parse_step = "features"

                    -- We know we are now parsing features, so lets initialize our first feature
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
                params.metadata_data = {trim(line:sub(params.metadata_tag:len()+1))}
            else
                params.metadata_data[#params.metadata_data+1] = line
            end
        end

        -- Parse features
        if params.parse_step == "features" then
            -- Switch to sequence parsing
            if line:find("ORIGIN") then
                params.parse_step = "sequence"
                
                -- save our completed attribute / qualifier string to the current feature
                if params.attribute_value ~= nil then
                    params.feature.attributes[params.attribute] = params.attribute_value
                    copied_feature = deepcopy(params.feature) as genbank.Feature
                    params.features[#params.features+1] = copied_feature
                    params.attribute_value = ""
                    params.attribute = ""
                    params.feature = genbank.Feature
                else
                    copied_feature = deepcopy(params.feature) as genbank.Feature
                    params.features[#params.features+1] = copied_feature
                end

                -- add our features to genbank
                for _, feature in ipairs(params.features) do
					feature.location = parse_location(feature.gbk_location_string) 
                    params.genbank.features[#params.genbank.features+1] = feature
                end
                goto continue
            end -- end sequence parsing logic

            -- check if current line contains anything but whitespace
            local trimmed_line: string = trim(line)
            if trimmed_line:len() < 1 then
                goto continue
            end

            -- determine if current line is a new top level feature
            if count_leading_spaces(params.current_line) < count_leading_spaces(params.previous_line) or params.previous_line == "FEATURES" then
                -- save our completed attribute / qualifier to the current feature
                if params.attribute_value ~= "" then
                    params.feature.attributes[params.attribute] = params.attribute_value
                    copied_feature = deepcopy(params.feature) as genbank.Feature
                    params.features[#params.features+1] = copied_feature 
                    params.attribute_value = ""
                    params.attribute = ""
                    params.feature = {} 
                    params.feature.attributes = {}
                end

                -- check for empty types
                if params.feature.feature_type ~= nil then
                    copied_feature = deepcopy(params.feature) as genbank.Feature
                    params.features[#params.features+1] = copied_feature
                    params.feature = {}
                    params.feature.attributes = {}
                end

                -- An initial feature line looks like this: `source          1..2686` with a type separated by its location
                if #split_line < 2 then
                    error("Feature line malformed on line " .. i .. " . Got line: " .. line)
                end
                params.feature.feature_type = trim(split_line[1])
                params.feature.gbk_location_string = trim(split_line[#split_line])
                params.multi_line_feature = false -- without this we can't tell if something is a multiline feature or multiline qualifier

            elseif not params.current_line:find("/") then -- current line is continuation of a feature or qualifier (sub-constituent of a feature)
                -- if it's a continuation of the current feature, add it to the location
                if not params.current_line:find("\"") and (count_leading_spaces(params.current_line) > count_leading_spaces(params.previous_line) or params.multi_line_feature) then
                    params.feature.gbk_location_string = params.feature.gbk_location_string .. trim(line)
                    params.multi_line_feature = true -- without this we can't tell if something is a multiline feature or multiline qualifier
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

        -- Parse sequence
        if params.parse_step == "sequence" then
            if #line < 2 then
                error("Too short line found while parsing genbank sequence on line " .. i .. ". Got line: " .. line)
            elseif line:sub(1,3) == "//" then
                copied_genbank = deepcopy(params.genbank) as genbank.Genbank
                genbanks[#genbanks+1] = copied_genbank
                params.genbank_started = false
                params.genbank.sequence = ""
            else
                params.genbank.sequence = params.genbank.sequence .. line:gsub("[0-9]-[%s+]","")
            end
        end
        ::continue::
        i = i + 1
    end
    return genbanks
end

function genbank.feature_sequence(self: genbank.Feature, parent: genbank.Genbank): string
	local function get_location(location: genbank.Location, sequence: string): string
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

--[[---------------------------------------------------------------------------
The codon module provides functions to work with codon tables, including the
translation of DNA/RNA into protein and the codon optimization (given a certain
organism's codon table) of a protein sequence into a nucleotide sequence.
]]-----------------------------------------------------------------------------
local record codon
    record Codon
        triplet: string
        weight: number
    end
    record AminoAcid
        letter: string
        codons: {Codon}
    end

    record CodonTable
        start_codons: {Codon}
        amino_acids: {AminoAcid}
    end

    CODON_TABLES: {number:{string, string}}
end

--[[---------------------------------------------------------------------------
July, 06, 2022

Codon table generation begins here.

Different organisms use different codons to represent different amino acids.
NCBI publishes this weird data format for developers to use for generating
codon tables and mapping codons for different organisms. All of the following
codon tables are experimentally validated.

]]-----------------------------------------------------------------------------

--- codon.CODON_TABLES are current NCBI sanctioned codon tables with their respective numbers.
-- @field 1 Translation table 1
-- @field 2 Translation table 2
-- @field 3 Translation table 3
-- @field 4 Translation table 4
-- @field 5 Translation table 5
-- @field 6 Translation table 6
-- @field 7 Translation table 7
-- @field 8 Translation table 8
-- @field 9 Translation table 9
-- @field 10 Translation table 10
-- @field 11 Translation table 11
-- @field 12 Translation table 12
-- @field 13 Translation table 13
-- @field 14 Translation table 14
-- @field 15 Translation table 15
-- @field 16 Translation table 16
-- @field 17 Translation table 17
-- @field 18 Translation table 18
-- @field 19 Translation table 19
-- @field 20 Translation table 20
-- @field 21 Translation table 21
-- @field 22 Translation table 22
-- @field 23 Translation table 23
-- @field 24 Translation table 24
-- @field 25 Translation table 25
-- @field 26 Translation table 26
-- @field 27 Translation table 27
-- @field 28 Translation table 28
-- @field 29 Translation table 29
-- @field 30 Translation table 30
-- @field 31 Translation table 31
-- @field 32 Translation table 32
-- @field 33 Translation table 33
-- @table CODON_TABLES
codon.CODON_TABLES = {
    [1] = {"FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**--*----M---------------M----------------------------"},
    [2] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG", "----------**--------------------MMMM----------**---M------------"},
    [3] = {"FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**----------------------MM---------------M------------"},
    [4] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--MM------**-------M------------MMMM---------------M------------"},
    [5] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG", "---M------**--------------------MMMM---------------M------------"},
    [6] = {"FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------"},
    [9] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG", "----------**-----------------------M---------------M------------"},
    [10] = {"FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**-----------------------M----------------------------"},
    [11] = {"FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**--*----M------------MMMM---------------M------------"},
    [12] = {"FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**--*----M---------------M----------------------------"},
    [13] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG", "---M------**----------------------MM---------------M------------"},
    [14] = {"FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG", "-----------*-----------------------M----------------------------"},
    [16] = {"FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------*---*--------------------M----------------------------"},
    [21] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG", "----------**-----------------------M---------------M------------"},
    [22] = {"FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "------*---*---*--------------------M----------------------------"},
    [23] = {"FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--*-------**--*-----------------M--M---------------M------------"},
    [24] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG", "---M------**-------M---------------M---------------M------------"},
    [25] = {"FFLLSSSSYY**CCGWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**-----------------------M---------------M------------"},
    [26] = {"FFLLSSSSYY**CC*WLLLAPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**--*----M---------------M----------------------------"},
    [27] = {"FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------"},
    [28] = {"FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**--*--------------------M----------------------------"},
    [29] = {"FFLLSSSSYYYYCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------"},
    [30] = {"FFLLSSSSYYEECC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------"},
    [31] = {"FFLLSSSSYYEECCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**-----------------------M----------------------------"},
    [33] = {"FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG", "---M-------*-------M---------------M---------------M------------"},
}


--- Generates a codon table from a list of amino acids and a list of start codons, given in the standard NCBI codon table format.
-- @param amino_acids the amino acid string
-- @param starts the start codon string
-- @return a codon table
-- @usage local ct = codon.ncbi_standard_to_codon_table("FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**--*----M------------MMMM---------------M------------")
function codon.ncbi_standard_to_codon_table(amino_acids: string, starts:string): codon.CodonTable 
    local base1 = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG"
    local base2 = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG"
    local base3 = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG"
    local amino_acid_table: {string:{codon.Codon}} = {}
    local ct: codon.CodonTable = {}
    ct.start_codons = {}
    for i = 1, #amino_acids do
        local triplet: string = base1:sub(i,i) .. base2:sub(i,i) .. base3:sub(i,i)
        -- Generate start_codons
        if starts:sub(i,i) == "M" then
            local start_codon: codon.Codon
            start_codon = {triplet = triplet, weight = 0}
            ct.start_codons[#ct.start_codons+1] = start_codon
        end
        -- Generate amino_acids
        local amino_acid = amino_acids:sub(i,i)
        if amino_acid_table[amino_acid] == nil then
            amino_acid_table[amino_acid] = {{triplet = triplet, weight = 0}}
        else
            amino_acid_table[amino_acid][#amino_acid_table[amino_acid]+1] = {triplet = triplet, weight = 0}
        end
    end

    -- Fill in codon table
    ct.amino_acids = {}
    for amino_acid, codons in pairs(amino_acid_table) do
        ct.amino_acids[#ct.amino_acids+1] = {letter = amino_acid, codons = codons}
    end
    return ct
end

--- Generates a new codon table given an NCBI codon table number.
-- @param table_number the table number
-- @return a codon table
-- @usage local ct = codon.new_table(11)
function codon.new_table(table_number: number): codon.CodonTable
    return codon.ncbi_standard_to_codon_table(codon.CODON_TABLES[table_number][1], codon.CODON_TABLES[table_number][2])
end
--[[---------------------------------------------------------------------------
July, 21, 2022

Codon table filling begins here.

In order to be useful for optimization or fixing, codon tables need to be
filled with data.

]]-----------------------------------------------------------------------------

--[[---------------------------------------------------------------------------
July, 21, 2022

Compromise + Add codon table begins here.

## Compromise tables
If you want to codon optimize a protein for two or more organisms, you will
want a codon table that works for both organisms. Compromise codon tables
standardize codon counts so the weights are equal between both organisms.
Then, they are added together. There is also a variable for removing rare
codons, which is essential to get good protein yield in many organisms(however,
this feature makes compromise tables lossy).

]]-----------------------------------------------------------------------------

--[[---------------------------------------------------------------------------
The synbio module contains all of synbiolua in a single module to enable
embedding into larger programs. All other modules are built into synbio.
]]-----------------------------------------------------------------------------


local record synbio
    version: string
    complement: complement
    fasta: fasta
    fastq: fastq
    primers: primers
    genbank: genbank
    codon: codon
end

synbio.version = "0.0.1"
synbio.complement = complement
synbio.fasta = fasta
synbio.fastq = fastq
synbio.primers = primers
synbio.genbank = genbank
synbio.codon = codon

return synbio
