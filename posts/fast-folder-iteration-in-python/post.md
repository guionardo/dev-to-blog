# Fast folder iteration in python

Post created at 2022-01-19 07:53

I have a problem to deal here.

I need to iterate over a big tree of folders and files and run process over each file.

In python, we have some options to deal to folders and files.

* glob
* iglob
* os.walk
* os.scandir
* pathlib.Path

Running this benchmark, we can read some implementation details:

## [glob](https://docs.python.org/3/library/glob.html#glob.glob)

``` python
import glob

folder='some_folder/another_folder/**/*'
for file in glob.glob(folder, recursive=True):
    print(file)
```

```
some_folder/another_folder/f1/file1
some_folder/another_folder/f1/file1
some_folder/another_folder/f1/file2
```

### Pros

* Easy to use, less code to write
* Easy to apply filters using masks (fnmatch based)
* Returns data as a list

### Cons

* Time to scan is the worst (more than 11x the quickest method)
* Data will be available only after all files/folders been scanned

## [iglob](https://docs.python.org/3/library/glob.html#glob.iglob)

``` python
import glob

folder='some_folder/another_folder/**/*'
for file in glob.iglob(folder, recursive=True):
    print(file)
```

```
some_folder/another_folder/f1/file1
some_folder/another_folder/f1/file1
some_folder/another_folder/f1/file2
```

### Pros

* Easy to use, like glob
* Same filtering
* Returns data as iterator, so you can have your data without need to wait all iteration ending.

### Cons

* Time to scan is a little better than glob (10x the quickest method)
* Time to first file could be mutch better

## [os.walk](https://docs.python.org/3/library/os.html#os.walk)

```python
import os

folder='some_folder/another_folder/**/*'

for root, _, files in os.walk(folder):
    for file in files:
        print(os.path.join(root, file))
```

### Pros

* Good performance. Second quickest method (less than 2x slower than the quickest)
* Time for the first file almost imediattely (better result of all)
* Explicit code in loops gives more visibility and control if you need validations or another nasty processes
  
### Cons 

* More code needed, with nested loops. 
* If you need to nest os.walk in another os.walk loop, some strange things can ocurr. But probably your code needs some refactoring.

## [os.scandir](https://docs.python.org/3/library/os.html#os.walk)

```python
import os
from typing import Generator

folder='some_folder/another_folder/**/*'

def get_files(folder: str) -> Generator:
    with os.scandir(folder) as scan:
        for item in scan:
            if item.is_file():
                yield item.path
            else:
                for subitem in get_files(item.path):
                    yield subitem
```

### Pros

* Best performance of all
* Context based, assure resources are released after processing
* Less verbose than os.walk
* Easy to implement your custom business rules


### Cons

* A little more complex. No big deal.


## [pathlib.Path.rglob](https://docs.python.org/3/library/pathlib.html)

```python
import pathlib

folder='some_folder/another_folder'

for path in pathlib.Path(folder).rglob('*'):
    if path.is_file():
        yield str(path)
```

### Pros

* Easy to implement your custom business rules
* Returns a iterator
* You can have your files soon and don't need to wait for all scan (7x more time than os.scandir)

### Cons

* Average time to scan (almost 8 times greater than os.scandir)
* Memory consumption is 4 times more than the other methods
  
## Some data from tests

## System Information

| System | Release           | Version                                            | Machine | Processor |
| ------ | ----------------- | -------------------------------------------------- | ------- | --------- |
| Linux  | 5.11.0-46-generic | #51~20.04.1-Ubuntu SMP Fri Jan 7 06:51:40 UTC 2022 | x86_64  | x86_64    |

## CPU Info

| Physical cores | Total cores | Max frequency | Min frequency | Current frequency |
| -------------- | ----------- | ------------- | ------------- | ----------------- |
| 4              | 8           | 3400          | 400           | 1.892             |

## CPU Usage Per Core

| 0    | 1    | 2    | 3    | 4    | 5    | 6    | 7    | Total |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ----- |
| 15.6 | 16.5 | 10.4 | 14.1 | 15.2 | 14.4 | 15.2 | 12.4 | 14    |

## Memory Information

| Total   | Available | Used   | Percentage |
| ------- | --------- | ------ | ---------- |
| 15.51GB | 4.77GB    | 9.56GB | 69.2%      |

## SWAP

| Total   | Free   | Used    | Percentage |
| ------- | ------ | ------- | ---------- |
| 15.26GB | 3.28GB | 11.98GB | 78.5%      |

```
  Creating sample files
  + Creating folder ./test_files
  + Creating files LEVELS=6 FOLDER_COUNT=6 FILE_COUNT_BY_FOLDER=20
  + Created 933120 files in  0:02:08.928680

* Running iterators: GlobFolderIterator IGlobFolderIterator OSWalkFolderIterator ScanDirIterator PathLibFolderIterator
```

## MEMORY USAGE

| Iterator              | RSS       | VMS       | DATA      |
| --------------------- | --------- | --------- | --------- |
| IGlobFolderIterator   | 111280128 | 96468992  | 96468992  |
| OSWalkFolderIterator  | 111280128 | 96468992  | 96468992  |
| ScanDirIterator       | 111280128 | 96468992  | 96468992  |
| GlobFolderIterator    | 117309440 | 102498304 | 120254464 |
| PathLibFolderIterator | 469721088 | 455081984 | 455081984 |

## ELAPSED TIME

| Iterator              | Elapsed time   | X    |
| --------------------- | -------------- | ---- |
| ScanDirIterator       | 0:00:01.317526 | 1    |
| OSWalkFolderIterator  | 0:00:02.496639 | 1.9  |
| PathLibFolderIterator | 0:00:10.464794 | 7.9  |
| IGlobFolderIterator   | 0:00:14.358165 | 10.9 |
| GlobFolderIterator    | 0:00:15.308936 | 11.6 |

## TIME FOR FIRST FILE

| Iterator              | Elapsed time   | X       |
| --------------------- | -------------- | ------- |
| ScanDirIterator       | 0:00:00.000098 | 1       |
| OSWalkFolderIterator  | 0:00:00.000247 | 2.5     |
| PathLibFolderIterator | 0:00:00.000690 | 7       |
| IGlobFolderIterator   | 0:00:00.001135 | 11.6    |
| GlobFolderIterator    | 0:00:07.831005 | 79908.2 |

You can check the source code for this [here](https://github.com/guionardo/python-folder-iteration).


Image from this wikipedia [article](https://en.wikipedia.org/wiki/International_Committee_of_the_Red_Cross_archives).