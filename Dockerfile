FROM python:3-alpine

RUN apk add --no-cache jq && pip3 install awscli gcloud

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]