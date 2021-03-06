# auto_tlapser
Docker container and script for creating videos or slideshows from a directory full of images. This script relies on ffmpeg and image magic to create transitions and convert images to movies. 
- Timelapse example: https://www.youtube.com/watch?v=bthl-kkmadU
- Slideshow example: https://www.youtube.com/watch?v=CpLt5Oa3M7g

Jason Charcalla 06292016

## Usage:
The auto_tlapser.sh can be run by itself or within a Docker container.

### All of the folowing options are required 

- -R Image resolution.  2k,4k,5k,8k (translates to 16x9 2560x1440,3840x2160,5120x2880,7680x4320)
- -F Frame rate 15,24,25,30,48,50,60
- -D Still image durration in seconds for slideshoe. Use 0 for timelapse mode
- -C Color of fade transition between still images in slideshow
- -T Transition legnth in seconds. Use 0 for timelapse
- -I Input path containing image files (This will create a tmp dir in here)
- -O Output path and filename for the resulting video
- -E Image file type extension, This is case sensative. (JPG, jpg, png, etc)

### Optional options

- -A Audio track, the shorter lenght file will determine output video lenght.


### Docker usage:
This container requires a rw mount point which contains images. Your images will be overwritten!

#### Produce a slide show with an audio track
	sudo docker run -v /mnt/:/mnt timelapse.1 -R 2k -F 15 -D 10 -C black -T 3 -I /mnt/test01/ -O /mnt/test.mp4 -E JPG -A /mnt/test01/audiotrack.mp3
#### Produce a timelapse
	sudo docker run -v /mnt/:/mnt timelapse.1 -R 2k -F 15 -D 0 -C black -T 0 -I /mnt/test01/ -O /mnt/test.mp4 -E JPG
