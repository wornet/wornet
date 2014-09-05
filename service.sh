#!/bin/bash
DAEMON_PATH="/var/www/nodejs/wornet/int"
DAEMON="nodemon index.coffee"
PORT=8002
NODE_ENV=production
DAEMONOPTS="PORT=$PORT NODE_ENV=$NODE_ENV"
NAME=wornetint
DESC="Control Wornet Integration"
PIDFILE=/var/run/$NAME.pid
LOGFILE=/var/log/$NAME.log
SCRIPTNAME=/etc/init.d/$NAME

case "$1" in
cleanlog)
        echo "" > $LOGFILE
        ;;
update)
        cd $DAEMON_PATH
        git pull http://deployer:xdaRNvqq@git.wornet.com/Bastien/wornet.git
        $0 restart
        ;;
start)
        printf "%-50s" "Starting $NAME..."
        cd $DAEMON_PATH
        echo "$DAEMONOPTS $DAEMON"
git pull http://deployer:xdaRNvqq@git.wornet.com/Bastien/wornet.git     export PORT=$PORT
        export NODE_ENV=$NODE_ENV
        ID=`$DAEMON >> $LOGFILE 2>&1 & echo $!`
        echo "Saving PID" $PID " to " $PIDFILE
        if [ -z $PID ]; then
            printf "%s\n" "Fail"
        else
            echo $PID > $PIDFILE
            printf "%s\n" "Ok"
        fi ;;
status)
        printf "%-50s" "Checking $NAME..."
        if [ -f $PIDFILE ]; then
            PID=`cat $PIDFILE`
            if [ -z "`ps axf | grep ${PID} | grep -v grep`" ]; then
                printf "%s\n" "Process dead but pidfile exists"
            else
                echo "Running"
            fi
        else
            printf "%s\n" "Service not running"
        fi ;;
stop)
        printf "%-50s" "Stopping $NAME"
            PID=`cat $PIDFILE`
            cd $DAEMON_PATH
        if [ -f $PIDFILE ]; then
            kill -15 $PID
            while ps -p $PID; do sleep 0.5; done;
            printf "%s\n" "Ok"
            rm -f $PIDFILE
        else
            printf "%s\n" "pidfile not found"
        fi ;;
restart)
        $0 stop
        $0 start ;;
*)
        echo "Usage: $0 {status|start|stop|restart}"
        exit 1
esac

