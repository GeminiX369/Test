FROM alpine:latest

ENV PORT=8080

RUN apk update && apk add --no-cache wget curl unzip tar

ADD install.sh .

USER www
EXPOSE $PORT
ENTRYPOINT ["sh", "install.sh"]
