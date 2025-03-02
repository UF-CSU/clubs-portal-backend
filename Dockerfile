FROM python:3.13-alpine3.20

LABEL maintainer="ikehunter.com"

# see logs immediately
ENV PYTHONUNBUFFERED=1

WORKDIR /app
USER root

# default to production
ARG DEV=false

RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client jpeg-dev && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base gcc musl-dev zlib zlib-dev linux-headers openssl-dev postgresql-dev && \
    /py/bin/pip install uwsgi==2.0.27 --retries 10

COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
    
RUN /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps

COPY ./scripts /scripts

RUN adduser \
    --disabled-password \
    --no-create-home \
    django-user && \
    mkdir -p /vol/web/media && \
    mkdir -p /vol/web/static && \
    chown -R django-user:django-user /vol && \
    chmod -R 755 /vol && \
    chmod -R +x /scripts


COPY ./app /app
ENV PATH="/scripts:/py/bin:/usr/bin:$PATH"
USER django-user

# VOLUME /vol/web
CMD ["/scripts/entrypoint.sh"]
