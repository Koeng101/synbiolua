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
        local s: string = line:sub(1,1)
        -- Process name lines
        if s == ">" then
            -- Process first line
            if start then
                name = line:sub(2,-1)
                start = false
            else
                output[#output+1] = {name = name, sequence = sequence}
                name = ""
                sequence = ""
            end
        -- Process sequence lines
        elseif s ~= ">" and s ~= ";" then
            sequence = sequence .. line:gsub("%s+", "") -- Remove whitespace from sequence
        end
    end
    -- final output
    output[#output+1] = {name = name, sequence = sequence}
    return output
end

return fasta
