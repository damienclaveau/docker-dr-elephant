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
    -v /my/own/datadir:/var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD=drelephant \
    -e MYSQL_DATABASE=drelephant \
    -e MYSQL_USER=drelephant \
    -e MYSQL_PASSWORD=drelephant \
    -d mysql:latest

Build the dr-elephant image with an internet connectivity

docker build -t dr-elephant:2.0.6 .

Then run our dr-elephant on a server having the hadoop client libs ..

docker run --name drelephant \
 --link mysql-drelephant:mysql \
 -p 8080:8080 \
 -e http_port='8080' \
 -e keytab_user='' \
 -e keytab_location='' \
 -v /etc/krb5.conf:/etc/krb5.conf \
 -v /etc/hadoop/conf:/etc/hadoop/conf \
 -v /etc/dr-elephant/conf:/usr/dr-elephant/app-conf \
 -v /var/log/dr-elephant:/usr/dr-elephant/logs \
 -d dr-elephant:2.0.6


