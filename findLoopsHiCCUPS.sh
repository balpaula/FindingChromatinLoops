#!/bin/bash

usage() {
	echo "Command takes the following form:"
	echo -e " \t findLoopsHiCCUPS.sh BAMfile headerFor4dn outputDirectory genome (e.g. h38) [options]"
	echo
	echo "Optional arguments from HiCCUPS can also be specified:"
	echo -e " \t -m <int>: maximum size of the submatrix within the chromosome"
	echo -e " \t -c <String(s)>: chromosome(s) on which HiCCUPS will be run"
	echo -e " \t -r <int(s)>: resolution(s) for which HiCCUPS will be run"
	echo 
	echo "Number of CPUs to use for BAM to 4dn conversion:"
	echo -e " \t -C numberCPUs"
	echo
	echo "Required in the working directory:"
	echo -e "\t BAMto4DNDCIC.py"
	echo
	}

INFILE=$1
HEADER=$2
NHEADER=$(echo $(wc -l "$HEADER" | awk '{ print $1 }'))
OUTDIR=$3
GENOME=$4
CPUS=1
RES=""
CHR=""
MTR=""

# PATH to JUICER directory
JUICERDIR="./hiccups_cluster/Juicer/scripts/common/juicer_tools.jar"

while getopts ":r:C:c:m:" arg; do
  case $arg in
    C) CPUS=$OPTARG;;
    r) RES=$OPTARG;;
	c) CHR=$OPTARG;;
	m) MTR=$OPTARG;;
  esac
done

if [  $# -le 1 ]; then 
	usage
	exit 1
fi

echo "Initializing findLoopsHiCCUPS"
echo
echo "BAM file used $INFILE"
echo "Results will be stored in directory $OUTDIR"/
echo
echo "Header for 4dn format used $HEADER"
echo

if [ ! -d "$OUTDIR" ]; then
	mkdir $OUTDIR/
fi

echo "Converting BAM file to 4dn format..."

python BAMto4DNDCIC.py -i $INFILE -H $HEADER -o $OUTDIR -c $CPUS

echo "4dn file ready"
echo

cd $OUTDIR/

echo "Sorting and compressing 4dnDCIC.pairs file..."

(head -n $NHEADER ./4dnDCIC.pairs && tail -n +$(("$NHEADER"+1)) ./4dnDCIC.pairs | sort -k2,2 -k4,4 -k3,3n -k5,5n) | ./bgzip -c > ./4dnDCIC.pairs.gz

echo "4dnDCIC.pairs.gz file ready"
echo

HICNAME=$(echo $INFILE| cut -f 1 -d '.')

echo "Converting .pairs.gz file to .hic and running HiCCUPS..."

if [ -z "$MTR" ]; then
	if [ ! -z "$RES" ] && [ ! -z "$CHR" ]; then
		java -Xmx2g -jar $JUICERDIR pre -r "$RES" -c "$CHR" ./4dnDCIC.pairs.gz ./$HICNAME.hic $GENOME
		java -Xmx2g -jar $JUICERDIR hiccups -r "$RES" -c "$CHR" ./$HICNAME.hic $OUTDIR
	elif [ ! -z "$RES" ]; then
		java -Xmx2g -jar $JUICERDIR pre -r "$RES" ./4dnDCIC.pairs.gz ./$HICNAME.hic $GENOME
		java -Xmx2g -jar $JUICERDIR hiccups -r "$RES" ./$HICNAME.hic $OUTDIR
	elif [ ! -z "$CHR" ]; then
		java -Xmx2g -jar $JUICERDIR pre -r "$CHR" ./4dnDCIC.pairs.gz ./$HICNAME.hic $GENOME
		java -Xmx2g -jar $JUICERDIR hiccups -c "$CHR" ./$HICNAME.hic $OUTDIR
	else
		java -Xmx2g -jar $JUICERDIR pre ./4dnDCIC.pairs.gz ./$HICNAME.hic $GENOME
		java -Xmx2g -jar $JUICERDIR hiccups ./$HICNAME.hic $OUTDIR
	fi
else
	if [ ! -z "$RES" ] && [ ! -z "$CHR" ]; then
		java -Xmx2g -jar $JUICERDIR pre -r "$RES" -c "$CHR" ./4dnDCIC.pairs.gz ./$HICNAME.hic $GENOME
		java -Xmx2g -jar $JUICERDIR hiccups -m "$MTR" -r "$RES" -c "$CHR" ./$HICNAME.hic $OUTDIR
	elif [ ! -z "$RES" ]; then
		java -Xmx2g -jar $JUICERDIR pre -r "$RES" ./4dnDCIC.pairs.gz ./$HICNAME.hic $GENOME
		java -Xmx2g -jar $JUICERDIR hiccups -m "$MTR" -r "$RES" ./$HICNAME.hic $OUTDIR
	elif [ ! -z "$CHR" ]; then
		java -Xmx2g -jar $JUICERDIR pre -r "$CHR" ./4dnDCIC.pairs.gz ./$HICNAME.hic $GENOME
		java -Xmx2g -jar $JUICERDIR hiccups -m "$MTR" -c "$CHR" ./$HICNAME.hic $OUTDIR
	else
		java -Xmx2g -jar $JUICERDIR pre ./4dnDCIC.pairs.gz ./$HICNAME.hic $GENOME
		java -Xmx2g -jar $JUICERDIR hiccups -m "$MTR" ./$HICNAME.hic $OUTDIR
	fi
fi

echo "Done. Results in $OUTDIR"

