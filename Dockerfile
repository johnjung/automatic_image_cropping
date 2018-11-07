FROM jjanzic/docker-python3-opencv

RUN pip3 install -r requirements.txt

COPY crop_out_ruler.py crop_out_ruler.py
