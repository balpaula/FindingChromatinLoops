#!/usr/bin/env python

from os              import system, path as ospath
from subprocess      import Popen, PIPE
from multiprocessing import cpu_count
from argparse        import ArgumentParser


def main():
    opts = get_options()

    fname = opts.inbam
    outdir = opts.outdir
    cpus = opts.ncpus

    proc = Popen('samtools view -@{} {}'.format(cpus,fname), shell=True, stdout=PIPE)

    system("mkdir -p {}".format(outdir))

    out = open(ospath.join(outdir, 'HiCsummary.txt'), 'w')

    # not much faster, but also checks that s1 trully comes from read-end 1
    dico_strand1 = {'S1:i:1': '+', 'S1:i:0': '-'}
    dico_strand2 = {'S2:i:1': '+', 'S2:i:0': '-'}

    for line in proc.stdout:
        # stop at 14, some BAM have more fields
        rID, _, c1, b1, _, _, c2, b2, _, _, _, _, s1, s2, _ = line.split('\t', 14)

        if c2 == "=":
            c2 = c1

        try:
		out.write('{}\t{}\t{}\t{}\t{}\t{}\t{}\t\n'.format(
	        	rID, c1, b1, dico_strand1[s1], c2, b2, dico_strand2[s2]))
	except KeyError:
		pass
    out.close()


def get_options():
    parser = ArgumentParser()
    parser.add_argument('-i', '--bam', dest='inbam', required=True, metavar='PATH',
                        help='Input TADbit HiC-BAM file')
    parser.add_argument('-o', '--out', dest='outdir', required=True, metavar='PATH',
                        help='Outdir to store HiCsummary file')
    parser.add_argument('-C', dest='ncpus', default=cpu_count(),
                        type=int, help='[%(default)s] Number of CPUs used to read BAM')
    opts = parser.parse_args()

    return opts


if __name__ == '__main__':
    exit(main())
