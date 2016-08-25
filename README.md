# rdiff

Raccoon Diff - Find file differences between two folders with ease.

```rdiff``` is useful if you want to find differences in two folders. It crawls in two folders, finds the difference and tells you which file to copy over in order to **sync** the two folders.

## Usage

```
> rdiff ./source ./destination

Please copy these files from /Users/Matthias/Desktop/source to /Users/Matthias/Desktop/destination:
myPic.jpg
yourPic.jpg
herMovie.mov
```

## Caching MD5 results
```rdiff``` uses MD5 to compare files. It may take a while for the first crawl. After the each crawl, ```rdiff``` will save the MD5 list of the folder in the file ```.md5.cache```, therefore speeding up in succeeding runs.
