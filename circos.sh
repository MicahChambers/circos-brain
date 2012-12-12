#!/bin/bash


EXE=`basename $0`
DIR="$( cd "$( dirname "$0" )" && pwd )"
export PERL5LIB=/ifs/students/mchambers/perl/share/perl5/:/ifs/students/mchambers/perl/lib64/perl5

tmpdir=`mktemp -d`
echo Tempdir: $tmpdir
if [ -d "$1/data" ]; then
	echo "Input Data Directory: $1/data"
	echo "Input etc Directory: $2"
	echo "Output Directory: $3"
	cp -av $1/data $tmpdir/data
else 
	echo "Input Data Directory: $1"
	echo "Input etc Directory: $2"
	echo "Output Directory: $3"
	cp -av $1 $tmpdir/data
fi
cp -av $2 $tmpdir/etc
cd $tmpdir/data
for i in `seq 10 -1 4`; do 
	if [ -e "measure.$i.txt" ]; then
		mv -v measure.$i.txt measure.$((i+1)).txt
	fi
done
cd $tmpdir

#cmd="/ifs/students/mchambers/circos-brain-0.2/circos-0.62-1/bin/circos --cdump --outputdir $3 --color_cache_rebuild"
cmd="$DIR/circos-0.62-1/bin/circos --outputdir $3 --color_cache_rebuild --noparanoid"
echo "Using: "
echo $cmd
$cmd
