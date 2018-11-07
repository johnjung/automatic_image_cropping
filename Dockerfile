FROM jjanzic/docker-python3-opencv

COPY requirements.txt requirements.txt
COPY crop_out_ruler.py crop_out_ruler.py
RUN pip3 install -r requirements.txt
RUN python3 crop_out_ruler.py
