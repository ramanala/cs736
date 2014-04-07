#!/usr/bin/python

import os, sys, random, string, ConfigParser
from optparse import OptionParser
from test import *

BLOCK_SIZE = 4096

char_set = string.ascii_letters+string.digits

def getrandomstring(length):
    return ''.join(random.choice(char_set) for x in range(length))

def shouldsync(syncprobability):
    if(random.random() > syncprobability):
        return False
    else:
        return True

parser = OptionParser(usage="Usage: %prog [options] filename", description="...")

# example of a proper command line: -b 1 -f '/home/user1/workloads/seq' -w 40 -i 1 -s 1.0 -t 'sequential' -c False
parser.add_option("-s", "--sync", dest="syncprobability", type="float", default=0.0,help="Probability that we will call fsync after any write")
parser.add_option("-b", "--numblk", dest="blocks", type="int", default=10,help="Number of blocks in the file")
parser.add_option("-f", "--filepath", dest="filename", type="string", default="/tmp/temp.txt",help="Target file that will be used for running this workload. Note: Directory should exist")
parser.add_option("-w", "--writesize", dest="writesize", type="int", default=50,help="Write size for each write in bytes")
parser.add_option("-i", "--iter", dest="iterations", type="int", default=1000,help="Number of write iterations")
parser.add_option("-t", "--behavior", dest="behavior", type="string", default="random",help="random or sequential")
parser.add_option("-c", "--cachewarmup", action = "store_true" ,dest="warmup", default=False,help="Warm up cache?")

(options, args) = parser.parse_args()

#initialize local from command args
filename = options.filename
blocks = options.blocks
syncprobability = options.syncprobability
writesize = options.writesize
iterations = options.iterations
behavior = options.behavior
warmup = options.warmup

fd = os.open(filename, os.O_RDWR|os.O_CREAT )

if warmup:
    for i in range(0,blocks):
        randomstring = ''.join(random.choice(char_set) for x in range(BLOCK_SIZE))
        os.write(fd, randomstring)
        os.fsync(fd)

if behavior == 'sequential':
    assert(iterations * writesize <= BLOCK_SIZE*blocks)

#seeking to first before workload
os.lseek(fd, 0, 0)

for i in xrange(0, iterations):
    if behavior == 'random':
        seekpos = random.randint(0,(blocks*BLOCK_SIZE)- writesize)
        os.lseek(fd, seekpos, 0)
        
    os.write(fd, getrandomstring(writesize))
    
    if shouldsync(syncprobability):
        os.fsync(fd)

os.close(fd)



