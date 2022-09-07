local primers = require("primers")
local complement = require("complement")

-- Known bugs: primers at origin of circular sequence are not detected
local record pcr
  minimal_primer_length: integer
  design_primers_with_overhang: function(string, string, string, number): string, string
  design_primers: function(string, number): string, string
  record Sequence
    sequence: string
    circular: boolean
  end
  simulate_simple: function({Sequence}, {string}, number): {string}
  simulate: function({Sequence}, {string}, number): {string}
end

pcr.minimal_primer_length = 15

function pcr.design_primers_with_overhang(sequence: string, forward_overhang: string, reverse_overhang: string, target_tm: number): string, string
  sequence = sequence:upper()
  -- Walk out over additional nucleotides until melting tm requirements are met
  local additional_nucleotides: integer = 1
  local forward_primer = sequence:sub(1, pcr.minimal_primer_length)
  while primers.melting_temp(forward_primer) < target_tm do
    forward_primer = sequence:sub(1, pcr.minimal_primer_length + additional_nucleotides)
    additional_nucleotides = additional_nucleotides + 1
  end
  additional_nucleotides = 1
  local reverse_primer = complement.reverse_complement(sequence:sub(#sequence - pcr.minimal_primer_length, -1))
  while primers.melting_temp(reverse_primer) < target_tm do
    reverse_primer = complement.reverse_complement(sequence:sub(#sequence - (pcr.minimal_primer_length + additional_nucleotides), -1))
    additional_nucleotides = additional_nucleotides + 1
  end

  -- Add overhangs to primer
  forward_primer = forward_overhang .. forward_primer
  reverse_primer = complement.reverse_complement(reverse_overhang) .. reverse_primer
  return forward_primer, reverse_primer
end

function pcr.design_primers(sequence: string, target_tm: number): string, string
  return pcr.design_primers_with_overhang(sequence, "", "", target_tm)
end

function pcr.simulate_simple(sequences: {pcr.Sequence}, primer_list: {string}, target_tm: number): {string}
  -- Set primers to uppercase and get minimally sized primers
  local minimal_primer_binds: {string} = {}
  local additional_nucleotides: integer
  for idx=1,#primer_list do
    additional_nucleotides = 1
    primer_list[idx] = primer_list[idx]:upper()
    local minimal_primer: string = primer_list[idx]:sub(#primer_list[idx] - pcr.minimal_primer_length, -1)
    local found_minimal_primer: boolean = true
    while primers.melting_temp(minimal_primer) < target_tm do
      local base_idx = #primer_list[idx] - (pcr.minimal_primer_length + additional_nucleotides)
      if base_idx == 0 then
        found_minimal_primer = false
        break
      end
      minimal_primer = primer_list[idx]:sub(base_idx, -1)
      additional_nucleotides = additional_nucleotides + 1
    end
    if found_minimal_primer then
      minimal_primer_binds[idx] = minimal_primer
    else
      minimal_primer_binds[idx] = ""
    end
  end
  
  -- Add generate_pcr_fragments
  local function generate_pcr_fragments(s: string, f: integer, r: integer, forward_primer_indexes: {integer}, reverse_primer_indexes: {integer}): {string}
    local gen_pcr_fragments: {string} = {}
    for _, forward_primer_index in ipairs(forward_primer_indexes) do
      local minimal_primer = minimal_primer_binds[forward_primer_index]
      local full_primer_forward = primer_list[forward_primer_index]
      for _, reverse_primer_index in ipairs(reverse_primer_indexes) do
        local full_primer_reverse = complement.reverse_complement(primer_list[reverse_primer_index])
        local pcr_fragment: string = full_primer_forward:sub(1, #full_primer_forward - #minimal_primer) .. s:sub(f,r) .. full_primer_reverse
        gen_pcr_fragments[#gen_pcr_fragments+1] = pcr_fragment
      end
    end
    return gen_pcr_fragments
  end


  -- Add output pcr_fragments
  local pcr_fragments: {string} = {}

  for _, sequence_record in ipairs(sequences) do
    local sequence = sequence_record.sequence:upper()

    -- First, find the binding sites for each primer
    local forward_locations: {integer: {integer}} = {{}}
    local reverse_locations: {integer: {integer}} = {{}}
    for minimal_primer_idx, minimal_primer in ipairs(minimal_primer_binds) do
      if minimal_primer == "" then break end
      -- Forward locations
      local search_after: integer = 1
      while true do
        local match_start = string.find(sequence, minimal_primer, search_after, true)
        if match_start == nil then break end
        if forward_locations[minimal_primer_idx] == nil then 
          forward_locations[minimal_primer_idx] = {match_start}
        else
          forward_locations[minimal_primer_idx][#forward_locations[minimal_primer_idx]+1] = match_start
        end
        search_after = match_start + 1
      end
      -- Reverse locations
      search_after = 1
      while true do
        local match_start = string.find(sequence, complement.reverse_complement(minimal_primer), search_after, true)
        if match_start == nil then break end
        if reverse_locations[minimal_primer_idx] == nil then reverse_locations[minimal_primer_idx] = {} end
        reverse_locations[minimal_primer_idx][#reverse_locations[minimal_primer_idx]+1] = match_start
        search_after = match_start + 1
      end
    end

    -- We are going to create 2 new tables, essentially inverting forward_locations and reverse_locations, binding locations to different primers
    -- We are also going to create a new array that can be sorted for each of those individual values
    local forward_locations_inverted: {integer: {integer}} = {}
    local forward_locations_indexes: {integer} = {}
    local reverse_locations_inverted: {integer: {integer}} = {}
    local reverse_locations_indexes: {integer} = {}
    for idx, values in pairs(forward_locations) do
      for _, value in ipairs(values) do
        if forward_locations_inverted[value] == nil then forward_locations_inverted[value] = {} end
        forward_locations_inverted[value][#forward_locations_inverted[value]+1] = idx
        forward_locations_indexes[#forward_locations_indexes+1] = value
      end
    end
    for idx, values in pairs(reverse_locations) do
      for _, value in ipairs(values) do
        if reverse_locations_inverted[value] == nil then reverse_locations_inverted[value] = {} end
        reverse_locations_inverted[value][#reverse_locations_inverted[value]+1] = idx
        reverse_locations_indexes[#reverse_locations_indexes+1] = value
      end
    end
    -- Sort both forward_locations_indexes and reverse_locations_indexes
    table.sort(forward_locations_indexes)
    table.sort(reverse_locations_indexes)

    for idx, forward_match_start in ipairs(forward_locations_indexes) do
      -- Check that this isn't the last element in forward_locations_indexes
      if forward_locations_indexes[idx+1] ~= nil then
        -- If this isn't the last element in forward_locations_indexes, then we can select the first reverse_location_index that is less than the next forward_locations_index
        for _, reverse_match_start in ipairs(reverse_locations_indexes) do
          if (forward_match_start < reverse_match_start) and (reverse_match_start < forward_locations_indexes[idx+1]) then
            for _, fragment in ipairs(generate_pcr_fragments(sequence, forward_match_start, reverse_match_start, forward_locations_inverted[forward_match_start], reverse_locations_inverted[reverse_match_start])) do
              pcr_fragments[#pcr_fragments+1] = fragment
            end
              for _, fragment in ipairs(generate_pcr_fragments(sequence, forward_match_start, reverse_match_start, forward_locations_inverted[forward_match_start], reverse_locations_inverted[  reverse_match_start])) do
                pcr_fragments[#pcr_fragments+1] = fragment
              end
            break
          end
        end
      else
        local found_fragment: boolean = false
        for _, reverse_match_start in ipairs(reverse_locations_indexes) do
          if forward_match_start < reverse_match_start then
            for _, fragment in ipairs(generate_pcr_fragments(sequence, forward_match_start, reverse_match_start, forward_locations_inverted[forward_match_start], reverse_locations_inverted[  reverse_match_start])) do
              pcr_fragments[#pcr_fragments+1] = fragment
            end
            found_fragment = true
          end
        end
        -- If the sequence is circular and we haven't found a fragment yet, check the other side of the origin
        if sequence_record.circular then
          for _, reverse_match_start in ipairs(reverse_locations_indexes) do
            if forward_locations_indexes[1] > reverse_match_start then
              -- If either one of these are true, create a new pcrFragment and append to pcrFragments
              local rotated_sequence = sequence:sub(forward_match_start, -1) .. sequence:sub(1, forward_match_start)
              local rotated_forward_location: integer = 1
              local rotated_reverse_location = #sequence:sub(forward_match_start, -1) + reverse_match_start
              for _, fragment in ipairs(generate_pcr_fragments(rotated_sequence, rotated_forward_location, rotated_reverse_location, forward_locations_inverted[forward_match_start], reverse_locations_inverted[reverse_match_start])) do
                pcr_fragments[#pcr_fragments+1] = fragment
              end
            end
          end
        end
      end
    end
  end
  local fragment_set: {string: boolean} = {}
  for _, fragment in ipairs(pcr_fragments) do
    fragment_set[fragment] = true
  end
  pcr_fragments = {}
  for fragment, _ in pairs(fragment_set) do
    pcr_fragments[#pcr_fragments+1] = fragment
  end
  return pcr_fragments
end

function pcr.simulate(sequences: {pcr.Sequence}, primer_list: {string}, target_tm: number): {string}
  local initial_amplification = pcr.simulate_simple(sequences, primer_list, target_tm)
  if #initial_amplification == 0 then error("no amplicons") end
  for _, fragment in ipairs(initial_amplification) do
    primer_list[#primer_list+1] = fragment
  end
  local subsequent_amplification = pcr.simulate_simple(sequences, primer_list, target_tm)
  if #initial_amplification ~= #subsequent_amplification then error("Concatemerization detected in PCR.") end
  return initial_amplification
end

--local gene = "aataattacaccgagataacacatcatggataaaccgatactcaaagattctatgaagctatttgaggcacttggtacgatcaagtcgcgctcaatgtttggtggcttcggacttttcgctgatgaaacgatgtttgcactggttgtgaatgatcaacttcacatacgagcagaccagcaaacttcatctaacttcgagaagcaagggctaaaaccgtacgtttataaaaagcgtggttttccagtcgttactaagtactacgcgatttccgacgacttgtgggaatccagtgaacgcttgatagaagtagcgaagaagtcgttagaacaagccaatttggaaaaaaagcaacaggcaagtagtaagcccgacaggttgaaagacctgcctaacttacgactagcgactgaacgaatgcttaagaaagctggtataaaatcagttgaacaacttgaagagaaaggtgcattgaatgcttacaaagcgatacgtgactctcactccgcaaaagtaagtattgagctactctgggctttagaaggagcgataaacggcacgcactggagcgtcgttcctcaatctcgcagagaagagctggaaaatgcgctttcttaa"
--pcr.simulate({{sequence = gene, circular = false}}, {"aaaccgatactcaaagattctatgaagctatttg", "tcgctacttctatcaagcgttcactggattcccac", "ctcgcagagaagagctggaaaatgcgctttcttaa"}, 55.0)

return pcr
