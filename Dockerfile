FROM jjanzic/docker-python3-opencv

RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get -y install cifs-utils
COPY requirements.txt requirements.txt
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
COPY start start
RUN chmod u+x start
