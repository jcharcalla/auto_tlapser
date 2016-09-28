auto_tlapser
Docker container and script for creating videos or slideshows from a directory full of images.
Timelapse example: https://www.youtube.com/watch?v=bthl-kkmadU
Slideshow example:

Timelapse and slideshow video creator

Jason Charcalla 06292016
Usage:

All of the folowing options are required 

-R Image resolution. 2k,4k,8k (translates to 16x9 2560x1440,3840x2160,5120x4320)
-F Frame rate 15,24,25,30,48,50,60
-D Still image durration in seconds for slideshoe. Use 0 for timelapse mode
-C Color of fade transition between still images in slideshow
-T Transition legnth in seconds. Use 0 for timelapse
-I Input path containing image files (This will create a tmp dir in here)
-O Output path and filename for the resulting video
-E Image file type extension, This is case sensative. (JPG, jpg, png, etc)


Docker usage:
This container requires a rw mount point which contains images

Produce a slide show
sudo docker run -v /mnt/:/mnt timelapse.1 -R 2k -F 15 -D 10 -C black -T 3 -I /mnt/test01/ -O /mnt/test.mp4 -E JPG
Produce a timelapse
sudo docker run -v /mnt/:/mnt timelapse.1 -R 2k -F 15 -D 0 -C black -T 0 -I /mnt/test01/ -O /mnt/test.mp4 -E J
