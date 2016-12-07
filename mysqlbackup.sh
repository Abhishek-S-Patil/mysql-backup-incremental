#!/bin/bash
#=====================================================================
#=====================================================================
# Set the following variables to your system needs
# (Detailed instructions below variables)
#=====================================================================

# Database names to specify a specific database only e.g. myawesomeapp
# Use space to give more databases names e.g. nmsdb mydb admin sqldb testdb
 DBNAME="nmsdb"

# Username to access the Mysql server e.g. root
 DBUSERNAME="root"

# Password to access the Mysql server e.g. password
 DBPASSWORD="root"


# Host name (or IP address) of MySql server e.g localhost
DBHOST="127.0.0.1"

# Backup directory location for MySqlDumps e.g /backups
DUMPBACKUPDIR="/var/lib/mysql"

# Backup directory location for MySql Binary Logs e.g /backups
BLOGSBACKUPDIR="/var/log/mysql"

# Binary Log File name
BINFILENAME="mybinlog"

# ============================================================================
# === SCHEDULING OPTIONS ( Read the doc's below for details )===
#=============================================================================

# Which Day do you want to take dumps ? e.g Monday
DUMPDAY="Sunday"

# On what hour you want to take dumps? e.g 1 - 24
DUMPHOUR="12"

#=====================================================================
# Restoring
#=====================================================================
# Please provide command line argument as "restore" to start restore process.
# Please extract the .bz2 files in this directory if you wish to restore the database.
# Please keep the extracted .sql and Binary Log files only as this algorithm is designed to work on single .sql and binary files.

# Restore directory location for MySqlDumps and Binary Files e.g /restoreBackups
RESTOREBACKUPDIR="/home/user/sqlbackups"

#=====================================================================
# Please Note!!
#=====================================================================
# To force Dump please provide command line argument as "dump"
#=====================================================================
#=====================================================================
#=====================================================================
#
# Should not need to be modified from here down!!
#
#=====================================================================
#=====================================================================
#=====================================================================

function disp(){
echo "Command					$CMD_PARAM"
echo "Host					$HOST_PARAM"
echo "User Name				$USERN_PARAM"
echo "Password				$PASSWD_PARAM"
echo "Database				$DBNAME_PARAM"
echo "Dump Directory				$DUMPDIR_PARAM"
echo "BinaryLogs Directory			$BINLOGDIR_PARAM"
echo "To Dump Day				$DUMPDAY_PARAM"
echo "To Dump Hour				$DUMHOUR_PARAM"
echo "Restore Directory			$RESTOREDIR_PARAM"
echo "BinaryLog file Name			$BINFILE_PARAM"
}

function usage ()
{
  echo 'Usage : Script -c <command> -h <host> -u <user> -p <password> -db <databaseName>' 
  echo '	       -b <binaryLogFileName> -dp <dumpPath> -bl <binaryLogFileLocation>'
  echo '	       -r <restoreLocation> -day <day> -hour <hour> -help'
  echo '-----------------------------------------------------------------------------------'
  echo '-help, --help          Display this help and exit.'
  echo '-c, --command          External command to run e.g. dump or restore.'
  echo '-h, --host     	       Connect to host.'
  echo '-u, --user  	       User for login.'
  echo '-p, --password         Password to use when connecting to server. If password is not given it''s asked from the tty.' 
  echo '-db, --database        Database to use.'
  echo '-b, --binFileName      Binary Log File name.'
  echo '-dp, --dumpPath        Dump directory location.'
  echo '-bl, --binPath         Binary Log File directory location.'
  echo '-r, --restorePath      Restore directory location.'
  echo '-day, --day            Day e.g Monday or Sunday.'
  echo '-hour, --hour          Hour e.g 12 or 15.'
  exit
}
if [ $# -eq 0 -o $# -le 11 ] ; then
CMD_PARAM=defaults
HOST_PARAM=$DBHOST
USERN_PARAM=$DBUSERNAME
PASSWD_PARAM=$DBPASSWORD
DBNAME_PARAM=$DBNAME
DUMPDIR_PARAM=$DUMPBACKUPDIR
BINLOGDIR_PARAM=$BLOGSBACKUPDIR
DUMPDAY_PARAM=$DUMPDAY
DUMHOUR_PARAM=$DUMPHOUR
RESTOREDIR_PARAM=$RESTOREBACKUPDIR
BINFILE_PARAM=$BINFILENAME
fi

while [ $# -gt 0 ]; do
  case "$1" in
    "-c" | "--command") 	shift 
							CMD_PARAM=${1:-defaults}
      				    	;;
   "-h" | "--host") 		shift
      						HOST_PARAM=${1:-$DBHOST}
	  			    		;;
	"-u" | "--user") 		shift
      						USERN_PARAM=${1:-$DBUSERNAME}
	  			    		;;
	"-p" | "--password") 	shift
      						PASSWD_PARAM=${1:-$DBPASSWORD}
	  			    		;;
	"-db" | "--database") 	shift
      						DBNAME_PARAM=${1:-$DBNAME}
	  			    		;;
	"-b" | "--binFileName") shift
      						BINFILE_PARAM=${1:-$BINFILENAME}
	  			    		;;
	"-dp" | "--dumpPath") 	shift
      						DUMPDIR_PARAM=${1:-$DUMPBACKUPDIR}
	  			    		;;
	"-bl" | "--binPath") 	shift
      						BINLOGDIR_PARAM=${1:-$BLOGSBACKUPDIR}
	  			    		;;
	"-r" | "--restorePath") shift
      						RESTOREDIR_PARAM=${1:-$RESTOREBACKUPDIR}
	  			    		;;
	"-day" | "--day") 		shift
      						DUMPDAY_PARAM=${1:-$DUMPDAY}
	  			    		;;
	"-hour" | "--hour") 	shift
      						DUMHOUR_PARAM=${1:-$DUMPHOUR}
	  			    		;;
	"-help" | "--help") 	usage      						
	  			    		;;
								
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
	  usage
      
  esac
  shift
done

echo "Executing with following user options:"
disp

 
echo "Creating MySQL new binary log at `date`"
if [ "$CMD_PARAM" == "restore" ]; then
	echo "Restoring started `date`"
	echo "Taking Dump Files and BinaryLog Files from $RESTOREDIR_PARAM"
		for restoreDumpFile in `ls $RESTOREDIR_PARAM/*.sql | sort -V -r | head -n1`
			do
				mysql -u$USERN_PARAM -h$HOST_PARAM -p$PASSWD_PARAM < $restoreDumpFile
				echo "restored Dumps Successfully !!!"
			done
		for restoreBinLogFile in `ls $RESTOREDIR_PARAM/$BINFILE_PARAM*.* |sort -V | grep -v '\.bz2'`
			do 
				mysqlbinlog $restoreBinLogFile |mysql -u$USERN_PARAM -h$HOST_PARAM -p$PASSWD_PARAM
				echo "restored Binary Log File: $restoreBinLogFile"
			done
echo "Restore Completed !!!"
else

if [ `date +%A` == $DUMPDAY_PARAM -a `date +%H` == $DUMHOUR_PARAM -o "$CMD_PARAM" == "dump" ]; then
        echo "Weekly Backup started `date`"
        echo "Full mysql database dump started"
        echo 'All existing full backups and binary log files will be removed'
        PREFIX='mysql-dump.'
        DT=`date "+%m%d%y"`
        DBFN=$PREFIX$DT'.sql'

        rm -f $DUMPDIR_PARAM/*.bz2

        mysqldump -u$USERN_PARAM -h$HOST_PARAM -p$PASSWD_PARAM --flush-logs --delete-master-logs --master-data=2 --add-drop-table --lock-all-tables --databases $DBNAME_PARAM  > $DUMPDIR_PARAM/$DBFN
        bzip2 $DUMPDIR_PARAM/$DBFN
        echo "MySQL Dump Completed !!!"
		echo "Please find the .bz2 Dump File in $DUMPDIR_PARAM/$DBFN"
else
       echo "starting new bin log"
	   oldestlog=`ls -d $BINLOGDIR_PARAM/$BINFILE_PARAM.?????? | sed 's/^.*\.//' | sort -g | tail -n 1`
	   mysqladmin -u$USERN_PARAM -h$HOST_PARAM -p$PASSWD_PARAM flush-logs
fi
newestlog=`ls -d $BINLOGDIR_PARAM/$BINFILE_PARAM.?????? | sed 's/^.*\.//' | sort -g | tail -n 1`
for file in `ls $BINLOGDIR_PARAM/$BINFILE_PARAM.??????`
do
        if [ "$BINLOGDIR_PARAM/$BINFILE_PARAM.$newestlog" != "$file" ]; then
                bzip2 "$file"
				echo "Please find the .bz2 Binary Log File in $BINLOGDIR_PARAM/$BINFILE_PARAM.$oldestlog"
        fi
done

echo "Bin Logs backed up !!!"
fi

