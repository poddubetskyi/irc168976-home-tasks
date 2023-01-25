FROM library/ubuntu:latest
LABEL org.opencontainers.artifact.description='IRC168976 DevOps GL BaseCamp homework 09. Docker. Task 02'
LABEL org.opencontainers.image.authors='Volodymyr Poddubetskyi'
RUN apt update -y -q && apt install iputils-ping -y -q && apt autoremove -y -q && apt clean -y -q
ENTRYPOINT [ "/usr/bin/ping","-D" ]
CMD [ "globallogic.com" ]
