#!/bin/csh 

set URL='192.168.1.54:80'
set ROOT="/usr/local/bin/artifactory"

if ($#argv != 3) then
    echo "Usage $0 <file> <repo number> <version number>"
else
    set DIR=`dirname $1`
	set BASE=`basename $1`
	
	rm -f /tmp/$BASE.zip
	cd $DIR
	
    if (-d $BASE) then
	   echo "$1 is a directory, zipping it up into /tmp/$BASE.zip"
	   zip -r "/tmp/$1.zip" $BASE
	   set FILE="/tmp/$BASE.zip"
	else
	   set IS_ZIPPED=`file $1 | grep Zip | wc -l`
	   if ("$IS_ZIPPED" == "0") then
	      echo "$1 is not a zip file, zipping it up as /tmp/$BASE.zip"
	      zip "/tmp/$BASE.zip" $BASE
	      set FILE="/tmp/$BASE.zip"
	   else
	      echo "$BASE is already a zip file, moving it to /tmp/$BASE"
              set FILE="/tmp/$BASE"
	      cp "$BASE" "/tmp/$BASE"
	   endif
	endif

    set REPO_NUM=$2
    echo "    "
    echo -n "DESTINATION repo number: $REPO_NUM"
    
    set NUMVALID=`cut -f1 -d' ' "$ROOT/REPO_LIST" | grep "$REPO_NUM)" | wc -l`
    
    if "$NUMVALID" == "0" then
		echo "Invalid repo number."
    else
		set REPO_NAME=`grep "^$REPO_NUM)" "$ROOT/REPO_LIST" | cut -f2 -d' '`
		set TARGET_PREFIX=`grep "^$REPO_NUM)" "$ROOT/REPO_LIST" | cut -f4 -d' '`	

		echo "   "
		echo "The $REPO_NAME repo already contains binary releases with the following Version Numbers: "
		echo "items.find(" > /tmp/query_$REPO_NUM.aql
		echo "   {" >> /tmp/query_$REPO_NUM.aql
		echo '      "repo":"'"$REPO_NAME"'"' >> /tmp/query_$REPO_NUM.aql
		echo "   }" >> /tmp/query_$REPO_NUM.aql
		echo ")" >> /tmp/query_$REPO_NUM.aql
				
		curl -X POST -u'user:E1af&c\!\!' "http://$URL/artifactory/api/search/aql" -T/tmp/query_$REPO_NUM.aql >& /tmp/list_$REPO_NUM.txt
		cat /tmp/list_$REPO_NUM.txt | grep '"name"' | sed -e 's/.*: "//' | sed -e 's/".*//' | awk '{print "      " $s}' > /tmp/shortlist_$REPO_NUM.txt
		cat /tmp/shortlist_$REPO_NUM.txt

		set VERSION_NUM=$3
		echo "   "
		echo -n "The Version Number of the binary release you are going to push up now: $VERSION_NUM"

		set TARGET="$TARGET_PREFIX-""$VERSION_NUM"

		echo "   "
		echo "$FILE is about to be *PUSHED*"	
		echo "TO artifactory repo: $REPO_NAME"
		echo "Where it will become known as: $TARGET.zip"

		echo "   "
		echo "Push request starting"

		curl -u'user:E1af&c\!\!' -T $FILE "http://$URL/artifactory/$REPO_NAME/$TARGET.zip"

		echo "   "
		echo "    "
		echo "*PUSH* request COMPLETED"	    
    endif
	
	rm -f /tmp/$1.zip
endif