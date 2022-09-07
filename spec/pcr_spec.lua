local synbio = require("build.synbio")
local pcr = synbio.pcr

local gene = "aataattacaccgagataacacatcatggataaaccgatactcaaagattctatgaagctatttgaggcacttggtacgatcaagtcgcgctcaatgtttggtggcttcggacttttcgctgatgaaacgatgtttgcactggttgtgaatgatcaacttcacatacgagcagaccagcaaacttcatctaacttcgagaagcaagggctaaaaccgtacgtttataaaaagcgtggttttccagtcgttactaagtactacgcgatttccgacgacttgtgggaatccagtgaacgcttgatagaagtagcgaagaagtcgttagaacaagccaatttggaaaaaaagcaacaggcaagtagtaagcccgacaggttgaaagacctgcctaacttacgactagcgactgaacgaatgcttaagaaagctggtataaaatcagttgaacaacttgaagagaaaggtgcattgaatgcttacaaagcgatacgtgactctcactccgcaaaagtaagtattgagctactctgggctttagaaggagcgataaacggcacgcactggagcgtcgttcctcaatctcgcagagaagagctggaaaatgcgctttcttaa"

describe("pcr", function()
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
    local err = false
    if pcall(pcr.simulate({{sequence = gene, circular = false}}, {forward_primer, reverse_primer}, 55.0)) then err = false else err = true end
    assert(err, true, "should call error when concatemerizing")
  end)
    
end)
