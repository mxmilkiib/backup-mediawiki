backup-mediawiki
================

backup-mediawiki backs up MediaWiki files and DB and sends to a remote machine.

Setup requires ACL and SSH key setup.
* Create backup user
* Read only ACL access to www dir (setfacl -Rdm u:backupuser:r /var/www/wiki.example.org)
* Put backup script in back user home
* Configure
* Setup key and remote
* Setup cron

See https://github.com/milkmiruku/backup-mediawiki-remote for remote code.  
