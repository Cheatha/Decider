# About Decider
A small command line utility written in bash to find the best
option from a list of options. Randomly choose two or more options
and let the user decide which is the best one.

Only options within a certain threshold will be chosen. After each 
decision the winning option will be up- and all other options will 
be downvoted. Every option has an additional counter, which stores 
how many times it was compared. An option will only be compared if 
it has a positive vote balance or was chosen less than ten times.

These thresholds are customizable.

## Installation
There is no installation: Just clone the repository and start decider.sh.

## Usage
Start Decider with `./decider.sh`

You can do some tasks directly from command line:

### Add new option
To add "YourOption": `./decider.sh add YourOption`

### Remove option
To remove "YourOption": `./decider.sh remove YourOption`

### Print options
Print all options in database: `./decider.sh print`

### Batch add new options
You can batch add a list of options. One option per line.
`./decider batchadd YourOptionList.txt`

### Show Top/Bottom options
Show 10 best voted options: `./decider hiscore`
