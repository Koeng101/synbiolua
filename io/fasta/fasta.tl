local record fasta
    record Fasta
        name: string
        sequence: string
    end
end

function fasta.parse(input: string): {fasta.Fasta}
    local output: {fasta.Fasta} = {}
    local name: string = ""
    local sequence: string = ""
    local start:boolean = true
    for line in string.gmatch(input, '[^\r\n]+') do
        -- Check for blank lines
        if line:len() == 0 then
            goto continue
        end
        -- Check for comments
        if line:sub(1,1) == ";" then
            goto continue
        end
        -- Process name lines
        if line:sub(1,1) == ">" then
            -- Process first line
            if start then
                name = line:sub(2,-1)
                start = false
                goto continue
            end
            -- Process other lines
            output[#output+1] = {name = name, sequence = sequence}
            name = ""
            sequence = ""
        end
        -- Process sequence lines
        if line:sub(1,1) ~= ">" then
            sequence = sequence .. line:gsub("%s+", "") -- Remove whitespace from sequence
        end
        ::continue::
    end
    -- final output
    output[#output+1] = {name = name, sequence = sequence}
    return output
end

return fasta
