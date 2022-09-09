--[[---------------------------------------------------------------------------
The synbio module contains all of synbiolua in a single module to enable
embedding into larger programs. All other modules are built into synbio.
]]-----------------------------------------------------------------------------

local complement = require("complement")
local fasta = require("fasta")
local fastq = require("fastq")
local primers = require("primers")
local pcr = require("pcr")
local genbank = require("genbank")
local codon = require("codon")
local fragment = require("fragment")
local json = require("json")

local record synbio
    version: string
    complement: complement
    fasta: fasta
    fastq: fastq
    primers: primers
    pcr: pcr
    genbank: genbank
    codon: codon
    fragment: fragment
    json: json
end

synbio.version = "SUBSTITUTE_WITH_VERSION_NUMBER"
synbio.complement = complement
synbio.fasta = fasta
synbio.fastq = fastq
synbio.primers = primers
synbio.pcr = pcr
synbio.genbank = genbank
synbio.codon = codon
synbio.fragment = fragment
synbio.json = json

return synbio
