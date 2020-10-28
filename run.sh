# Example usage (with the common.s and minesweeper.s in the same directory):
# ./run.sh


rm -f test.s
cat common.s > test.s
cat minesweeper.s >> test.s
spim -notrap -mapped_io -f test.s