# Generate tl -> lua
tl gen io/fasta/fasta.tl io/fasta/fasta_test.tl
tl gen io/fastq/fastq.tl io/fastq/fastq_test.tl
tl gen io/genbank/genbank.tl io/genbank/genbank_test.tl

# Get stats
lua -lluacov fasta.lua
lua -lluacov fasta_test.lua
lua -lluacov fastq.lua
lua -lluacov fastq_test.lua
lua -lluacov genbank.lua
lua -lluacov genbank_test.lua
luacov
rm luacov.stats.out

# run tests
luajit fasta_test.lua
luajit fastq_test.lua
luajit genbank_test.lua

# Cleanup lua
rm fasta.lua fasta_test.lua
rm fastq.lua fastq_test.lua
rm genbank.lua genbank_test.lua
