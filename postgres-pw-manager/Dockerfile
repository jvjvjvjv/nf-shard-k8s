FROM python:3.14-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir flask bcrypt gunicorn psycopg2-binary \
    --only-binary psycopg2-binary

EXPOSE 5000

CMD ["/bin/bash"]
