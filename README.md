# NimTM
A turing machine emulator written in nim.

#Build
```
nim c --d:release tm.nim
```

#Usage

./tm <descriptor filename> <input filename>
./tm machines/5busyBeaver inputs/blank

```
time ./tm machines/5busyBeaver inputs/blank
tape: 1_11 ...
length: 6145
head moves: 11798826
Input was accepted

real	0m1.650s
user	0m1.650s
sys	0m0.000s
```

As you can see it takes less than 2 seconds to execute the busy five state busy beaver.


