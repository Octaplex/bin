#!/bin/bash

#########################################################
# A [pseudo] multithreaded FLAC to MP3 transcoder	#
#########################################################
# By Christopher A. Wadge, 09/04/2010			#
# Some code by Nick Sklavenitis, 09/18/2007		#
#							#
# http://files.tuxhelp.org/scripts/flac-distiller.sh	#
#							#
# Licensed under the GPL version 3. A copy of the GPL	#
# version 3 is included with this script.  If the file, #
# COPYING, is not included, you can find the GPL 	#
# version 3 at the following URL online:		#
#							#
# http://www.gnu.org/licenses/gpl-3.0.html		#
#########################################################

# This script's name:
PROGRAM_NAME="flac-distiller.sh"
# Date of last revision:
PROGRAM_DATE="12/30/11"

## VARIABLES ##
# The following are pre-determined variables that are not answered by the script.
#####

## Executable Paths ##

# MP3 encoder (e.g. lame/twolame/toolame) binary locale:
MP3ENCODER="/usr/bin/lame"
# FLAC decoder binary locale:
FLACDECODER="/usr/bin/flac"
# FLAC meta info reader locale:
METAFLAC="/usr/bin/metaflac"

## Encoder Variables ##

# Should we automatically copy meta info from FLAC files as MP3 tags?
COPYMETA="true"
# Nice priority level (19 to -20, 19 being the lowest):
PROCNICE="10"
# You can append additional values to the $MP3ENCODER encoding process if you wish:
XTRAOPTS="--vbr-new -h -V 0"
# Max number of encoder threads to use (leave blank for auto-detection):
THREADMAX=""

## !!! Attention Users: Editing below this line is not advised unless you really know what you're doing.

## FUNCTIONS ##
# Define each function that we will call in scripting later
#####

Error ()
{
	echo "[FATAL] Unfortunately we've encountered an unrecoverable error. Now quitting."
	exit 1
}

Print_Help ()
{
	echo ""
	echo "==== $PROGRAM_NAME ($PROGRAM_DATE) ===="
	echo ""
	echo "Description:   A multi-threaded FLAC to MP3 transcoder"
	echo ""
	echo "Usage:         $0 <path to '.flac' file(s) or directory>"
	echo "               You may also specify a wildcard, e.g. '*.flac'."
	echo "               Sans arguments, it will search the current directory."
	echo ""
	echo "Dependencies:  - An MP3 encoder, e.g. 'lame', 'twolame', or 'toolame'"
	echo "               - A LAME decoder (see: http://lame.sourceforge.net/)"
	echo "               - The Bourne Again SHell (aka 'BASH')"
	echo "               + Optional (but highly recommended): 'metaflac'"
	echo ""
	exit 1
}

Detect_Threads ()
{
if [ -z $THREADMAX ] ; then
	if [ `uname -a | grep -c Linux` = 1 ] ; then
		THREADMAX=`cat /proc/cpuinfo | grep -c processor`
        elif [ `uname -a | egrep -c '(BSD|Darwin)'` = 1 ] ; then
                THREADMAX=`sysctl -a | grep hw.ncpu | grep -v "=" | cut -d " " -f2`
	fi
elif  (( "$THREADMAX" >= "1" )) ; then
        THREADMAX="$THREADMAX"
else
	echo "[WARNING] Unable to detect maximum supported CPU threads; falling back to 1 thread to be safe."
	echo "          You can specify the thread count manually in the 'VARIABLES' section of this script."
	THREADMAX="1"
fi
}

Sanity_Check ()
{
if [ ! -e /bin/bash ] ; then
	echo "[ERROR] It doesn't appear that you have the Bourne Again SHell (aka 'BASH')!"
	echo "        The [over-hyped] 'DASH' shell is too primitive to interpret this script."
	echo "        Please use your package manager to install 'bash' and try again."
	NOTSANE=1
fi
if [ ! -e $MP3ENCODER ] ; then
	echo "[ERROR] The MP3 Encoder binary is not in the expected location: '$MP3ENCODER'"
	echo "        If no encoder is installed, 'twolame' is quite fast: http://www.twolame.org/"
	echo "        Otherwise, you can correct the path by editing the VARIABLES section of this script."
	NOTSANE=1
fi
if [ ! -e $FLACDECODER ] ; then
	echo "[ERROR] The FLAC decoder binary is not in the expected location: '$FLACDECODER'"
	echo "        If no FLAC decoder is installed, try installing 'flac' with your package manager."
	echo "        Otherwise, you can correct the path by editing the VARIABLES section of this script."
	NOTSANE=1
fi
if [ " $COPYMETA " = " true " ] ; then
	if [ ! -e $METAFLAC ] ; then
		echo "[WARNING] The 'metaflac' binary is not in the expected location: '$METAFLAC'"
		echo "          This is a non-critical error. However, metaflac is strongly recommended."
		COPYMETA="false"
	fi
fi
if [ ! -z $NOTSANE ] ; then
	echo "[ERROR] Missing dependencies prevent this script from proceeding!"
	Error
fi
}

MP3_Encode ()
{
for file ; do
[ -r "$file" ] || { echo '[ERROR] Unable to read file: \"$file\"' >&1 ; Error ; }
FILEOUT=$(echo "$file" | sed s'/[.][Ff][Ll][Aa][Cc]//')
if [ " $COPYMETA " = " true " ] ; then
	#This section pulls the Tag info from flac and stores it as a variable.
	TITLE="`$METAFLAC --show-tag=TITLE "$file" | awk -F = '{ printf($2) }'`"
	ALBUM="`$METAFLAC --show-tag=ALBUM "$file" | awk -F = '{ printf($2) }'`"
	ARTIST="`$METAFLAC --show-tag=ARTIST "$file" | awk -F = '{ printf($2) }'`"
	TRACKNUMBER="`$METAFLAC --show-tag=TRACKNUMBER "$file" | awk -F = '{ printf($2) }'`"
	GENRE="`$METAFLAC --show-tag=GENRE "$file" | awk -F = '{ printf($2) }'`"
	COMMENT="`$METAFLAC --show-tag=COMMENT "$file" | awk -F = '{ printf($2) }'`"
	DATE="`$METAFLAC --show-tag=DATE "$file" | awk -F = '{ printf($2) }'`"
	#This section handles the conversion of the Flac file to MP3
	$FLACDECODER -dcs "$file" | $MP3ENCODER --quiet $XTRAOPTS \
	--tt "$TITLE" \
	--tn "$TRACKNUMBER" \
	--tg "$GENRE" \
	--ty "$DATE" \
	--ta "$ARTIST" \
	--tl "$ALBUM" \
	--add-id3v2 \
	- "$FILEOUT".mp3 || { echo "[ERROR] Transcoding failed for '$file'" >&1 ; Error ; }
else
	$FLACDECODER -dcs "$file" | $MP3ENCODER --quiet $XTRAOPTS \
	- "$FILEOUT".mp3 || { echo "[ERROR] Transcoding failed for '$file'" >&1 ; Error ; }
fi ; done
}

## SCRIPTING ##
# Here's where we actually do all the work
#####

if [ " $1 " = " --help " ] ; then
	Print_Help
fi
Sanity_Check
Detect_Threads
export MP3ENCODER
export FLACDECODER
export XTRAOPTS
export COPYMETA
if [ " $COPYMETA " = " true " ] ; then
	export METAFLAC
fi
export -f Error
export -f MP3_Encode
find "${@}" -maxdepth 1 -name '*[.][Ff][Ll][Aa][Cc]' -print0 | xargs -0 -n 1 -P $THREADMAX nice -n $PROCNICE bash -c 'MP3_Encode "$@"' --
exit 0
