FROM oraclelinux:7-slim

ARG release=19
ARG update=9

RUN  yum -y install oracle-release-el7 && \
     yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install oracle-instantclient${release}.${update}-basiclite && \
     yum install -y oracle-epel-release-el7

WORKDIR /app
COPY foodwinepairing/requirements.txt .
RUN yum install -y tar

# Update apt packages
RUN apt update
RUN apt upgrade -y

# Install python 3.7
RUN apt install software-properties-common -y
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt install python3.7 -y

# Make python 3.7 the default
RUN echo "alias python=python3.7" >> ~/.bashrc
RUN export PATH=${PATH}:/usr/bin/python3.7
RUN /bin/bash -c "source ~/.bashrc"

# Install pip
RUN apt install python3-pip -y
RUN python -m pip install --upgrade pip

#wine-pairing dependencies
RUN python -m pip install -U gensim
RUN python -m pip install -U scikit-learn
RUN python -m pip install -r requirements.txt

ADD common .
ADD foodwinepairing .
RUN echo 'Adding foodwinepairing done in DockerFile!'

CMD ["gunicorn", "app:app", "--config=config.py"]