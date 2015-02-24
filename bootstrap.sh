#!/usr/bin/bash

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get -qq update 
 
echo "Installing Base Dependencies..."
sudo apt-get -qq install zip unzip zlib1g-dev git g++ default-jre libxml2-dev libxslt1-dev python-dev python-pip mongodb-10gen <<-EOF
Y
EOF

echo "Downloading Phoenix Pipeline..."
echo " - Phoenix Pipeline..."
git clone -q https://github.com/openeventdata/phoenix_pipeline.git
echo " - Scraper..."
git clone -q https://github.com/openeventdata/scraper.git
echo " - Stanford Pipeline..."
git clone -q https://github.com/openeventdata/stanford_pipeline.git
echo " - CoreNLP..."
wget -nv http://nlp.stanford.edu/software/stanford-corenlp-full-2014-06-16.zip
unzip -qq stanford-corenlp-full-2014-06-16.zip
rm stanford-corenlp-full-2014-06-16.zip
mv stanford-corenlp-full-2014-06-16 stanford-corenlp
cd stanford-corenlp
wget -nv http://nlp.stanford.edu/software/stanford-srparser-2014-07-01-models.jar
cd ..
 
echo "Installing Python dependencies..."
echo " - Scraper"
sudo pip -q install -r scraper/requirements.txt
echo " - PETRARCH..."
sudo pip -q install git+https://github.com/openeventdata/petrarch.git
echo " - Phoenix Pipeline..."
sudo pip -q install -r phoenix_pipeline/requirements.txt
echo " - Stanford Pipeline..."
sudo pip -q install -r stanford_pipeline/requirements.txt
 
echo "Downloading NLTK data..."
mkdir -p nltk_data/tokenizers
cd nltk_data/tokenizers
wget -nv http://www.nltk.org/nltk_data/packages/tokenizers/punkt.zip
unzip -qq punkt.zip
cd ../..
sudo mv nltk_data /usr/lib/nltk_data
 
echo "Automating Jobs..."
DIR=`pwd`
CRONJOBS="@hourly cd $DIR/scraper && /usr/bin/python $DIR/scraper/scraper.py >> $DIR/scraper_stdout.log 2>&1
0 1 * * * cd $DIR/phoenix_pipeline && /usr/bin/python $DIR/phoenix_pipeline/pipeline.py >> $DIR/pipeline_stdout.log 2>&1
10 */3 * * * cd $DIR/stanford_pipeline && /usr/bin/python $DIR/stanford_pipeline/process.py >> $DIR/stanford_stdout.log 2>&1
"
 
echo "$CRONJOBS" > crontab.txt
sudo crontab crontab.txt

