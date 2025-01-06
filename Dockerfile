FROM python:3.12.7-alpine
RUN apk update && apk add --no-cache postgresql-dev
COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir
