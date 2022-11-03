# Now Playing Database Extractor

This shell script can be used to download the databases used by Google Pixel Now Playing feature to your local disk and extract all the YouTube Music IDs stored in the database using several simple grep commands. Beside GNU standard utilities and curl no other programs are required (e.g. no LevelDB-parser).

## Usage

```bash
./main.sh  [-k] [COUNTRY_CODE] [MONTH_TO_FETCH]
```

**Attention**: Even without the `-k`-option, a full run of the program requires up to 4 GB of temporary disk space in the working directory.

### Arguments

- `-k` Keep old leveldb-files
- `COUNTRY_CODE` Only download databases for this country
- `MONTH_TO_FETCH` Manually set the month in YYYYMM format to download. Default is the latest database.

The program needs exactly these places of command line arguments.

### Examples

Download US databases and don't keep old files (-k): 

```bash
$ ./main.sh '' US
```

Download all countries databases for 10/2022 and keep old database files:

```bash
$ ./main.sh -k '' 202210
```

### Output

The program will create a directory structure in its working dir. The files in curly braces will be automatically deleted after execution if `-k` is not supplied. Beware that keeping the files consumes a relevant amount of disk space.

- YYYYMMDD-HHMMSS/ (Date of the database)
  - CC/ (Country code)
    - {CCxxxxxxxxxxxxxx.leveldb} (Downloaded database files)
    - **song-ids.list** (The extracted YouTube Music IDs, one-per-line: can be used like this: `https://music.youtube.com/watch?v=YOUR_ID_HERE`)
  - {files.list}
  - {manifest.json}
- {dates.list}
- {list-YYYYMM.xml}
