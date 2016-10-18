#
# Timelapser 10172016
# v1.4
#
# This container will create time lapse or slides
# show videos. It should be passed one mount point
# containing the images and for writing the output.
#
# Additional options are required
#
# Pass -h for options
# sudo docker run -v </mountpoint/>:/</mountpoint> <container name> -h
#
FROM ubuntu:latest
MAINTAINER Jason Charcalla

RUN apt-get update && apt-get install -y bc \
ffmpeg \
imagemagick \
&& rm -rf /var/lib/apt/lists/*


# Future work
#git \
#python \
#python-pip \
#python-tk \
#RUN pip install PyInstaller
#RUN cd /tmp && git clone https://github.com/google/spatial-media.git && pyinstaller /tmp/spatial-media/spatialmedia/spatial_media_metadata_injector.spec
#RUN ln -s /tmp/dist/Spatial\ Media\ Metadata\ Injector/libpython2.7.so.1.0 /tmp/build/spatial_media_metadata_injector/

COPY auto_tlapser.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/auto_tlapser.sh"]
CMD ["-h"]
