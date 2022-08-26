local synbio = require("build.synbio")
local primers = synbio.primers

describe("primers", function()
	describe("Marmur Doty", function()
		it("should calculate sequence melting temperature properly", function()
			assert(primers.marmur_doty("ACGTCCGGACTT"), 31.0)
		end)
	end)

	describe("Santa Lucia", function()
		it("should calculate sequence melting temperature properly", function()
			local test_seq = "ACGATGGCAGTAGCATGC"
			local test_c_primer = 0.0000001 -- 0.1e-6
			local test_c_na = 0.350 -- 350e-3
			local test_c_mg = 0
			local expected_tm = 62.5
			local calc_tm = primers.santa_lucia(test_seq, test_c_primer, test_c_na, test_c_mg)
			assert(math.abs(expected_tm - calc_tm) <= 0.2)
		end)
		it("should apply 3' AT penalty", function()
			local test_seq = "ACGATGGCAGTAGCATGA"
            local test_c_primer = 0.0000001 -- 0.1e-6
            local test_c_na = 0.350 -- 350e-3
            local test_c_mg = 0
            local expected_tm = 60.5
			local calc_tm = primers.santa_lucia(test_seq, test_c_primer, test_c_na, test_c_mg)
			assert(math.abs(expected_tm - calc_tm) <= 0.2)
		end)
		it("should apply symmetry penalty", function()
			local test_seq = "ACGTAGATCTACGT"
			local test_c_primer = 0.0000001 -- 0.1e-6
            local test_c_na = 0.350 -- 350e-3
            local test_c_mg = 0
			local expected_tm = 47.428514
            local calc_tm = primers.santa_lucia(test_seq, test_c_primer, test_c_na, test_c_mg)
            assert(math.abs(expected_tm - calc_tm) <= 0.2)
		end)
	end)
	describe("Melting Temp", function()
		it("should calculate sequence melting temperature properly", function()
			local test_seq = "GTAAAACGACGGCCAGT" -- M13 fwd
			local expected_tm = 52.8
			local calc_tm = primers.melting_temp(test_seq)
			assert(math.abs(expected_tm - calc_tm) <= 0.2)
		end)
	end)
end)
