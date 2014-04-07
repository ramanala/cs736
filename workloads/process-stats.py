#!/usr/bin/env python

import sys

stats = sys.argv[1]

distribution = {}

with open(stats, 'r') as f:
  for line in f:
    if int(line) in distribution:
      distribution[int(line)] += 1
    else:
      distribution[int(line)] = 1

total = sum(map(lambda (k,v): k*v, distribution.items()))
count = sum(distribution.values())

print total
print count
print float(total) / count

for size, num in sorted(distribution.items()):
  print size, num
