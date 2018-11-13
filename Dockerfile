FROM jjanzic/docker-python3-opencv

COPY requirements.txt requirements.txt
COPY start start
RUN chmod u+x start
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN apt-get update
RUN apt-get install cifs-utils
