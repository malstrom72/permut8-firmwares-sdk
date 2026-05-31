#!/bin/bash
cd "${0%/*}"

echo
echo "*** Any impala file in this directory will now be recompiled automatically. ***"
echo

for ((;;)); do
	for FILE in *.impala; do
		if [ "$FILE" -nt "${FILE%.impala}.gazl" ]; then
			echo Compiling $FILE...
			./PikaCmd impala.pika compile "$FILE" "${FILE%.impala}.gazl"
		fi
	done
	sleep 0.1
done
