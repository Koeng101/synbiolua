local gb = require("build.io.genbank")

local puc19_file = io.open("data/puc19.gbk", "rb")
local puc19 = puc19_file:read("*a")
puc19_file:close()
local plasmid = gb.parse(puc19)[1]

describe("Genbank", function()
	describe("parser", function()
		it("should parse locus name", function()
			assert(plasmid.meta.locus.name, "puc19.gbk")
		end)
	end)
end)
