FROM debian:stable-slim

WORKDIR /root/

# Install basic system components
RUN apt-get update \
	&& apt-get install wget px nano -y \ 
	&& rm -rf /var/lib/apt/lists/*

# Install Rcdev WebADM and OpenOTP
RUN wget https://www.rcdevs.com/repos/debian/rcdevs-release_1.0.0-0_all.deb \ 
	&& apt-get install ./rcdevs-release_1.0.0-0_all.deb \
	&& rm ./rcdevs-release_1.0.0-0_all.deb \
	&& apt-get update \
	&& apt-get install waproxy -y \
	&& rm -rf /var/lib/apt/lists/* 

# Create backup copy of original configureation files that get wipped out by persistent volume mounts
RUN cp -r --preserve=all /opt/waproxy/conf /opt/waproxy/.conf 

# Create symlinks for the .setup file from the temp folder to the config folder that should be persisted 
RUN ln -s /opt/waproxy/conf/.setup /opt/waproxy/temp/.setup

ADD ./start.sh /
CMD /start.sh