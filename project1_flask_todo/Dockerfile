FROM python:3.10-slim-bullseye
WORKDIR /app
COPY requirements.txt /app
RUN apt-get update
RUN apt-get -y install libpq-dev libpq-dev python3-dev
RUN apt-get -y install gcc
RUN pip install --upgrade pip
RUN pip install --upgrade pip setuptools wheel
RUN pip install psycopg2-binary
RUN pip install -r requirements.txt
RUN pip install uwsgi
COPY templates /app/templates
COPY flask_app.py /app
COPY uwsgi.ini /app
COPY wsgi.py /app

ENV DB_HOST=172.26.10.11
ENV DB_PORT=5432
ENV DB_NAME=todo_db
ENV DB_USER=postgres
ENV DB_PASSWORD=mysecretpassword
CMD ["uwsgi", "--ini", "uwsgi.ini", "--http", ":9090"]