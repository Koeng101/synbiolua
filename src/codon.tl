--[[---------------------------------------------------------------------------
The codon module provides functions to work with codon tables, including the
translation of DNA/RNA into protein and the codon optimization (given a certain
organism's codon table) of a protein sequence into a nucleotide sequence.
]]-----------------------------------------------------------------------------
local record codon
    record Codon
        triplet: string
        weight: number
    end
    record AminoAcid
        letter: string
        codons: {Codon}
    end

    record CodonTable
        start_codons: {Codon}
        amino_acids: {AminoAcid}
    end

    CODON_TABLES: {number:{string, string}}
end

--[[---------------------------------------------------------------------------
July, 06, 2022

Codon table generation begins here.

Different organisms use different codons to represent different amino acids.
NCBI publishes this weird data format for developers to use for generating
codon tables and mapping codons for different organisms. All of the following
codon tables are experimentally validated.

]]-----------------------------------------------------------------------------

--- codon.CODON_TABLES are current NCBI sanctioned codon tables with their respective numbers.
-- @field 1 Translation table 1
-- @field 2 Translation table 2
-- @field 3 Translation table 3
-- @field 4 Translation table 4
-- @field 5 Translation table 5
-- @field 6 Translation table 6
-- @field 7 Translation table 7
-- @field 8 Translation table 8
-- @field 9 Translation table 9
-- @field 10 Translation table 10
-- @field 11 Translation table 11
-- @field 12 Translation table 12
-- @field 13 Translation table 13
-- @field 14 Translation table 14
-- @field 15 Translation table 15
-- @field 16 Translation table 16
-- @field 17 Translation table 17
-- @field 18 Translation table 18
-- @field 19 Translation table 19
-- @field 20 Translation table 20
-- @field 21 Translation table 21
-- @field 22 Translation table 22
-- @field 23 Translation table 23
-- @field 24 Translation table 24
-- @field 25 Translation table 25
-- @field 26 Translation table 26
-- @field 27 Translation table 27
-- @field 28 Translation table 28
-- @field 29 Translation table 29
-- @field 30 Translation table 30
-- @field 31 Translation table 31
-- @field 32 Translation table 32
-- @field 33 Translation table 33
-- @table CODON_TABLES
codon.CODON_TABLES = {
    [1] = {"FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**--*----M---------------M----------------------------"},
    [2] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG", "----------**--------------------MMMM----------**---M------------"},
    [3] = {"FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**----------------------MM---------------M------------"},
    [4] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--MM------**-------M------------MMMM---------------M------------"},
    [5] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG", "---M------**--------------------MMMM---------------M------------"},
    [6] = {"FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------"},
    [9] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG", "----------**-----------------------M---------------M------------"},
    [10] = {"FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**-----------------------M----------------------------"},
    [11] = {"FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**--*----M------------MMMM---------------M------------"},
    [12] = {"FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**--*----M---------------M----------------------------"},
    [13] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG", "---M------**----------------------MM---------------M------------"},
    [14] = {"FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG", "-----------*-----------------------M----------------------------"},
    [16] = {"FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------*---*--------------------M----------------------------"},
    [21] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG", "----------**-----------------------M---------------M------------"},
    [22] = {"FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "------*---*---*--------------------M----------------------------"},
    [23] = {"FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--*-------**--*-----------------M--M---------------M------------"},
    [24] = {"FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG", "---M------**-------M---------------M---------------M------------"},
    [25] = {"FFLLSSSSYY**CCGWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**-----------------------M---------------M------------"},
    [26] = {"FFLLSSSSYY**CC*WLLLAPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**--*----M---------------M----------------------------"},
    [27] = {"FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------"},
    [28] = {"FFLLSSSSYYQQCCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**--*--------------------M----------------------------"},
    [29] = {"FFLLSSSSYYYYCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------"},
    [30] = {"FFLLSSSSYYEECC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "--------------*--------------------M----------------------------"},
    [31] = {"FFLLSSSSYYEECCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "----------**-----------------------M----------------------------"},
    [33] = {"FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG", "---M-------*-------M---------------M---------------M------------"},
}


--- Generates a codon table from a list of amino acids and a list of start codons, given in the standard NCBI codon table format.
-- @param amino_acids the amino acid string
-- @param starts the start codon string
-- @return a codon table
-- @usage local ct = codon.ncbi_standard_to_codon_table("FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG", "---M------**--*----M------------MMMM---------------M------------")
function codon.ncbi_standard_to_codon_table(amino_acids: string, starts:string): codon.CodonTable 
    local base1 = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG"
    local base2 = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG"
    local base3 = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG"
    local amino_acid_table: {string:{codon.Codon}} = {}
    local ct: codon.CodonTable = {}
    ct.start_codons = {}
    for i = 1, #amino_acids do
        local triplet: string = base1:sub(i,i) .. base2:sub(i,i) .. base3:sub(i,i)
        -- Generate start_codons
        if starts:sub(i,i) == "M" then
            local start_codon: codon.Codon
            start_codon = {triplet = triplet, weight = 0}
            ct.start_codons[#ct.start_codons+1] = start_codon
        end
        -- Generate amino_acids
        local amino_acid = amino_acids:sub(i,i)
        if amino_acid_table[amino_acid] == nil then
            amino_acid_table[amino_acid] = {{triplet = triplet, weight = 0}}
        else
            amino_acid_table[amino_acid][#amino_acid_table[amino_acid]+1] = {triplet = triplet, weight = 0}
        end
    end

    -- Fill in codon table
    ct.amino_acids = {}
    for amino_acid, codons in pairs(amino_acid_table) do
        ct.amino_acids[#ct.amino_acids+1] = {letter = amino_acid, codons = codons}
    end
    return ct
end

--- Generates a new codon table given an NCBI codon table number.
-- @param table_number the table number
-- @return a codon table
-- @usage local ct = codon.new_table(11)
function codon.new_table(table_number: number): codon.CodonTable
    return codon.ncbi_standard_to_codon_table(codon.CODON_TABLES[table_number][1], codon.CODON_TABLES[table_number][2])
end
--[[---------------------------------------------------------------------------
July, 21, 2022

Codon table filling begins here.

In order to be useful for optimization or fixing, codon tables need to be
filled with data.

]]-----------------------------------------------------------------------------

--[[---------------------------------------------------------------------------
July, 21, 2022

Compromise + Add codon table begins here.

## Compromise tables
If you want to codon optimize a protein for two or more organisms, you will
want a codon table that works for both organisms. Compromise codon tables
standardize codon counts so the weights are equal between both organisms.
Then, they are added together. There is also a variable for removing rare
codons, which is essential to get good protein yield in many organisms(however,
this feature makes compromise tables lossy).

]]-----------------------------------------------------------------------------

return codon
