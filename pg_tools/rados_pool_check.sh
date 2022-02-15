#!/bin/bash
# Init a branch of objects, and then put them into a pool. In order to check choked osd(s).
# TODO fix param checks.

POOL_NAME=$1
OBJ_NUM=$2
DIR_NAME=$(dirname $0)

OBJ_LIST=object_list
OBJ_PATH=object_file

#dpkg -i libossp-uuid16_1.6.2-1.3ubuntu1_amd64.deb uuid_1.6.2-1.3ubuntu1_amd64.deb

if [ $# != 2 ]
then
    echo "USAGE: $0 pool_name object_num"
    echo " e.g.: $0 volumes 10"
    exit 1;
fi

mkdir -p $DIR_NAME/$OBJ_PATH

if [ -f $OBJ_LIST ]
then
    mv $OBJ_LIST $OBJ_LIST.`date +%s`
fi

for((id=1;id<=$OBJ_NUM;id++))
do 
    UUID=`uuidgen`
    OBJ_NAME=$OBJ_PATH/$UUID
    echo "0123456789" > $OBJ_NAME
    echo $UUID >>$OBJ_LIST

    start=`date +%s`
    echo "rados put object $id   start: $OBJ_NAME"
    rados put $OBJ_NAME -p $POOL_NAME $OBJ_NAME
    end=`date +%s`
    cost=`expr $end - $start`
    echo "rados put object $id   end:   $OBJ_NAME, cost: $cost"

done

