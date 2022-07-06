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

return fasta
