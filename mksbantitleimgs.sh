#!/bin/sh

################################################################################
#
# Copyright 2022 ro_qu_na
# Copyright 2022 Tpaefawzen
#
# This file is part of mksban.
#
# mksban is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# mksban is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with mksban.  If not, see <https://www.gnu.org/licenses/>.
#
################################################################################
#
# make-title-images
# Generates titles from Script file, with ImageMagick.
#
################################################################################

set -eu
. "$(pwd)"/CONFIG.shlib

# NOTE this file as UTF-8
# NOTE needs to run as UTF-8 locale
# NEEDS GAWK and UTF-8 locale.... I am lazy to make it really POSIXism....

# for escaping
DUMMY="$(printf '\021')"

test -r "$(pwd)/Script" || {
	echo 'No "$(pwd)/Script" file readable' 1>&2
	exit 1
}
cat "$(pwd)/Script" |

# remove comments and empty lines
grep -v '^#' |
grep . |

# categorize each letter and separate
# NOTE. kana: U+3041: ぁ to U+30FF: ヿ
# NOTE. non-kana symbols: U+3000: 　 to U+303F: 〿
awk '
{
	time=$1
	text=$2
	L=length(text)
	s=""
	label="kana"
	prev=""
	for(i=1;i<=L;i++){
		c=substr(text,i,1)
		isalnum=c<="ჿ" # U+10FF: U+1100 is Hangul Kiuk
		iskana="ぁ"<=c&&c<="ヿ"||isalnum
		iskigou="　"<=c&&c<="〿"
		iskanji=!iskana&&!iskigou

		if(iskana)
			label="kana"
		if(iskanji)
			label="kanji"

		if(prev!=label)
			if(s=="")
				s=label " " c
			else 
				s=s " " label " " c
		else
			s=s c

		prev=label
	}
	print time,s
}' |

# make args for ImageMagick
awk -v ImageMagick_command_header="$ImageMagick_command_header" '
BEGIN{
	'"$ImageMagick_pointsize_definition_awkcode"'
}
{
	time=$1
	cmd=ImageMagick_command_header

	arg=""
	for(i=2;i<=NF;i+=2){
		label=$i
		text=$(i+1)

		# special characters for Script file syntax
		gsub("\\\\\\\\","\021",text)
		gsub("_"," ",text)
		gsub("\\\\ ","_",text)
		gsub("\\\\t","\t",text)
		gsub("\021","\\",text)

		# HTML_ESCAPE.
		gsub("&","\\&amp;",text)

# 		gsub("\t","\\&#9;",text)
# 		gsub(" ","\\&#32;",text)
		gsub("\"","\\&#34;",text)
		gsub("'\''","\\&#39;",text)
		gsub("<","\\&lt;",text)
		gsub(">","\\&gt;",text)

		arg=arg '"$ImageMagick_command_interval_awkcode"'
	}

	# ImageMagick escape
	gsub("%","%%",arg)

	# arg escape
	gsub("[&\"$\\\\]","\\\\&",arg)

	arg="\"" arg "\""

	cmd=cmd arg


	filename='"$ImageMagick_command_get_filename_awkcode"'
	# cmd=cmd " " '"$ImageMagick_command_footer_awkcode"'
	cmd=cmd '"$ImageMagick_command_footer_awkcode"'

	#print time,filename,cmd
	print cmd
}
' |

sh
