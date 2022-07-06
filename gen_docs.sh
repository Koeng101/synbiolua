rm -rf docs
mkdir tmp
find . -name "*.tl" | xargs cp -t tmp/
cd tmp
for f in *.tl; do
	mv -- "$f" "${f%.tl}.lua"
done
cd ..
ldoc tmp
rm -rf tmp
