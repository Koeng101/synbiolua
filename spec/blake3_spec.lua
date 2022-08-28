local synbio = require("build.synbio")
local blake3 = synbio.blake3

describe("blake3", function()
	it("should hash <64 bytes", function()
		assert(blake3.sum("hello world"), "d74981efa7ac88b8d8c1985d075dbcbf679b99a5f9914e5aaf96b831a9e24a020ed55aed9a6ab2eaf3fd7d2c98c949e142d8f42a1025190b699e02cf9eb")
	end)
	it("should hash >64 <1024 bytes", function()
		assert(blake3.sum("GTCCTGTCGGGTTTCGCCACCTCTGACTTGAGCGTCGATTTTTGTGATGCTCGTCAGGGGGGCGGAGCCT"), "72ed9518d2bd3248ac524cb467db52c90c9b5981a2eccdc9f08fac39feb5757f86c1f914aba359087eab3854aff7c6dcb0acbbb4f8a05f95496fe585bff2")
	end)
end)
