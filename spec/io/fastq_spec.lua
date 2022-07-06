local fastq = require("build.io.fastq")

local test_case = [[@SEQ_ID
GATTTGGGGTTCAAAGCAGTATCGATCAAATAGTAAATCCATTTGTTCAACTCACAGTTT
+
!''*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65
@SEQ_ID_2
AATTTGGGGTTCAAAGCAGTATCGATCAAATAGTAAATCCATTTGTTCAACTCACAGTTT
+
!1'*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65
]]

describe("FASTQ", function()
	describe("parser", function()
		local fastqs = fastq.parse(test_case)
		it("should parse multiple FASTA lines", function()
			assert(#fastqs, 2)
		end)
		it("should parse identifiers", function()
			assert(fastqs[1].identifier, "SEQ_ID")
		end)
		it("should parse sequences", function()
			assert(fastqs[1].sequence, "GATTTGGGGTTCAAAGCAGTATCGATCAAATAGTAAATCCATTTGTTCAACTCACAGTTT")
		end)
		it("should parse quality lines", function()
			assert(fastqs[1].quality, "!''*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65")
		end)
		it("should parse multiple identifiers", function()
			assert(fastqs[2].identifier, "SEQ_ID_2")
		end)
		it("should parse multi-line sequences", function()
			assert(fastqs[2].sequence, "AATTTGGGGTTCAAAGCAGTATCGATCAAATAGTAAATCCATTTGTTCAACTCACAGTTT")
		end)
		it("should parse multiple quality lines", function()
			assert(fastqs[2].quality, "!1'*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65")
		end)
	end)
end)
