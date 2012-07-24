#!/bin/bash

# hacked better script, to source origin

# Out Error:
#   1 - SSH failed
#   2 - Nothing to backup! $WIKI_WEB_DIR does not exist.
#   3 - MySQL Dump failed


exec > /dev/null

# Definition of Variables

ERR_NUM=0
BKP_DIR="/var/www/mediawiki/backup"
BKP_DIR_ROOT=`echo "$BKP_DIR" | cut -c 2-`
WIKI_WEB_DIR="/var/www/mediawiki"
WIKI_WEB_DIR_ROOT=`echo "$WIKI_WEB_DIR" | cut -c 2-`

DB_SERV=`grep "wgDBserver" $WIKI_WEB_DIR/LocalSettings.php | cut -d\" -f2`
DB_NAME=`grep "wgDBname" $WIKI_WEB_DIR/LocalSettings.php | cut -d\" -f2`
DB_LOGIN=`grep "wgDBuser" $WIKI_WEB_DIR/LocalSettings.php | cut -d\" -f2`
DB_PASS=`grep '^\$wgDBpassword' $WIKI_WEB_DIR/LocalSettings.php | cut -d\" -f2`

SSH_HOST=""
SSH_LOGIN="backup"
SSH_DIR="/home/backup/mediawiki"


# Ensure backup directory exists

if [ ! -d $BKP_DIR ]; then
     mkdir -p $BKP_DIR;
fi

# Take a copy of the previous archive

if [ -a $BKP_DIR/mediawiki-backup.tar.bz2 ]; then
     rm -f $BKP_DIR/mediawiki-backup.tar.bz2.old
     mv $BKP_DIR/mediawiki-backup.tar.bz2 $BKP_DIR/mediawiki-backup.tar.bz2.old
fi

# Ensure wiki directory exists

if [ ! -d $WIKI_WEB_DIR ]; then
     ERR_NUM=2
     echo "Nothing to backup! $WIKI_WEB_DIR does not exist."
     exit $ERR_NUM
fi

# Tar a copy of the site directory

cd /; tar rvfh $BKP_DIR/mediawiki-backup.tar $WIKI_WEB_DIR_ROOT --exclude $BKP_DIR_ROOT

# Take a SQL dump, hehe

nice -n 19 mysqldump --single-transaction -u $DB_LOGIN --password=$DB_PASS $DB_NAME -c > $BKP_DIR/mediawiki.sql

# Ensure dump worked

MySQL_RET_CODE=$?
if [ $MySQL_RET_CODE != 0 ]; then
     ERR_NUM=3
     echo "MySQL Dump failed! (return code of MySQL: $MySQL_RET_CODE)"
     exit $ERR_NUM
fi


cd /; tar rvf $BKP_DIR/mediawiki-backup.tar $BKP_DIR_ROOT/mediawiki.sql

# Compress the archive

nice -n 19 bzip2 $BKP_DIR/mediawiki-backup.tar

# Send the archive on an other host

if [ `ssh $SSH_LOGIN@$SSH_HOST uname` ]; then
     scp $BKP_DIR/mediawiki-backup.tar.bz2 $SSH_LOGIN@$SSH_HOST:$SSH_DIR/
else
     ERR_NUM=1
     echo "SSH connection to scp the backup failed!"
     exit $ERR_NUM
fi

# Clean the files

rm -f $BKP_DIR/mediawiki-backup.tar
rm -f $BKP_DIR/mediawiki.sql

exit $ERR_NUM
