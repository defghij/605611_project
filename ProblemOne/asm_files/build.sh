#! /bin/sh

case $1 in
  "A" | "a")
    gcc -Wall -fpic -fno-stack-protector -z execstack oflow_partA.s -o oflow_partA
    ;;
  "B" | "b")
    gcc -Wall -fpic -fno-stack-protector -z execstack oflow_partB.s -o oflow_partB
    ;;
  "C" | "c")
    gcc -Wall -fpic -fno-stack-protector -z execstack oflow_partC.s -o oflow_partC
esac

if [ $? -eq 0 ]
then
  echo "Built."
else
  echo "Failed."
fi
