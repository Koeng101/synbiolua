local genbank = require("build.genbank")

local puc19_file = io.open("spec/data/puc19.gbk", "rb")
local puc19 = puc19_file:read("*a")
puc19_file:close()
local plasmid = genbank.parse(puc19)[1]

describe("Genbank", function()
	describe("parser", function()
		it("should parse locus name", function()
			assert(plasmid.meta.locus.name, "puc19.gbk")
		end)
	end)

	describe("feature", function()
		it("should return proper sequence from simple parse", function()
			assert(genbank.feature_sequence(plasmid.features[10], plasmid) == "ATGACCATGATTACGCCAAGCTTGCATGCCTGCAGGTCGACTCTAGAGGATCCCCGGGTACCGAGCTCGAATTCACTGGCCGTCGTTTTACAACGTCGTGACTGGGAAAACCCTGGCGTTACCCAACTTAATCGCCTTGCAGCACATCCCCCTTTCGCCAGCTGGCGTAATAGCGAAGAGGCCCGCACCGATCGCCCTTCCCAACAGTTGCGCAGCCTGAATGGCGAATGGCGCCTGATGCGGTATTTTCTCCTTACGCATCTGTGCGGTATTTCACACCGCATATGGTGCACTCTCAGTACAATCTGCTCTGATGCCGCATAG") -- get CDS
		end)
	end)
end)
