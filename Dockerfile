FROM ubuntu:20.10

# Enable production settings by default; for development, this can be set to 
# `false` in `docker run --env`
ENV DJANGO_PRODUCTION=true

# Set terminal to be noninteractive
ENV DEBIAN_FRONTEND noninteractive

# Enable MySQL root user creation without interactive input
RUN echo 'mysql-server mysql-server/root_password password devrootpass' | debconf-set-selections
RUN echo 'mysql-server mysql-server/root_password_again password devrootpass' | debconf-set-selections

# Install packages
RUN apt-get update && apt-get install -y \
    git \
    libmysqlclient-dev \
    mysql-server \
    nginx \
    python-dev \
    python3 \
    python3-pip \
    python3-mysqldb \
    python-setuptools \
    supervisor

# Handle urllib3 InsecurePlatformWarning
RUN apt-get install -y libffi-dev libssl-dev libpython3.8
RUN pip install urllib3[security] requests[security] ndg-httpsclient pyasn1

# Configure Django project
RUN mkdir /control
COPY requirements.txt /control/requirements.txt
COPY nginx.conf /control/nginx.conf
COPY initialize.sh /control/initialize.sh
RUN mkdir /code
RUN mkdir /djangomedia
RUN mkdir /static
RUN mkdir /logs
RUN mkdir /logs/nginx
RUN mkdir /logs/gunicorn
RUN pip install -r /control/requirements.txt
RUN chmod ug+x /control/initialize.sh

# Expose ports
# 80 = Nginx
# 8000 = Gunicorn
# 3306 = MySQL
EXPOSE 80 8000 3306

# Configure Nginx
RUN ln -s /control/nginx.conf /etc/nginx/sites-enabled/django_docker.conf
RUN rm /etc/nginx/sites-enabled/default

# Run Supervisor (i.e., start MySQL, Nginx, and Gunicorn)
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
