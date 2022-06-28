local record gb
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
        location_start: integer
        location_end: integer
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
        sequence: string
        gbk_location_string: string
        location: Location
    end
    
    record Genbank
        meta: Meta
        features: {Feature}
        sequence: string
    end

end

-- Genbank molecule types. Mirrors poly's genbank parser.
local genbank_molecule_types = {
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

-- Genbank divisions. Mirrors poly's genbank parser.
local genbank_divisions = {
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


function gb.parse(input: string): {gb.Genbank}
    -- Start helper functions
    function trim(s: string): string -- from PiL2 20.4
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
    
    function split(s: string, sep: any): {string}
        if sep == nil then
            sep = "[^%s]+"
        end
        local l: {string} = {}
        for token in s:gmatch(sep as string) do
            l[#l+1] = token
        end
        return l
    end
    
    function deepcopy(obj:any): any
        if type(obj) ~= 'table' then return obj end
        local obj_table: {any:any} = obj as {any:any}
        local res = setmetatable({} as {any:any}, getmetatable(obj as {any:any}))
        for k, v in pairs(obj_table) do res[deepcopy(k)] = deepcopy(v) end
        return res
    end

    function count_leading_spaces(line: string): integer
        local i: integer = 0
        for idx = 1, #line do
            if line:sub(idx,idx) == " " then
                i = i + 1
            else
                return i
            end
        end
    end
    
    function parse_locus(locus_string: string): gb.Locus
        local locus = gb.Locus
    
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
        for _, genbank_molecule in ipairs(genbank_molecule_types) do
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
        for _, genbank_division in ipairs(genbank_divisions) do
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
    
    function parse_metadata(metadata: {string}): string
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
    
    function parse_references(metadata_data: {string}): gb.Reference
        function add_key(reference: gb.Reference, reference_key: string, reference_value: string): nil
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
        local reference: gb.Reference = {}
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

    function get_source_organism(metadata_data: {string}): string, string, {string}
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

    --function parse_location(s: string): gb.Location
    --    local location: gb.Location = {}
    --    if not s:find("(") then
    --        if not s:find(".") then
    --            position = tonumber(s)
    --            location.location_start = position
    --            location.location_end = position
    --        else
    --            -- to remove FivePrimePartial and ThreePrimePartial indicators from start and end before converting to int.
    --            local start_end_split = split(s, "[^%.]+")
    --            location.location_start = start_end_split[1]
    --            location.location_end = start_end_split[2]
    --        end
    --    else
    --        local first_outer_parentheses = s:find("%(")

    --    end
    --end

    local record ParseParameters
        new_location: boolean
        quote_active: boolean
        attribute: string
        attribute_value: string
        parse_step: string
        genbank: gb.Genbank
        feature: gb.Feature
        features: {gb.Feature}
        metadata_tag: string
        metadata_data: {string}
        genbank_started: boolean
        current_line: string
        previous_line: string
        multi_line_feature: boolean
    end
    function params_init(): ParseParameters
        local params: ParseParameters = {}
        params.new_location = true
        params.parse_step = "metadata"
        params.metadata_tag = ""
        params.genbank = gb.Genbank
        params.genbank_started = false

        -- Init features
        params.attribute_value = ""
        params.feature = gb.Feature
        params.feature.attributes = {}
        params.features = {}

        -- Init Genbank
        params.genbank = gb.Genbank
        params.genbank.meta = gb.Meta
        params.genbank.meta.locus = gb.Locus
        params.genbank.meta.other = {}
        params.genbank.meta.references = {}
        params.genbank.features = {}
        params.genbank.sequence = ""
        return params
    end
    local params: ParseParameters = params_init()

    -- Setup basic parse parameters
    local genbanks: {gb.Genbank} = {}
    local copied_feature: gb.Feature = {}
    local copied_genbank: gb.Genbank = {}
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
                    copied_feature = deepcopy(params.feature) as gb.Feature
                    params.features[#params.features+1] = copied_feature
                    params.attribute_value = ""
                    params.attribute = ""
                    params.feature = gb.Feature
                else
                    copied_feature = deepcopy(params.feature) as gb.Feature
                    params.features[#params.features+1] = copied_feature
                end

                -- add our features to genbank
                for _, feature in ipairs(params.features) do
                    -- location = parse_location TODO
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
                    copied_feature = deepcopy(params.feature) as gb.Feature
                    params.features[#params.features+1] = copied_feature 
                    params.attribute_value = ""
                    params.attribute = ""
                    params.feature = {} 
                    params.feature.attributes = {}
                end

                -- check for empty types
                if params.feature.feature_type ~= nil then
                    copied_feature = deepcopy(params.feature) as gb.Feature
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
                copied_genbank = deepcopy(params.genbank) as gb.Genbank
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

return gb
