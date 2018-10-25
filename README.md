backup-mediawiki
================

backup-mediawiki backs up MediaWiki files and DB and sends to a remote machine.

Setup requires ACL and SSH key setup.
* Create backup user
* Give backup user ACL access to www subdir (`setfacl -Rdm u:backupuser:r /var/www/wiki.example.org`)
* Put backup script in backup user home
* Configure path in script
* Give script executable permission
* Setup crontab entry
* Optional: Setup SSH key
* Optional: Or setup Syncthing or similar

See https://github.com/milkmiruku/backup-mediawiki-remote for remote code.  
