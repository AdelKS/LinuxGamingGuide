#!/bin/bash

echo "Redirecting Processes back to main cpuset"
while read p; do
  echo "Redirecting PID $p"
  /bin/echo $p > /dev/cpuset/tasks
done < /dev/cpuset/theUgly/tasks

while read p; do
  echo "Redirecting PID $p"
  /bin/echo $p > /dev/cpuset/tasks
done < /dev/cpuset/theGood/tasks

/bin/rmdir /dev/cpuset/theUgly
/bin/rmdir /dev/cpuset/theGood
