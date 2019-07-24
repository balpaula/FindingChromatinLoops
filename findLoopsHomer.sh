#!/bin/bash

usage() {
	echo "Command takes the followinf form:"
	echo -e " \t findLoopsHomer.sh BAMfile outputDirectory [options]"
	echo
	echo "Homer options can also be specified:"
	echo -e " \t -c numberCPUs -r resolution -w window -g genome (e.g. hg38) -p badRegions.bed"
	echo "Default:"
	echo -e " \t -cpu 10 -res 3000 -window 15000"
	echo
	echo "Required in the working directory:"
	echo -e " \t BAMtoHiCsummary.py"
	echo
	}

INFILE=$1
OUTDIR=$2
RES=3000
CPUS=1
WINDOW=15000
GENOME=""
BADREGIONS=""

# PATH to HOMER directory
HOMER=""

while getopts ":r:C:w:g:p:" arg; do
  case $arg in
    r) RES=$OPTARG;;
    C) CPUS=$OPTARG;;
	w) WINDOW=$OPTARG;;
	g) GENOME=$OPTARG;;
	p) BADREGIONS=$OPTARG;;
  esac
done

if [  $# -le 1 ]; then
	usage
	exit 1
fi

echo "Initializing findLoopsHomer"
echo
echo "BAM file used $INFILE"
echo "Results will be stored in directory $OUTDIR"/
echo

if [ ! -d "$OUTDIR" ]; then
	mkdir $OUTDIR/
fi


echo "Converting BAM file to HiCsummary format..."

python BAMtoHiCsummary.py -i $INFILE -o $OUTDIR -C $CPUS

echo "HiCsummary file ready"
echo

cd $OUTDIR/

echo "Creating TagDirectory for Homer results..."

$HOMER/makeTagDirectory HomerDir/ -format HiCsummary HiCsummary.txt 2>&1 | tee -a mtd.out

#makeTagDirectory HomerDir/ -format HiCsummary HiCsummary.txt 2>&1 | tee -a mtd.out

#makeTagDirectory HomerDir/ -format HiCsummary HiCsummary.txt > mtd.out

#script makeTagDirectory.out
#makeTagDirectory HomerDir/ -format HiCsummary HiCsummary.txt
#exit

echo "TagDirectory ready"
echo
echo "Calling findTADsAndLoops.pl from Homer..."
echo -e " \t Resolution $RES"
echo -e " \t CPUs $CPUS"

if [ -z "$GENOME" ] && [ ! -z "$BADREGIONS" ]; then
	echo -e " \t No genome specified, ignoring bad regions file"
elif [ ! -z "$GENOME" ] && [ ! -z "$BADREGIONS" ]; then
	echo -e " \t Genome $GENOME"
	echo -e " \t Using bad regions file $BADREGIONS"
elif [ ! -z "$GENOME" ]; then
	echo -e " \t Genome $GENOME"
fi

if ( [ -z "$GENOME" ] && [ -z "$BADREGIONS" ] ) || [ -z "$GENOME" ]; then
	$HOMER/findTADsAndLoops.pl find HomerDir/ -cpu $CPUS -res $RES -window $WINDOW
	#(findTADsAndLoops.pl find HomerDir/ -cpu $CPUS -res $RES -window $WINDOW) > findTADsAndLoops.out
elif [ -z "$BADREGIONS" ]; then
	  $HOMER/findTADsAndLoops.pl find HomerDir/ -cpu $CPUS -res $RES -window $WINDOW -genome $GENOME
	#(findTADsAndLoops.pl find HomerDir/ -cpu $CPUS -res $RES -window $WINDOW -genome $GENOME) > findTADsAndLoops.out
else
	  $HOMER/findTADsAndLoops.pl find HomerDir/ -cpu $CPUS -res $RES -window $WINDOW -genome $GENOME -p $BADREGIONS
	#(findTADsAndLoops.pl find HomerDir/ -cpu $CPUS -res $RES -window $WINDOW -genome $GENOME -p $BADREGIONS) > findTADsAndLoops.out
fi

tail -n 5 findTADsAndLoops.out

echo
echo "findTADsAndLoops.pl ready"
echo

cd ..

echo "Done. Results in $OUTDIR/HomerDir/HomerDir.loop.2D.bed"

