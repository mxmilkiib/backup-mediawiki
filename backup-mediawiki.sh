#!/bin/bash

# still buggy, use with extreme caution
# modified from https://serom.eu/index.php/Backup_du_SeRoM_Wiki
# cc: by, sa

# Out Error:
#   1 - SSH failed
#   2 - Nothing to backup! $WIKI_WEB_DIR does not exist.
#   3 - MySQL Dump failed


exec > /dev/null

# Definition of Variables
ERR_NUM=0
BKP_DIR="/home/backupwiki/mediawiki"
WIKI_WEB_DIR="/var/www/wiki.thingsandstuff.org"

DB_SERV=`grep "wgDBserver" $WIKI_WEB_DIR/LocalSettings.php | cut -d\" -f2`
DB_NAME=`grep "wgDBname" $WIKI_WEB_DIR/LocalSettings.php | cut -d\" -f2`
DB_LOGIN=`grep "wgDBuser" $WIKI_WEB_DIR/LocalSettings.php | cut -d\" -f2`
DB_PASS=`grep '^\$wgDBpassword' $WIKI_WEB_DIR/LocalSettings.php | cut -d\" -f2`

# SSH_HOST=""
# SSH_LOGIN="backup"
# SSH_DIR="/home/backup/mediawiki"
# SSH_PORT="21"


# Ensure backup directory exists
if [ ! -d $BKP_DIR ]; then
     mkdir -p $BKP_DIR;
fi

# Ensure wiki directory exists
if [ ! -d $WIKI_WEB_DIR ]; then
     ERR_NUM=2
     echo "Nothing to backup! $WIKI_WEB_DIR does not exist."
     exit $ERR_NUM
fi

# Take a copy of the previous archive
if [ -a $BKP_DIR/archivedwiki/mediawiki-backup.tar ]; then
                 rm -f $BKP_DIR/mediawiki-backup.tar.old
                 mv $BKP_DIR/archivedwiki/mediawiki-backup.tar $BKP_DIR/mediawiki-backup.tar.old
fi


# Take a SQL dump, hehe
echo "Compressing SQL"
nice -n 19 mysqldump --single-transaction -u $DB_LOGIN --password=$DB_PASS $DB_NAME -c | xz > $BKP_DIR/mediawiki-sql-backup.xz

# Ensure dump worked
MySQL_RET_CODE=$?
if [ $MySQL_RET_CODE != 0 ]; then
     ERR_NUM=3
     echo "MySQL Dump failed! (return code of MySQL: $MySQL_RET_CODE)"
     exit $ERR_NUM
fi

# Tar a copy of the site directory
echo "Compressing site files"
nice -n 19 tar cJf $BKP_DIR/mediawiki-php-backup.xz $WIKI_WEB_DIR/

# Add compressed sql to site archive
echo "Archiving SQL and site, removing tmp files"
nice -n 19 tar -c --remove-files -f $BKP_DIR/mediawiki-backup.tar $BKP_DIR/mediawiki-sql-backup.xz $BKP_DIR/mediawiki-php-backup.xz

# Send the archive on an other host
# if [ `ssh -p $SSH_PORT $SSH_LOGIN@$SSH_HOST uname` ]; then
#      scp -P $SSH_PORT $BKP_DIR/mediawiki-backup.tar.bz2 $SSH_LOGIN@$SSH_HOST:$SSH_DIR/
# else
#      ERR_NUM=1
#      echo "SSH connection to scp the backup failed!"
#      exit $ERR_NUM
# fi
# 
# or use a cron job
# see also: https://github.com/andreafabrizi/Dropbox-Uploader

# Move archived wiki to folder on it's own
if [ -a $BKP_DIR/mediawiki-backup.tar ]; then
        mv $BKP_DIR/mediawiki-backup.tar $BKP_DIR/archivedwiki/mediawiki-backup.tar
fi

exit $ERR_NUM
