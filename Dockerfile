FROM alpine:latest

ENV PORT=8080

USER 10014

RUN apk update && apk add --no-cache wget curl unzip tar

ADD install.sh .

EXPOSE $PORT
CMD ["sh", "install.sh"]
