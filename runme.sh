#!/bin/bash

gcc myinit.c -o myinit;

touch /tmp/in
touch /tmp/out
touch /tmp/myconf

echo /bin/sleep 5 /tmp/in /tmp/out > /tmp/myconf
echo /bin/sleep 10 /tmp/in /tmp/out >> /tmp/myconf
echo /bin/sleep 15 /tmp/in /tmp/out >> /tmp/myconf


./myinit /tmp/myconf

sleep 1

echo First three tasks: > result.txt
ps -ef | grep "/bin/sleep 5" >> result.txt
ps -ef | grep "/bin/sleep 10" >> result.txt
ps -ef | grep "/bin/sleep 15" >> result.txt

pkill -f "/bin/sleep 15"

echo Three tasks after kill second task: >> result.txt
ps -ef | grep "/bin/sleep 5" >> result.txt
ps -ef | grep "/bin/sleep 10" >> result.txt
ps -ef | grep "/bin/sleep 15" >> result.txt

sleep 15

echo /bin/sleep 7 /tmp/in /tmp/out > /tmp/myconf

killall -HUP myinit

echo One task running: >> result.txt

ps -ef | grep "/bin/sleep" | grep -v grep >> result.txt

echo -e "LOGS:" >> result.txt

cat /tmp/myinit.log >> result.txt
killall myinit
