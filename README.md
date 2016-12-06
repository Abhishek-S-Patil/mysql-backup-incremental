# MySQL Incremental Backup
This bash script will allow you to do daily *(incremental as well as full)* backups of a MySQL database.

### MYSQLDUMP
[`mysqldump`](http://dev.mysql.com/doc/refman/5.7/en/mysqldump.html) is a utility program that reads databases and generates the mysql statements necessary to completely rebuild the databases. It can be used to make a full backup of one or more databases in a single operation.

### BINARY LOG FILES
Mysql can be configured to generate "binary logs." A mysql binary log file in an incremental backup. It contains the mysql  statements needed to update the database since the last full or incremental backup.

#### The backup strategy is:
1. Generate a full backup of databases with mysqldump. This full backup is compressed and backed-up to specified path on server.
2. With binary logging enabled, every mysql action which modifies the database after the full backup is stored in the current binary log file.
3. Every 6 hours (configurable), the current binary log file is closed, and is backed-up on server. A new binary log file is created to continue to record changes to the databases.
4. Step 3 is repeated.  Once per week, a new full backup is created (step 1), and all binary log files are purged. The previous full backup and the now-obsolete binary log files are deleted from the backup server.

#### The restore strategy is:
1. The full backup and all binary log files are copied to the server where the databases are to be recreated (the databases will be created if they do not exist.) The full backup is restored.
2. Apply the incremental database changes contained in each binary log file, consecutively. The utility programs *"mysqladmin"* and *"mysqlbinlog"* are used for this. This brings the databases up-to-date to the moment of the latest incremental backup.

### Utility Programs
* [mysqldump](http://dev.mysql.com/doc/refman/5.7/en/mysqldump.html) and [mysqladmin](http://dev.mysql.com/doc/refman/5.7/en/mysqladmin.html) are part of the mysql-client-x.x package
* [mysqlbinlog](http://dev.mysql.com/doc/refman/5.7/en/mysqlbinlog.html) is part of the mysql-server-x.x package

### Prerequisites
#### Configure MySQL to do binary logging
Find and edit the file:
```sh
/etc/mysql/mysql.conf.d/mysqld.cnf
```
Uncomment the following lines save and exit:
```
#The following can be used as easy to replay backup logs or for replication.
#note: if you are setting up a replication slave, see README.Debian about
#other settings you may need to change.
server-id		= 1
log_bin			= /var/log/mysql/binlog.log 
expire_logs_days	= 10
max_binlog_size   = 100M
```
You can specify which databases to do binary logging for, or which databases NOT to do binary logging for.
*"binlog_do_db"* turns binary logging on for a given database. If this statement is used, all databases not specifically named will have binary logging turned off. Multiple statements can be made, one to a line:
```
binlog_do_db = mydb
binlog_do_db = testdb
```
Alternatively, you can use the statement binlog_ignore_db. This statements turns binary logging on for all databases EXCEPT the database(s) names. Again, you can make several binlog_ignore_db statements, one to a line:
```
binlog_ignore_db  = otherdb
binlog_ignore_db  = uselessdb
```
If you have applications that use more than one database, you should be careful when using either binlog_do_db or binlog_ignore_db.  If you have doubts, you should read [The Binary Log](http://dev.mysql.com/doc/refman/5.0/en/binary-log.html)

#### Restart MySQL Server
```sh
sudo service mysql restart
```
#### Fields need to be set in the file:
Field            | Description                                                                 | Example
-----------------| ----------------------------------------------------------------------------|-----------------------------
DBNAME           | Database name to specify a specific database only e.g. myawesomeapp. Use space to give more databases names e.g. nmsdb mydb admin sqldb testdb        |  DBNAME="nmsdb testdb" 
DBUSERNAME       | Username to access the MySQL server e.g. root                               | DBUSERNAME="root"
DBPASSWORD       | Password to access the MySQL server e.g. password                           | DBPASSWORD="password"
DBHOST           | Host name (or IP address) of MySQL server e.g localhost                     | DBHOST="127.0.0.1"
DUMPBACKUPDIR    | Backup directory location for MySqlDumps e.g /backups                       | DUMPBACKUPDIR="/var/lib/mysql"
BLOGSBACKUPDIR   | Backup directory location for MySqlDumps e.g /backups                       | BLOGSBACKUPDIR="/var/log/mysql"
RESTOREBACKUPDIR | Restore directory location for MySqlDumps and Binary Files                  | RESTOREBACKUPDIR="~/sqlbackups

### Running the script

There are two methods to run this script, One is to run with cron jobs and other is to execute within terminal.
> Note: Make sure file has executable permissions.

#### Executing in terminal

```sh
$ ./mysqlbinlog.sh  
```
This command runs the script in normal mode. If the *"full backup"* Day matches the *“DUMPDAY”* field, then full backup will ve perfromed otherwise binary logs will be updated.

```sh
$ ./mysqlbinlog.sh dump 
```
This command explicitly provides “dump” as argument to force full backup.

```sh
$ ./mysqlbinlog.sh restore 
```
This command explicitly provides “restore” as argument to run the program in restoring mode.

#### Setting cron job:
Linux Crontab Format
```
MIN HOUR DOM MON DOW CMD
```
Table: Crontab Fields and Allowed Ranges (Linux Crontab Syntax)

Field         | Description   | Allowed Value
------------- | ------------- | -------------
MIN           | Minute field  | 0 to 59
HOUR          | Hour field    | 0 to 23 (0 is midnight)
DOM           | Day of Month  | 1-31
MON           | Month field   | 1-12
DOW           | Day Of Week   | 0-6
CMD           | Command       | Any command to be executed

##### Example:


```sh
00 0 * * * CMD
```
This line will schedule a command or job to execute at 12.00 (midnight) everyday.

```sh
00 */6 * * * CMD
```
This line will schedule a command or job to execute every 6 hours.

##### Steps to create cron job:

> Note:
>
> As cron jobs are particular for particular users, log in with the user from which you want to create the job.
> If you want to execute .sh files please make sure you give execute permissions to that particular file with following command

```sh
sudo chmod +x <fileName>
```

* Open Terminal

* Type crontab -e

* append below command at bottom of the file

```sh
00 0 * * * /home/downloads/mysqlbinlog.sh
```

* Save and exit.

##### TroubleShoot cron job:

* To check whether job is added or not type following command

```sh
crontab -l
```

* To check the logs whether cron has executed the file, find logs in /var/log/syslog












  
