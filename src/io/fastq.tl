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

return fastq
