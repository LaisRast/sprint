# sprint
A shell script to print over `ssh` using `lp`.

## Getting Started
Download `sprint.sh` to your computer and make it excutable:
```
curl XXX --output sprint.sh
chmod +x sprint.sh
```
Edit the script and set the variables PRINTER, REMOTE and USER.
To print a file (e.g. `blank.pdf`) simply run:
```
./sprint.sh blank.pdf
```
For more options see Usage below.

## Usage
```
Usage: sprint.sh [-d PRINTER] [-h] [-l] [-o OPTION=VALUE] [-r REMOTE] [-u USER] [-q] FILE

Options:
    -d PRINTER
        Set the destination printer.
    -h
        Show this help message.
    -l
        List all printers in remote.
    -o OPTION=VALUE
        Set job option. Available options are:
        -o copies=NUM
            Set the number of copies to print.
        -o media=SIZE
            Set the page size, e.g. "a4', "letter', or "legel".
        -o page-ranges=[NUM-NUM | NUM,NUM]
            Specifies which pages to print, e.g., "1,3-5,16".
        -o sides=[one-sided | two-sided-long-edge | two-sided-short-edg]
            Prints on one side, both sides (portrait), or both sides (landscape) of the paper.
    -r REMOTE
        Set the remote host name.
    -u USER
        Set the user name.
    -q
        Show printer queue status.
```





