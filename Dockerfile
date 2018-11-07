FROM jjanzic/docker-python3-opencv

COPY requirements.txt /tmp/requirements.txt
COPY crop_out_ruler.py /etc/init.d/crop_out_ruler.py
RUN pip3 install --upgrade pip
RUN pip3 install -r /tmp/requirements.txt
