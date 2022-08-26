--[[---------------------------------------------------------------------------
The synbio module contains all of synbiolua in a single module to enable
embedding into larger programs. All other modules are built into synbio.
]]-----------------------------------------------------------------------------

local complement = require("complement")
local fasta = require("fasta")
local fastq = require("fastq")
local primers = require("primers")
local genbank = require("genbank")
local codon = require("codon")

local record synbio
    version: string
    complement: complement
    fasta: fasta
    fastq: fastq
    primers: primers
    genbank: genbank
    codon: codon
end

synbio.version = "SUBSTITUTE_WITH_VERSION_NUMBER"
synbio.complement = complement
synbio.fasta = fasta
synbio.fastq = fastq
synbio.primers = primers
synbio.genbank = genbank
synbio.codon = codon

return synbio
