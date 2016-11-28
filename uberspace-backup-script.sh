#!/bin/bash
###Uberspace Backup-Script by Sebastian Neef
###www.gehaxelt.in
###Version 1.1
### More info:
## - http://www.gehaxelt.in/blog/update-backupscript-ueberspace-v1-1/
## - http://www.gehaxelt.in/blog/ueberspace-backupscript/

##Variables
USER='username' #Uberspacename
MYSQLPW='mysqlpw' #MySQL-Passwort
DATE=$(date +%d-%m-%Y)
DODELETE=TRUE
##For encryption
DOUPLOAD=FALSE
ENCRYPTPASS="encryption gpg pass"
EMAILTO="email to send downloadlink"
PLOWPATH="/home/$USER/bin"
## END Variables

for i in $*
do 
    if [ $i = "upload" ] 
    then
        DOUPLOAD=TRUE
    fi
    if [ $i = "deleteold" ]
    then 
        DODELETE=TRUE
    fi
done

##Check if directory backup exists and create it eventually
if [ ! -d /home/$USER/backup ]
    then
        mkdir /home/$USER/backup
    echo "Backup-folder created"
fi
##END Check

##Check if backup exists and exit
if [ -f /home/$USER/backup/backup-$DATE.tar.bz2 ]
    then
        echo "Backup already exists"
    exit 1
fi
##END Check


##Backup
mysqldump --user=$USER --password=$MYSQLPW --compact --comments --dump-date --quick --all-databases | gzip > "/var/www/virtual/"$USER"/database.sql.gz"
cd /var/www/virtual/$USER
tar -cjf /home/$USER/backup/backup-$DATE.tar.bz2 *
rm /var/www/virtual/$USER/database.sql.gz
##END Backup

if [ $DOUPLOAD ]
    then
    ##Encrypt with gpg
    echo "$ENCRYPTPASS" | gpg --passphrase-fd 0 --batch --no-tty -c /home/$USER/backup/backup-$DATE.tar.bz2
    ##END Encrypt

    ##Upload with plowup && mail
    $PLOWPATH/plowup -q mirrorcreator /home/$USER/backup/backup-$DATE.tar.bz2.gpg | mail -s "Backup Uberspace" $EMAILTO
    rm /home/$USER/backup/backup-$DATE.tar.bz2.gpg
    ## End Upload
fi

if [ $DODELETE ]
then
    ##Check if old backup exists
    YESTERDAY=$(date +%d-%m-%Y -d"1 day ago")
    if [ -f /home/$USER/backup/backup-$YESTERDAY.tar.bz2 ]
    then
        rm  /home/$USER/backup/backup-$YESTERDAY.tar.bz2
    fi
    ##END Yesterday delete
fi