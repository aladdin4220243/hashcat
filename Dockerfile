FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y \
    hashcat \
    hcxtools \
    python3 \
    python3-pip \
    && apt-get clean

RUN pip3 install flask

RUN mkdir -p /app/wordlists
COPY app.py /app/
COPY wordlists/ /app/wordlists/

WORKDIR /app

EXPOSE 8000

CMD ["python3", "app.py"]
