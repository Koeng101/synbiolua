local fasta = require("build.fasta")

local test_case = [[>hello there
atg
;a comment

>general kenobi
atg
taa
]]

describe("FASTA", function()
	describe("parser", function()
		local fastas = fasta.parse(test_case)
		it("should parse multiple FASTA lines", function()
			assert(#fastas, 2)
		end)
		it("should parse identifiers", function()
			assert(fastas[1].identifier, "hello there")
		end)
		it("should parse sequences", function()
			assert(fastas[1].sequence, "atg")
		end)
		it("should parse multiple identifiers", function()
			assert(fastas[2].identifier, "general kenobi")
		end)
		it("should parse multi-line sequences", function()
			assert(fastas[2].sequence, "taa")
		end)
	end)
end)
