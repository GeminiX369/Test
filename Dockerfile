FROM alpine:latest

ENV PORT=8080

USER 10014

RUN sudo apk update && sudo apk add --no-cache wget curl unzip tar

ADD install.sh .

EXPOSE $PORT
CMD ["sudo", "sh", "install.sh"]
