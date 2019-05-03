#!/bin/bash

# general script to dump SQL results, 
# transform into CSV and move copy to S3
PROG=$(basename $0)
PROG=`echo $PROG| awk -F. '{ print $1 }'`

NOW=`date +%s`

POSTGRES_USER="##POSTGRES_USER##"
POSTGRES_PASS="##POSTGRES_PASSWORD##"
POSTGRES_HOST="##POSTGRES_HOST##"
POSTGRES_PORT=5432

MYSQL_USER="##MYSQL_USER##"
MYSQL_PASS="##MYSQL_PASSWORD##"
MYSQL_HOST="##MYSQL_HOST##"

# Define usage information
USAGE="Usage: ./$PROG.sh [-h <host>] [-d <db>] [-s <sql file to run>] [-p <aws profile>] [-b <full path to s3 bucket> ]"

# Parse the command line arguments:
while getopts h:d:s:b:p: c ; do
  case $c in
    h)  HOST="${OPTARG}" ;;
    d)  DB="${OPTARG}" ;;
    s)  SQL="${OPTARG}" ;;
    b)  BUCKET="${OPTARG}" ;;
    p)  PROFILE="${OPTARG}" ;;
    *)  echo "$USAGE" ; exit 2 ;;
  esac
done

if [ -z $HOST ] || [ -z $DB ] || [ -z $SQL ] || [ -z $BUCKET ] || [ -z $PROFILE ]; then
    echo -e $USAGE;
    exit;
else
    OUTFILE=$SQL-$NOW.csv
    if [ "$HOST" = "postgres" ]; then
        PGPASSWORD=$POSTGRES_PASS psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $DB -p $POSTGRES_PORT -A -t -F',' -f $SQL -o $OUTFILE
    elif [ "$HOST" = "mysql" ]; then
        mysql -u$MYSQL_USER -h$MYSQL_HOST -p -A $DB < $SQL | sed 's/\t/,/g;s/\n//g' > $OUTFILE
    else
        echo "Unknown host: $HOST"
    fi
    if [ -f $OUTFILE ]; then
        # copy to s3
        aws --profile=$PROFILE s3 cp $OUTFILE $BUCKET
        rm -f $OUTFILE
    fi
fi
