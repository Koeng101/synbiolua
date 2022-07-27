local complement = require("build.complement")

describe("complement", function()
	it("should reverse a string", function()
		assert(complement.reverse_complement("ABCDGHKMNRSTUVWYabcdghkmnrstuvwy"), "rwbaasynkmdchgvtRWBAASYNKMDCHGVT")
	end)
end)
