FROM ubuntu:14.04
MAINTAINER Shisei Hanai<ruimo.uno@gmail.com>

RUN apt-get update
RUN apt-get install -y wget
RUN apt-get install -y build-essential
RUN apt-get install -y libpcre3-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y libxml2-dev
RUN apt-get install -y libxslt-dev
RUN apt-get install -y libgd-dev
RUN apt-get install -y libgeoip-dev
RUN apt-get install -y monit
RUN apt-get install -y openssh-server
RUN apt-get install -y w3m

# Compile nginx 1.7.2
RUN \
  cd /tmp && \
  wget http://nginx.org/download/nginx-1.7.2.tar.gz && \
  tar xf nginx-1.7.2.tar.gz

RUN \
  cd /tmp/nginx-1.7.2 && \
  ./configure --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-log-path=/var/log/nginx/access.log \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --with-pcre-jit \
    --with-debug \
    --with-http_addition_module \
    --with-http_dav_module \
    --with-http_geoip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-http_ssl_module \
    --with-http_sub_module \
    --with-http_xslt_module \
    --with-ipv6 \
    --with-sha1=/usr/include/openssl \
    --with-md5=/usr/include/openssl \
    --with-mail \
    --with-mail_ssl_module && \
  make && \
  make install

ADD monit   /etc/monit/conf.d/

# This is a user for ssh login. Initial password = 'password'.
RUN useradd -p `perl -e "print(crypt('password', 'AB'));"` -s /bin/bash --create-home --user-group nginx

# Force to change password.
RUN passwd -e nginx
RUN gpasswd -a nginx sudo

# Use non standard port for ssh(22) to prevent atack.
RUN sed -i.bak "s/Port 22/Port 2201/" /etc/ssh/sshd_config

RUN mkdir /home/nginx/.ssh
ONBUILD ADD authorized_keys /home/nginx/.ssh/authorized_keys
ONBUILD RUN chmod 755 /home/nginx
ONBUILD RUN chmod 600 /home/nginx/.ssh/authorized_keys
ONBUILD RUN chown -R nginx:nginx /home/nginx/.ssh

EXPOSE 80
EXPOSE 443
EXPOSE 2201

CMD ["/usr/bin/monit", "-I", "-c", "/etc/monit/monitrc"]
