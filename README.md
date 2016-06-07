# docker-dr-elephant
LinkedIn dr-elephant tool in a ready to go container

LinkedIn dr-elephant is a useful solution that gives recommandations 
to the Data engineers that use Hadoop MapReduce and Spark.
More info can be found here : https://github.com/linkedin/dr-elephant

# How to run it ?
Dr-elephant needs a MySql backend.
The easiest way to achieve it is to link the container with a official MySql image.

docker pull mysql:latest

docker run --name mysql-drelephant \
    -e MYSQL_ROOT_PASSWORD=drelephant \
    -e MYSQL_DATABASE=drelephant \
    -e MYSQL_USER=drelephant \
    -e MYSQL_PASSWORD=drelephant \
    -d mysql

Build the dr-elephant image with an internet connectivity

docker build -t edf/dr-elephant .

Then run our dr-elephant on a server having the hadoop client libs ..

docker run --name drelephant 
   --link mysql-drelephant:mysql  \
   -e HADOOP_HOME='/usr/hdp/current/hadoop-client' \
   -e HADOOP_CONF_DIR='/etc/hadoop/conf' \
   -e http_port='8080' \
   -e keytab_user='' \
   -e keytab_location='' \
   -e ELEPHANT_CONF_DIR='/etc/drelephant/conf' \
   -v /etc/drelephant/conf:/usr/dr-elephant/app-conf \
   -d edf/dr-elephant


