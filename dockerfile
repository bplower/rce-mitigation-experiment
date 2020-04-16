FROM python:3.7.3-alpine

RUN apk add inotify-tools

# Install gunicorn
RUN python3 -m pip install --upgrade pip
RUN pip3 install gunicorn werkzeug

# Copy over the script and service files
COPY ./init_container.sh /build/init_container.sh
COPY ./service.py /build/service.py
WORKDIR /build

CMD ./init_container.sh
