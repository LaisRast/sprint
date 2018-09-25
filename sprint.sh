#!/bin/env bash
OPTIND=1

## User defaults
PRINTER="HP_Officejet_4620"
REMOTE="192.168.0.32"
USER="pi"

## Set colors
BLUE='\033[1;34m'
RED='\033[1;31m'
NC='\033[0m'

## Usage and help
### Usage
SCRIPT_NAME=$(basename $0)
USAGE="Usage: $SCRIPT_NAME [-d PRINTER] [-h] [-l] [-o OPTION=VALUE] [-r REMOTE] [-u USER] [-q] FILE"

### Help
function show_help()
{
    cat <<-EndHelp
		A shell script to print over ssh using lp.
		$USAGE

		Options:
		    -d PRINTER
		        Set the destination printer (Default: $PRINTER).
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
		        Set the remote host name (Default: $REMOTE).
		    -u USER
		        Set the user name (Default: $USER).
		    -q
		        Show printer queue status.
	EndHelp
}

## Functions
### List all printers function
function list_printers()
{
    echo -e "${BLUE}[$SCRIPT_NAME] Listing all printers in '$REMOTE'..${NC}"
    PRINTERS=$(ssh $USER@$REMOTE "lpstat -a" | awk '{print $1}')
    for P in $PRINTERS
    do
        echo $P
    done
}

### Show queue function
function show_queue()
{
    echo -e "${BLUE}[$SCRIPT_NAME] Listing queue of '$PRINTER'..${NC}"
    ssh $USER@$REMOTE "lpq -P $PRINTER" 
}

## Main script
### Get positional arguments
while getopts "d:hlo:r:u:q" OPTION; do
    case "$OPTION" in
        d)
            PRINTER="$OPTARG"
            ;;
        h)
            show_help
            exit 0
            ;;
        l)
            list_printers
            exit 0
            ;;
        o)
            IFS='=' read -ra OPTARRAY <<< "$OPTARG"
            case "${OPTARRAY[0]}" in
                copies|n)
                    COPIES=${OPTARRAY[1]}
                    ;;
                media|m)
                    MEDIA=${OPTARRAY[1]}
                    ;;
                page-ranges|P)
                    PAGE_RANGES=${OPTARRAY[1]}
                    ;;
                sides|s)
                    SIDES=${OPTARRAY[1]}
                    ;;
                *)
                    echo -e "${RED}[$SCRIPT_NAME] Unknown Option: $OPTARG!${NC}" >&2
                    exit 1
                    ;;
            esac
            ;;
        r)
            REMOTE="$OPTARG"
            ;;
        u)
            USER="$OPTARG"
            ;;          
        q)
            show_queue
            exit 0
            ;;
        *)
            echo "$USAGE"
    		echo -e "${RED}[$SCRIPT_NAME] Try '$SCRIPT_NAME -h' for more information!${NC}"
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))

### Set options which are not assigned
[ -z "$COPIES" ] && COPIES="1"
[ -z "$MEDIA" ] && MEDIA="a4"
[ -z "$PAGE_RANGES" ] && PAGE_RANGES="-"
[ -z "$SIDES" ] && SIDES="two-sided-long-edge"

### Check if no file was specified
if [ $# -eq 0 ]
then
    echo $USAGE
    echo -e "${RED}[$SCRIPT_NAME] Please provide a file to print!${NC}"
    exit 1
fi

### Send file over ssh and print it
FILE="$@"
FILE_NAME=$(basename "$@")
if [ -f "$FILE" ]
then
    echo -e "${BLUE}[$SCRIPT_NAME] Sending '$FILE_NAME' to '$REMOTE' to print it..${NC}"
    ### Start ssh-agent
    eval "$(ssh-agent -s)" &>/dev/null
    ssh-add &>/dev/null
    ssh $USER@$REMOTE "lp -s -t '$FILE_NAME' -d $PRINTER -n '$COPIES' -o media='$MEDIA' -o page-ranges='$PAGE_RANGES' -o sides='$SIDES'" < "$FILE"
    if [ ! $? ]
    then
        echo -e "${RED}[$SCRIPT_NAME] '$FILE_NAME' was not printed!${NC}"
        exit 1
    fi
else
    echo -e "${RED}[$SCRIPT_NAME] '$FILE_NAME' does not exist!${NC}"
    exit 1
fi

### Check until file is printed
echo -e "${BLUE}[$SCRIPT_NAME] Waiting '$FILE_NAME' to be printed.${NC}"
ssh $USER@$REMOTE /bin/bash << ENDlp
	while [[ -z \$(lpq -P $PRINTER $USER | grep 'no entries') ]]
	do
	    lpq -P $PRINTER $USER
	    echo 
	    sleep 10
	done
ENDlp

echo -e "${BLUE}[$SCRIPT_NAME] Finished printing.${NC}"

### Kill ssh-agent
kill $SSH_AGENT_PID
