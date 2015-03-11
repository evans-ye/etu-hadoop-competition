#!/bin/bash
echo "[32;1mUSER=$(whoami)[0m"

## It cause problem for HBase .... can not connet to 127.0.1.1:60020
sudo su -s /bin/bash root -c "echo \"127.0.0.1 localhost $(hostname)\" > /etc/hosts"

## backup centos official repos
sudo mkdir /etc/yum.repos.d.bak;
sudo mv /etc/yum.repos.d/* /etc/yum.repos.d.bak/

## setup centos cloned repository
sudo su -s /bin/bash root -c "cat > /etc/yum.repos.d/centos64.repo << EOF
[centos64-os]
name=centos64-os
baseurl=http://etu-centos64.s3.amazonaws.com/centos/Packages
enabled=1
gpgcheck=0
priority=1

[centos64-update]
name=centos64-update
baseurl=http://etu-centos64.s3.amazonaws.com/centos/update
enabled=1
gpgcheck=0
priority=1
EOF
"

## setup bigtop related yum repository
sudo yum install -y vim unzip wget java-1.7.0-openjdk-devel.x86_64
sudo su -s /bin/bash root -c "cat > /etc/yum.repos.d/bigtop.repo << EOF
[bigtop]
name=bigtop
baseurl=http://etu-bigtop.s3.amazonaws.com/bigtop0.7/bigtop
enabled=1
gpgcheck=0
priority=1
EOF
"

## pre-download the test samples
wget http://www.hadoop.tw/excite-small.log -O /tmp/excite-small.log &
wget http://seanlahman.com/files/database/lahman2012-csv.zip -O /tmp/lahman2012-csv.zip &

## install bigtop related packages
sudo yum install -y bigtop-utils hadoop-conf-pseudo hive pig hbase hive-hbase hbase-master hbase-regionserver  zookeeper

## format NameNode
sudo /etc/init.d/hadoop-hdfs-namenode init

## enable HBase with ZooKeeper
sudo su -s /bin/bash root -c "cat > /etc/hbase/conf/hbase-site.xml << EOF
<?xml version=\"1.0\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
  <property>
      <name>hbase.rootdir</name>
      <value>hdfs://localhost:8020/hbase</value>
  </property>
  <property>
      <name>hbase.tmp.dir</name>
      <value>/var/hbase</value>
  </property>
  <property>
      <name>hbase.cluster.distributed</name>
      <value>true</value>
  </property>
</configuration>
EOF
"

## start HDFS
for i in hadoop-hdfs-namenode hadoop-hdfs-datanode ; do sudo service $i start ; done

## initialize HDFS
echo "[32;1mCreating hdfs directories[0m"
#sudo ./cust-init-hdfs.sh || sudo /usr/lib/hadoop/libexec/init-hdfs.sh
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -mkdir -p /tmp /var/log /tmp/hadoop-yarn /var/log/hadoop-yarn/apps /hbase /benchmarks /user /user/history /user/hive /user/root'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chmod -R 1777 /tmp'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chmod -R 1775 /var/log'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chown yarn:mapred /var/log'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chown -R mapred:mapred /tmp/hadoop-yarn'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chmod -R 777 /tmp/hadoop-yarn'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chmod -R 1777 /var/log/hadoop-yarn/apps'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chown yarn:mapred /var/log/hadoop-yarn/apps'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chown hbase:hbase /hbase'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chmod 755 /user /user/history'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chown hdfs /user'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chown mapred:mapred /user/history'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chmod -R 777 /user/hive /user/root /benchmarks'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chown hive /user/hive'
sudo su -s /bin/bash hdfs -c '/usr/bin/hadoop fs -chown root /user/root'
# Create home directory for the current user if it does not exist
USER=${USER:-$(id -un)}
EXIST=$(sudo su -s /bin/bash hdfs -c "/usr/bin/hadoop fs -ls /user/${USER}" &> /dev/null; echo $?)
if [ ! $EXIST -eq 0 ]; then
  sudo su -s /bin/bash hdfs -c "/usr/bin/hadoop fs -mkdir /user/${USER}"
  sudo su -s /bin/bash hdfs -c "/usr/bin/hadoop fs -chmod -R 755 /user/${USER}"
  sudo su -s /bin/bash hdfs -c "/usr/bin/hadoop fs -chown ${USER} /user/${USER}"
fi

## start ZooKeeper
sudo mkdir -p /var/run/zookeeper && sudo chown zookeeper:zookeeper /var/run/zookeeper
sudo su -s /bin/bash zookeeper -c "zookeeper-server-initialize"
sudo su -s /bin/bash zookeeper -c "zookeeper-server start"

## start YARN and HBase
for i in hadoop-yarn-resourcemanager hadoop-yarn-nodemanager hadoop-mapreduce-historyserver hbase-master hbase-regionserver ; do sudo service $i start ; done

## Fix YARN staging folder permission issues
# ERROR security.UserGroupInformation: PriviledgedActionException as:root (auth:SIMPLE) 
#  cause:org.apache.hadoop.security.AccessControlException: Permission denied: 
#  user=root, access=EXECUTE, inode="/tmp/hadoop-yarn/staging":mapred:mapred:drwxrwx---
sudo su -s /bin/bash hdfs -c "hadoop fs -chmod -R 777 /tmp/hadoop-yarn/staging"

## run mapreduce for function test 
#sudo su -s /bin/bash hdfs -c "hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar pi 2 2"

## run HDFS test case
(
dd if=/dev/zero of=100mb.img bs=1M count=100
hadoop fs -put 100mb.img test.img
) >> hdfs.log 2>&1 &

## run hbase test case
(
cat > /tmp/hbase_test << EOF
create 't1','f1'
put 't1','r1','f1','v1'
put 't1','r1','f1','v2'
put 't1','r1','f1:c1','v2'
put 't1','r1','f1:c2','v3'
scan 't1'
quit
EOF
hbase shell /tmp/hbase_test
) >> hbase.log 2>&1 &

## run pig test case
(
#wget http://www.hadoop.tw/excite-small.log -O /tmp/excite-small.log
hadoop fs -put /tmp/excite-small.log /tmp/excite-small.log
cat > /tmp/pig_test.pig << EOF
log = LOAD '/tmp/excite-small.log' AS (user, timestamp, query);
grpd = GROUP log BY user;  
cntd = FOREACH grpd GENERATE group, COUNT(log) AS cnt;
fltrd = FILTER cntd BY cnt > 50;      
srtd = ORDER fltrd BY cnt;
STORE srtd INTO '/tmp/pig_output';
EOF
pig /tmp/pig_test.pig
) >> pig.log 2>&1 &

## run hive test case
(
#wget http://seanlahman.com/files/database/lahman2012-csv.zip -O /tmp/lahman2012-csv.zip
( cd /tmp; unzip /tmp/lahman2012-csv.zip )
cat > /tmp/hive_test.hql << EOF
create database baseball;
create table baseball.master 
( lahmanID INT, playerID STRING, managerID INT, hofID STRING,  
  birthYear INT, birthMonth INT, birthDay INT, birthCountry STRING,  
  birthState STRING, birthCity STRING, deathYear INT, deathMonth INT, 
  deathDay INT, deathCountry STRING, deathState STRING, deathCity STRING, 
  nameFirst STRING, nameLast STRING, nameNote STRING, nameGiven STRING, 
  nameNick STRING, weight INT, height INT, bats STRING, throws STRING, 
  debut STRING, finalGame STRING, college STRING, lahman40ID STRING, 
  lahman45ID STRING, retroID STRING, holtzID STRING, bbrefID STRING ) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' ;
LOAD DATA LOCAL INPATH '/tmp/Master.csv' OVERWRITE INTO TABLE baseball.master;
select * from baseball.master LIMIT 10;
quit;
EOF
hive -f /tmp/hive_test.hql
) >> hive.log 2>&1 &
wait

echo "[32;1mFinished Deployment[0m"
read
sudo /usr/local/bin/send_my_score
