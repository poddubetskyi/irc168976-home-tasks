FROM library/httpd:latest
LABEL org.opencontainers.artifact.description='IRC168976 DevOps GL BaseCamp homework 09. Docker. Task 01'
LABEL org.opencontainers.image.authors='Volodymyr Poddubetskyi'
RUN /bin/sed -i 's/^Listen 80$/Listen 8080/' /usr/local/apache2/conf/httpd.conf
EXPOSE 8080
WORKDIR /usr/local/apache2/htdocs
ADD ./index.html ./
