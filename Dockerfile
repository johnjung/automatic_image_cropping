FROM jjanzic/docker-python3-opencv

RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get -y install cifs-utils
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --upgrade pip
RUN pip3 install -r /tmp/requirements.txt
COPY start /usr/local/bin/start
RUN chmod u+x /usr/local/bin/start
RUN mkdir /mnt/pres
