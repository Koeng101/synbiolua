local fasta = require("fasta")

local test_case: string = [[>hello there
atg
;a comment

>general kenobi
taa
]]

function test_fasta()
    local fastas = fasta.parse(test_case)
    assert(#fastas, 2)
    assert(fastas[1].identifier, "hello there")
    assert(fastas[1].sequence, "atg")
    assert(fastas[2].identifier, "general kenobi")
    assert(fastas[2].sequence, "taa")
end

test_fasta()
