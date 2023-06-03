FROM alpine:latest

ENV PORT=8080

RUN apk update && apk add --no-cache wget curl unzip tar

ADD .choreo .
ADD install.sh .

USER 10001
EXPOSE $PORT
ENTRYPOINT ["sh", "install.sh"]
