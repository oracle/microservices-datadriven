# FROM oraclelinux:7-slim
FROM container-registry.oracle.com/os/oraclelinux:7-slim

ARG release=19
ARG update=9

RUN  yum -y install oracle-release-el7 && \
     yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install oracle-instantclient${release}.${update}-basiclite && \
     yum install -y oracle-epel-release-el7

WORKDIR /app
COPY foodwinepairing/requirements.txt .

RUN yum install -y tar && \
    yum install -y python36 && \
    rm -rf /var/cache/yum && \
    python3.6 -m pip install -U pip setuptools

#wine-pairing dependencies
RUN python3.6 -m pip install -U gensim==4.1.2 && \
	python3.6 -m pip install -U scikit-learn && \
	python3.6 -m pip install -U pandas && \
	python3.6 -m pip install -U nltk && \
	python3.6 -m pip install -U matplotlib && \
	python3.6 -m pip install -U ipython && \
	python3.6 -m pip install -r requirements.txt

#to locate if/where gunicorn is
RUN find / -name "gunicorn"

ADD common .
ADD foodwinepairing .
RUN echo 'Adding foodwinepairing done in DockerFile!'

CMD ["gunicorn", "app:app", "--config=config.py"]