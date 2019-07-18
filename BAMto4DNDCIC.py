#!/usr/bin/env python

from os              import system, path as ospath
from subprocess      import Popen, PIPE
from multiprocessing import cpu_count
from argparse        import ArgumentParser


def main():
	opts = get_options()

	fname = opts.inbam
	fheader = opts.header
	outdir = opts.outdir
	cpus = opts.ncpus

	proc = Popen('samtools view -@{} {}'.format(cpus,fname),shell=True,stdout=PIPE)

	system("mkdir -p {}".format(outdir))

	out = open(ospath.join(outdir, '4dn.pairs'), 'w')
	fh = open(fheader,'r')

	out.write(fh.read())

	dico_strand1 = {'S1:i:1': '+', 'S1:i:0': '-'}
	dico_strand2 = {'S2:i:1': '+', 'S2:i:0': '-'}

	for line in proc.stdout:
		rID, _, c1, b1, _, _, c2, b2, _, _, _, _, s1, s2 = line.split('\t', 14)

		if c2 == "=":
			c2 = c1 

		out.write('{}\t{}\t{}\t{}\t{}\t{}\t{}\t\n'.format(
				rID, c1, b1, c2, b2, dico_strand1[s1], dico_strand[s2]))

	out.close()


def get_options():
	parser = ArgumentParser()
	parser.add_argument('-i', '--bam', dest='inbam', required=True, metavar='PATH',
						help='Input TADbit HiC-BAM file')
	parser.add_argument('-H', '--header', dest='header', required=True, metavar='PATH',
						help='Input 4dn format header with pairs format, columns and chromsize')
	parser.add_argument('-o', '--out', dest='outdir', required=True, metavar='PATH',
						help='Outdir to store 4dn file')
	parser.add_argument('-c', dest='ncpus', default=cpu_count(),
                        type=int, help='[%(default)s] Number of CPUs used to read BAM')
	opts = parser.parse_args()

	return opts

if __name__ == '__main__':
    exit(main())
