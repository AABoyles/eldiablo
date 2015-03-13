#!/bin/bash

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
 
echo "Installing Base Dependencies..."
sudo apt-get -y install zip unzip curl zlib1g-dev git g++ default-jre libxml2-dev libxslt1-dev python-dev python-pip mongodb-10gen

echo "Downloading Phoenix Pipeline..."
git clone https://github.com/openeventdata/phoenix_pipeline.git
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

echo "Installing Libraries..."
sudo pip install -r scraper/requirements.txt
sudo pip install git+https://github.com/openeventdata/petrarch.git
sudo pip install -r phoenix_pipeline/requirements.txt
sudo pip install -r stanford_pipeline/requirements.txt

echo "Downloading NLTK data..."
mkdir -p nltk_data/tokenizers
curl http://www.nltk.org/nltk_data/packages/tokenizers/punkt.zip > nltk_data/tokenizers/punkt.zip
unzip nltk_data/tokenizers/punkt.zip -d nltk_data/tokenizers
sudo mv nltk_data /usr/lib/nltk_data

echo "Automating Jobs..."
PYTHON=`which python`
CRONJOBS="@hourly cd $DIR/scraper && $PYTHON $DIR/scraper/scraper.py >> $DIR/scraper_stdout.log 2>&1
0 1 * * * cd $DIR/phoenix_pipeline && $PYTHON $DIR/phoenix_pipeline/pipeline.py >> $DIR/pipeline_stdout.log 2>&1
10 */3 * * * cd $DIR/stanford_pipeline && $PYTHON $DIR/stanford_pipeline/process.py >> $DIR/stanford_stdout.log 2>&1
"
echo "$CRONJOBS" > crontab.txt
sudo crontab crontab.txt

echo "All Done!"

