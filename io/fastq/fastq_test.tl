local fastq = require("fastq")

local test_case: string = [[@SEQ_ID
GATTTGGGGTTCAAAGCAGTATCGATCAAATAGTAAATCCATTTGTTCAACTCACAGTTT
+
!''*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65
@SEQ_ID_2
AATTTGGGGTTCAAAGCAGTATCGATCAAATAGTAAATCCATTTGTTCAACTCACAGTTT
+
!1'*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65
]]

function test_fastq()
    local fastqs = fastq.parse(test_case)
    assert(#fastqs, 2)
    assert(fastqs[1].identifier, "SEQ_ID")
    assert(fastqs[1].sequence, "GATTTGGGGTTCAAAGCAGTATCGATCAAATAGTAAATCCATTTGTTCAACTCACAGTTT")
    assert(fastqs[1].quality, "!''*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65")
    assert(fastqs[2].identifier, "SEQ_ID_2")
    assert(fastqs[2].sequence, "AATTTGGGGTTCAAAGCAGTATCGATCAAATAGTAAATCCATTTGTTCAACTCACAGTTT")
    assert(fastqs[2].quality, "!1'*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65")
end

test_fastq()
