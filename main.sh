#!/bin/bash

# Usage: ./main.sh [-k] [COUNTRY_CODE] [MONTH_TO_FETCH]
# Without country code: all countries
# Countrycode must be $2, if no -k give other string as $1
# Month to fetch: Specify YYYYMM for month of database

S3_BASE_URL="https://storage.googleapis.com/music-iq-db"

# Find manifests
echo "Searching manifests"
THIS_MONTH=$(date +%Y%m)
LAST_MONTH=$(date --date='-1 month' +%Y%m)

list_dl () {
  curl -o list-$1.xml --fail --silent "$S3_BASE_URL/?prefix=updatable_ytm_db/$1&max-keys=5000"
  if [ $? != 0 ]; then echo Cannot download dir listing for $1; exit 1; fi
}

if [ "$3" == "" ]; then
  list_dl $THIS_MONTH
  list_dl $LAST_MONTH
else
  list_dl $3
fi

extract_dates () {
  cat list-$1.xml | grep -oe 'updatable_ytm_db\/[0-9]\+-[0-9]\+\/manifest.json' | grep -oe '[0-9]\+-[0-9]\+'
}

if [ "$3" == "" ]; then
  extract_dates $THIS_MONTH > dates.list
  extract_dates $LAST_MONTH >> dates.list
else
  extract_dates $3 > dates.list
fi

DB_DATE=$(cat dates.list | sort | tail -n 1)

# Output directory
mkdir -p $DB_DATE
cd $DB_DATE

# Download manifest
echo "Downloading manifest $DB_DATE"
curl -o manifest.json --fail --silent "$S3_BASE_URL/updatable_ytm_db/$DB_DATE/manifest.json"
if [ $? != 0 ]; then echo Cannot download manifest $DB_DATE; exit 2; fi

# Extract country databases
echo "Extracting database list"
cat manifest.json | grep -oe 'updatable_ytm_db\/'$DB_DATE'\/[a-z0-9A-Z\-_]\+' | grep -oe '\/[a-z0-9A-Z\-_]\+' | grep -oe '[a-z0-9A-Z\-_]\+' > files.list

# Download databases
echo "Downloading databases"
cat files.list | while read f; do
  c=${f:0:2}
  if [ "$(echo "$c" | grep -oe '[A-Z]\{2\}')" != "$c" ]; then continue; fi
  if [ "$2" != "" ]; then if [ "$c" != "$2" ]; then echo Skipping "$c"; continue; fi; fi
  mkdir -p $c
  if [ -f $c/$f.leveldb ]; then echo $c/$f.leveldb already exists; continue; fi
  echo -ne "$c/$f       \r"
  curl -o $c/$f.leveldb --fail --silent "$S3_BASE_URL/updatable_ytm_db/$DB_DATE/$f"
done

# Extract YT Music Ids of titles per country
echo "Reading databases"
for c_ in */; do
  c="$(basename "$c_")"
  cat $c/$c*.leveldb | grep -aoe 'watch?v=[a-z0-9A-Z\-_]\{11\}&' | grep -oe '[a-z0-9A-Z\-_]\{11\}' > $c/song-ids.list
  count=$(cat $c/song-ids.list | sort | uniq | wc -l)
  echo "  [$c] $count song(s)"
done

# Delete databases
if [ "$1" != "-k" ]; then
  echo "Deleting old files"
  rm -f */*.leveldb list-*.xml dates.list manifest.json files.list
fi

