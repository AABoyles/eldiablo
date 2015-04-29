#!/usr/bin/env bash

echo "Installing Base Dependencies..." 
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get -y install zip unzip curl zlib1g-dev git g++ default-jre libxml2-dev libxslt1-dev python-dev python-pip mongodb-10gen htop openjdk-7-jre openjdk-7-jdk maven tomcat7
sudo apt-get -y upgrade

echo "Downloading Phoenix Pipeline..."
git clone https://github.com/openeventdata/scraper.git
git clone https://github.com/openeventdata/stanford_pipeline.git
curl http://nlp.stanford.edu/software/stanford-corenlp-full-2014-06-16.zip > stanford-corenlp.zip
unzip stanford-corenlp
rm stanford-corenlp.zip
mv stanford-corenlp-full-2014-06-16 stanford-corenlp
curl http://nlp.stanford.edu/software/stanford-srparser-2014-07-01-models.jar > stanford-corenlp/stanford-srparser-2014-07-01-models.jar
DIR=`pwd`
echo "[StanfordNLP]
stanford_dir = $DIR/stanford-corenlp" > stanford_pipeline/default_config.ini
git clone https://github.com/openeventdata/phoenix_pipeline.git

echo "Installing Libraries..."
sudo pip install -r scraper/requirements.txt
sudo pip install git+https://github.com/openeventdata/petrarch.git
sudo pip install -r phoenix_pipeline/requirements.txt
sudo pip install -r stanford_pipeline/requirements.txt
sudo python -m nltk.downloader -d /usr/share/nltk_data punkt

echo "Configuring System"
set JRE_HOME=/usr/lib/jvm/java-7-openjdk-amd64
sudo chmod 777 /usr/lib/jvm/java-7-openjdk-amd64
sudo chmod 777 -R /usr/lib/jvm/java-7-openjdk-amd64/*
sudo update-alternatives --set java 2
sudo curl https://raw.githubusercontent.com/ahalterman/CLIFF-up/master/tomcat-users.xml > /etc/tomcat7/tomcat-users.xml
git clone https://github.com/Berico-Technologies/CLAVIN.git
cd CLAVIN
mvn compile
curl http://download.geonames.org/export/dump/allCountries.zip > allCountries.zip
unzip allCountries.zip
rm allCountries.zip
MAVEN_OPTS="-Xmx4g" mvn exec:java -Dexec.mainClass="com.bericotech.clavin.index.IndexDirectoryBuilder"
sudo mkdir /etc/cliff2
sudo ln -s `pwd`/IndexDirectory /etc/cliff2/
cd ..
curl https://raw.githubusercontent.com/ahalterman/CLIFF-up/master/settings.xml > .m2/settings.xml
curl https://codeload.github.com/c4fcm/CLIFF/tar.gz/v2.0.0 | tar -xz
curl https://raw.githubusercontent.com/ahalterman/CLIFF-up/master/pom.xml > CLIFF-2.0.0/pom.xml
cd CLIFF-2.0.0
mvn tomcat7:deploy -DskipTests
sudo mv target/CLIFF-2.0.0.war /var/lib/tomcat7/webapps/
cd ..
sudo service tomcat7 restart

echo "Automating Jobs..."
DIR=`pwd`
PYTHON=`which python`
CRONJOBS="@hourly cd $DIR/scraper && $PYTHON $DIR/scraper/scraper.py >> $DIR/scraper_stdout.log 2>&1
10 */3 * * * cd $DIR/stanford_pipeline && $PYTHON $DIR/stanford_pipeline/process.py >> $DIR/stanford_stdout.log 2>&1
0 1 * * * cd $DIR/phoenix_pipeline && $PYTHON $DIR/phoenix_pipeline/pipeline.py >> $DIR/pipeline_stdout.log 2>&1
"
echo "$CRONJOBS" > crontab.txt
crontab crontab.txt

echo "All Done!"

