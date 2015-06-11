#!/bin/bash
#DAEMON_PATH="/var/www/nodejs/wornet/int"
DAEMON_PATH="/home/serveur/www/nodejs/wornet/int"
DAEMON="/usr/bin/nodemon -x ./node_modules/.bin/coffee ./index.coffee"
PORT=8002
NODE_ENV=production
#NODE_ENV=development
DEAMONUSER=gitlab-runner
DAEMONOPTS="sudo -u $DEAMONUSER -H PORT=$PORT NODE_ENV=$NODE_ENV"
APPNAME=wornet
APPSUFFIX=int
NAME=$APPNAME$APPSUFFIX
DESC="Control Wornet Integration"
PIDFILE=/var/run/$NAME.pid
LOGFILE=/var/log/$NAME.log
LOGCOFFEE=/var/log/$NAME-coffee.log
PIDCOFFEE=/var/run/$NAME-coffee.pid
SCRIPTNAME=/etc/init.d/$NAME

case "$1" in
cleanlog)
    echo "" > $LOGFILE
    echo "" > $LOGCOFFEE
    ;;
update)
    cd $DAEMON_PATH
    sudo -u $DEAMONUSER -H git pull
    npm i
    chmod -R 0777 public/img/photo
    NEW=`date +"%Y-%m-%d-%H-%M-%S"`
    sed "s/{VERSION}/$NEW/g" /home/config/custom.json > ./config/custom.json
    $0 restart
    ;;
start)
    printf "%-50s" "Starting $NAME..."
    cd $DAEMON_PATH
    echo "$DAEMONOPTS $DAEMON"
    export PORT
    export NODE_ENV
    sudo -u $DEAMONUSER -H rm .build/css/*
    sudo -u $DEAMONUSER -H rm .build/js/*
    COF=`sudo -u $DEAMONUSER -H ./node_modules/.bin/coffee -bc -o .build/js/ --join app public/js/app/ >> $LOGCOFFEE 2>&1 & echo $!`
    PID=`$DAEMONOPTS $DAEMON >> $LOGFILE 2>&1 & echo $!`
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
