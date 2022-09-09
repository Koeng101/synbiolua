local pcr = require("build.pcr")

local gene = "aataattacaccgagataacacatcatggataaaccgatactcaaagattctatgaagctatttgaggcacttggtacgatcaagtcgcgctcaatgtttggtggcttcggacttttcgctgatgaaacgatgtttgcactggttgtgaatgatcaacttcacatacgagcagaccagcaaacttcatctaacttcgagaagcaagggctaaaaccgtacgtttataaaaagcgtggttttccagtcgttactaagtactacgcgatttccgacgacttgtgggaatccagtgaacgcttgatagaagtagcgaagaagtcgttagaacaagccaatttggaaaaaaagcaacaggcaagtagtaagcccgacaggttgaaagacctgcctaacttacgactagcgactgaacgaatgcttaagaaagctggtataaaatcagttgaacaacttgaagagaaaggtgcattgaatgcttacaaagcgatacgtgactctcactccgcaaaagtaagtattgagctactctgggctttagaaggagcgataaacggcacgcactggagcgtcgttcctcaatctcgcagagaagagctggaaaatgcgctttcttaa"

describe("pcr", function()
  describe("simulation", function()
    it("should simulate primer rejection", function()
      -- CTGCAGGTCGACTCTAG is too low tm for this function, so there is a break in the logic.
      local primers = {"TATATGGTCTCTTCATTTAAGAAAGCGCATTTTCCAGC", "TTATAGGTCTCATACTAATAATTACACCGAGATAACACATCATGG", "CTGCAGGTCGACTCTAG"}
      local fragments = pcr.simulate({{sequence = gene, circular = false}}, primers, 55.0)
      assert(#fragments, 1, "Should only have one fragment")
    end)

    it("should simulate more than one forward", function()
      -- This tests the first bit of logic in simulate.
      -- If this primer isn't last forward binding primer AND there is
      -- another reverse primer binding site.
      -- gatactcaaagattctatgaagctatttgaggcacttggtacg occurs internally inside of
      -- gene
      local internal_primer = "gatactcaaagattctatgaagctatttgaggcacttggtacg"

      -- reverse_primer is a different primer from normal that will bind inside
      -- of gene.
      local reverse_primer = "tatcgctttgtaagcattcaatgcacctttctcttcaagttg"

      -- outside_forward_primer is a primer that binds out of range of
      -- reverse_primer
      local outside_forward_primer = "gtcgttcctcaatctcgcagagaagagctggaaaatg"

      local fragments = pcr.simulate({{sequence = gene, circular = false}}, {internal_primer, reverse_primer, outside_forward_primer}, 55.0)
      assert(#fragments, 1, "Should only have one fragment")
    end)

    it("should simulate PCR on a circular DNA", function()
      -- This tests for ciruclar sequences
      local forward_primer = "actctgggctttagaaggagcgataaacggc"
      local reverse_primer = "aagtgcctcaaatagcttcatagaatctttgagtatcgg"
      local target_fragment = "ACTCTGGGCTTTAGAAGGAGCGATAAACGGCACGCACTGGAGCGTCGTTCCTCAATCTCGCAGAGAAGAGCTGGAAAATGCGCTTTCTTAAAATAATTACACCGAGATAACACATCATGGATAAACCGATACTCAAAGATTCTATGAAGCTATTTGAGGCACTT"
      local fragments = pcr.simulate({{sequence = gene, circular = true}}, {forward_primer, reverse_primer}, 55.0)
      assert(fragments[1], target_fragment, "Didn't get target fragment from circular pcr.")
    end)

    it("should simulate concatemerization", function()
      local forward_primer = "AATAATTACACCGAGATAACACATCATGG"
      local reverse_primer = "CCATGATGTGTTATCTCGGTGTAATTATTTTAAGAAAGCGCATTTTCCAGC"
      assert.has_error(function() pcr.simulate({{sequence = gene, circular = false}}, {forward_primer, reverse_primer}, 55.0) end, "Concatemerization detected in PCR.", "should call error when concatemerizing")
    end)

    it("should get ending PCRs", function()
      local primers = {"TATATGGTCTCTTCATTTAAGAAAGCGCATTTTCCAGC", "TTATAGGTCTCATACTAATAATTACACCGAGATAACACATCATGG", "actctgggctttagaaggagcgataaacggc"}
      local fragments = pcr.simulate({{sequence = gene, circular = false}}, primers, 55.0)
      assert(#fragments, 1, "Should only have one fragment")
    end)
  end)

  describe("design", function()
    it("should design primers", function()
      local fwd, rev = pcr.design_primers(gene, 55)
      assert(fwd, "AATAATTACACCGAGATAACACATCATGG")
      assert(rev, "TTAAGAAAGCGCATTTTCCAGC")
    end)
    
    it("should design primers with the right overhangs", function()
      local fwd, rev = pcr.design_primers_with_overhang(gene, "ATGC", "ATGC", 55)
      assert(fwd, "ATGCAATAATTACACCGAGATAACACATCATGG")
      assert(rev, "TACGTTAAGAAAGCGCATTTTCCAGC")
    end)
  end)
end)
