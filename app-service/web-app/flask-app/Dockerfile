FROM python:3.13-slim

RUN mkdir /opt/flask_app

WORKDIR /opt/flask_app

COPY app.py requirements.txt /opt/flask_app/

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000

ENTRYPOINT ["gunicorn", "-w", "1", "--bind", "0.0.0.0:8000", "app:app"]