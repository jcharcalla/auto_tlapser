#
# Timelapser 06292016
#
# This container will create time lapse or slides
# show videos. It should be passed one mount point
# containing the images and for writing the output.
#
# Additional options are required
#
# Pass -h for options
# sudo docker run -v </mountpoint/>:/</mountpoint> <container name> -h
#`
FROM ubuntu:latest
MAINTAINER Jason Charcalla

RUN apt-get update && apt-get install -y bc \
ffmpeg \
imagemagick \
&& rm -rf /var/lib/apt/lists/*

COPY auto_timelapse.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/auto_timelapse.sh"]
CMD ["-h"]
