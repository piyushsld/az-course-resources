FROM python:3.13-slim
RUN mkdir /opt/flask_app
WORKDIR /opt/flask_app
COPY app.py requirements.txt /opt/flask_app/
ENTRYPOINT [ "gunicorn -w 1 --bind 127.0.0.1:8000 app:app" ]
