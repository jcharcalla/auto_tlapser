#!/bin/bash

#
# Auto timelapse script
#

print_usage() {
	cat <<EOF
#
# Timelapse and slideshow video creator
#
# Jason Charcalla 06292016
# Usage:
#
# All of the folowing options are required 
#
# -R Image resolution. 2k,4k,8k (translates to 16x9 2560x1440,3840x2160,5120x4320)
# -F Frame rate 15,24,25,30,48,50,60
# -D Still image durration in seconds for slideshoe. Use 0 for timelapse mode
# -C Color of fade transition between still images in slideshow
# -T Transition legnth in seconds. Use 0 for timelapse
# -I Input path containing image files (This will create a tmp dir in here)
# -O Output path and filename for the resulting video
# -E Image file type extension, This is case sensative. (JPG, jpg, png, etc)
#
#
# Docker usage:
# This container requires a rw mount point which contains images
#
# Produce a slide show
# sudo docker run -v /mnt/:/mnt timelapse.1 -R 2k -F 15 -D 10 -C black -T 3 -I /mnt/test01/ -O /mnt/test.mp4 -E JPG
# Produce a timelapse
# sudo docker run -v /mnt/:/mnt timelapse.1 -R 2k -F 15 -D 0 -C black -T 0 -I /mnt/test01/ -O /mnt/test.mp4 -E JPG
#
#
EOF
exit 1
}

if [ "$#" -le 7 ]; then
	    print_usage
fi

while getopts h?R:F:D:C:T:I:O:E: arg ; do
	case $arg in
		R) IMG_RESOLUTION=$OPTARG;;
		F) FRAME_RATE=$OPTARG;;
		D) IMG_DUR=$OPTARG;;
		C) FADE_COLOR=$OPTARG;;
		T) TRANS_DUR=$OPTARG;;
#			TRANS_COUNT=0;;
		I) IN_PATH=$OPTARG;;
		O) OUTPUT=$OPTARG;;
		E) IMG_TYPE=$OPTARG;;
		h|\?) print_usage; exit ;;
	esac
done

# set some variables
# the work path must be located on the same filesystem as the images for soft links
WORK_PATH="${IN_PATH}tmp/"
echo ${WORK_PATH}

# Make the work path
mkdir "${WORK_PATH}"

TMP_NAME=000000

# Count jpg files in dir

FILE_COUNT=$(find "${IN_PATH}" -name "*.${IMG_TYPE}" | wc -l)
echo "Total file count is ${FILE_COUNT}"

# calculate total number of images needed when were done (files * 2 * framerate)
# if we are doing a transition calculate how many frames it will add as well
if [ "$TRANS_DUR" -ge 1 ]
then
	TRANS_FRAMES=$(echo "${TRANS_DUR}*${FRAME_RATE}"| bc)
	IMG_FRAMES=$(echo "${IMG_DUR}*${FRAME_RATE}"| bc)
	#TOT_IMG=$(echo "${FILE_COUNT}*2*${FRAME_RATE}"| bc)
	FADE_RATE=$(echo "scale=3;100/${TRANS_FRAMES}"| bc)
	echo "transition frame count = ${TRANS_FRAMES}"
	echo "Single image frame count = ${IMG_FRAMES}"
	#echo "Total images = ${TOT_IMG}"
	echo "Fade rate = ${FADE_RATE}"
else
	TRANS_FRAMES=0
	IMG_FRAMES=$(echo "${IMG_DUR}*${FRAME_RATE}"| bc)
	#TOT_IMG=$(echo "${FILE_COUNT}*${FRAME_RATE}"| bc)
	echo "Single image frame count = ${IMG_FRAMES}"
	#echo "Total images = ${TOT_IMG}"
fi

# Logic should be added here to check the current resolution, for now everything
# will be re-sized. this sould ensure things are squised to 16x9 aspect ratio

case $IMG_RESOLUTION in
	2k) H_RES=2560
            V_RES=1440
	    BIT_RATE="16M";;
	    #BIT_RATE="80M";;
	4k) H_RES=3840
            V_RES=2160
	    BIT_RATE="40M";;
	    #BIT_RATE="40M";;
	8k) H_RES=5120
	    V_RES=4320
	    BIT_RATE="80M";;
	    #BIT_RATE="16M";;
esac
# resize in place
echo "Resolution set at ${H_RES}x${V_RES}"
mogrify  -filter Lanczos -antialias -quality 95 -resize ${H_RES}x${V_RES}! ${IN_PATH}*.${IMG_TYPE}

# Function for creating transitions and links with new sequential names
img_sequence()
{
	# prior to each image transition from black
	# future feature. blend images with imagemagick
	if [ "${TRANS_DUR}" -ne 0 ]
	then
		echo "Creating fade in transition images"
		#TRANS_I=$TRANS_FRAMES
		TRANS_I=0
		FADE_CURRENT=100
	 	 while [ $TRANS_I -le $TRANS_FRAMES ]
		 do
			 # step through percentages
			 # calculate current blend threshold
			 FADE_CURRENT=$(printf "%.0f" $(echo "scale=3;${FADE_CURRENT}-${FADE_RATE}"| bc))
			 $(convert ${FILENAME} -fill ${FADE_COLOR} -colorize ${FADE_CURRENT}% ${WORK_PATH}${TMP_NAME}.${IMG_TYPE})
			 #echo "convert ${FILENAME} -fill ${FADE_COLOR} -colorize ${FADE_CURRENT}% ${WORK_PATH}${TMP_NAME}.${IMG_TYPE}"
			 # advance the new temp file name every time.
			 TMP_NAME=$(echo "${TMP_NAME}+1"| bc | awk '{printf "%06d", $0}')
			 TRANS_I=$(( TRANS_I + 1 ))
		 done
	fi
	# create multiple simlinks
	# These sim links will be virtual frames for ffmpeg
	if [ "${IMG_DUR}" -ge 1 ]
	then
		echo "Creating soft links"
		IMG_I=0
		while [ "${IMG_I}" -le "${IMG_FRAMES}" ]
		do
			# Create a sim link
			ln -s ${FILENAME} ${WORK_PATH}${TMP_NAME}.${IMG_TYPE}	
			# increment up IMG_I
			IMG_I=$(( IMG_I + 1 ))
			# advance the new temp file name every time.
			TMP_NAME=$(echo "${TMP_NAME}+1"| bc | awk '{printf "%06d", $0}')
		done
	else
		echo "Time lapse mode only"
		# create sim link
		ln -s ${FILENAME} ${WORK_PATH}${TMP_NAME}.${IMG_TYPE}	
		# advance the new temp file name every time.
		TMP_NAME=$(echo "${TMP_NAME}+1"| bc | awk '{printf "%06d", $0}')
	fi

	# create transition to black
        if [ "${TRANS_DUR}" -ge 1 ]
        then
		echo "Creating fade out transition images"
                #TRANS_I=$TRANS_FRAMES
                TRANS_I=0
                FADE_CURRENT=0
                while [ "${TRANS_I}" -le "${TRANS_FRAMES}" ]
                do
                        # step through percentages
                        # calculate current blend threshold
                        FADE_CURRENT=$(printf "%.0f" $(echo "scale=3;${FADE_CURRENT}+${FADE_RATE}"| bc))
			$(convert ${FILENAME} -fill ${FADE_COLOR} -colorize ${FADE_CURRENT}% ${WORK_PATH}${TMP_NAME}.${IMG_TYPE})
			#echo "convert ${FILENAME} -fill ${FADE_COLOR} -colorize ${FADE_CURRENT}% ${WORK_PATH}${TMP_NAME}.${IMG_TYPE}"
                        # advance the new temp file name every time.
                        TMP_NAME=$(echo "${TMP_NAME}+1"| bc | awk '{printf "%06d", $0}')
                        TRANS_I=$(( TRANS_I + 1 ))
               done    
            fi
	
# End img_sequence funftion
}
#done

# find all the image files in the path were looking at and call the img_sequence function
find "${IN_PATH}" -maxdepth 1 -type f -name "*.${IMG_TYPE}" -print | sort -n | while read FILENAME
do
	img_sequence
	#echo "Creating transitions, links, etc. Outputting image $TMP_NAME"
done


# create a video with ffmpeg from the images and image links
echo "LETS MAKE A MOVIE!"
ffmpeg -framerate ${FRAME_RATE} -i ${WORK_PATH}%06d.${IMG_TYPE} -preset medium -pix_fmt yuv420p -c:v libx264 -b:v ${BIT_RATE} -r ${FRAME_RATE} ${OUTPUT}
#echo "ffmpeg -framerate ${FRAME_RATE} -i ${WORK_PATH}%06d.${IMG_TYPE} -c:v libx264 -b:v ${BIT_RATE} -r ${FRAME_RATE} ${OUTPUT}"

# add audio track

# Clean up time
rm -rf "${WORK_PATH}"

exit
