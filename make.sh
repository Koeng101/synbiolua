# Generate synbio.tl
[ -e tmp.tl ] && rm tmp.tl

sed '$d' src/complement.tl >> tmp.tl
sed '$d' src/fasta.tl >> tmp.tl
sed '$d' src/fastq.tl >> tmp.tl
sed '$d' src/primers.tl >> tmp.tl
sed '$d' src/genbank.tl >> tmp.tl
sed '$d' src/codon.tl >> tmp.tl
cat src/synbio.tl >> tmp.tl
sed -i '/require/d' tmp.tl
sed -i 's/SUBSTITUTE_WITH_VERSION_NUMBER/0.0.1/g' tmp.tl

mv tmp.tl synbio.tl
tl gen synbio.tl
mv synbio.tl synbio.lua build/

busted -c -m "./build/?.lua"
