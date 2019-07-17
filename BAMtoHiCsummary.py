#!/usr/bin/env python

import sys
from subprocess import Popen, PIPE

fname = sys.argv[1]
outdir = sys.argv[2]
cpus = sys.argv[3]
proc = Popen('samtools view -@{} {}'.format(cpus,fname),shell=True,stdout=PIPE)

out = open('{}/HiCsummary.txt'.format(outdir), 'w')

for line in proc.stdout:
	rID, flag, c1, b1, _, l1, c2, b2, tl, _, _, tc, s1, s2 = line.split()
	if c2 == "=":
		c2 = c1 
	sr1 = '+' if s1 == 'S1:i:1' else '-'
	sr2 = '+' if s2 == 'S2:i:1' else '-'
	out.write('{}\t{}\t{}\t{}\t{}\t{}\t{}\t\n'.format(rID, c1, b1, sr1, c2, b2, sr2))

out.close()
