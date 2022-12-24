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
# make-scrolls
# Generates a video from the Script file and images generated by make-title-images, with FFmpeg.
#
################################################################################

set -eu
. "$(pwd)/CONFIG.shlib"

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

# obtain timestamp and filename
awk '{print$1,'"$ImageMagick_command_get_filename_awkcode"'}' |

# generate ffmpeg command
awk -v scrollDuration="$scrollDuration" -v lavfiOption="$LAVFI_OPTION" -v TARGET_VIDEO="$TARGET_VIDEO" -v Q=\' '
BEGIN{
	ORS=""
	print"ffmpeg -y -f lavfi -i",lavfiOption,""

	to_lavfi="\""

	OG_label="0:v"
}
{
	begin_at=$1
	filename=$2

	print"-i",filename,""

	if(NR>=2)
		to_lavfi=to_lavfi ";"

	new_label="_" NR
	plz_insert=sprintf("[%s][%d:v]overlay=x=(W-w)/2:y=(t-%s)*(-h-H)/%s+H:enable=%cbetween(t,%s,%s)%c[%s]",\
	                    OG_label,NR, begin_at,scrollDuration, Q,begin_at,begin_at+scrollDuration,Q, new_label)
	OG_label=new_label
	to_lavfi=to_lavfi plz_insert
}
END{
	to_lavfi=to_lavfi "\""
	map="-map [" OG_label "]"
	print "-lavfi",to_lavfi,map,TARGET_VIDEO
	print"\n"
}
' |

sh