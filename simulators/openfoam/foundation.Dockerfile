# Start from the official Ubuntu Bionic (18.04 LTS) image
FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

# Install any extra things we might need
RUN apt-get update \
	&& apt-get install -y \
	vim \
	ssh \
	git \
	wget \
	gmsh \
	software-properties-common ;\
	rm -rf /var/lib/apt/lists/*

ARG openfoam_num_version=8
ARG openfoam_version="openfoam${openfoam_num_version}"

# Install OpenFOAM from Foundation source (without ParaView)
# plus an extra environment variable to make OpenMPI play nice
RUN sh -c "wget -O - http://dl.openfoam.org/gpg.key | apt-key add -" ;\
	add-apt-repository http://dl.openfoam.org/ubuntu ;\
	apt-get update ;\
	apt-get install -y --no-install-recommends ${openfoam_version} ;\
	rm -rf /var/lib/apt/lists/*

ENV OPENFOAM_SOURCE_FILE=/opt/${openfoam_version}/etc/bashrc
COPY ./launch.sh /launch.sh
RUN chmod +x /launch.sh
