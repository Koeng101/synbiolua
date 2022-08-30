local synbio = require("synbio")
local blake3 = synbio.seqhash.blake3

print(blake3("hello world"))
