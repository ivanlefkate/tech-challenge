FROM python:3.9-slim-buster

WORKDIR /app
ADD . /app

RUN pip install -r requirements.txt

ENV FLASK_APP=/app/app.py

EXPOSE 5000
CMD ["flask", "run", "--with-threads", "--host=0.0.0.0"]