FROM oraclelinux:7-slim

ARG release=19
ARG update=9

RUN  yum -y install oracle-release-el7 && \
     yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install oracle-instantclient${release}.${update}-basiclite && \
     yum install -y oracle-epel-release-el7

WORKDIR /app
COPY foodwinepairing/requirements.txt .
RUN yum install -y tar && \
    yum install -y python37 \
    yum install -y python37-oci-sdk && \
    rm -rf /var/cache/yum && \
    python3.7 -m pip install -U gensim && \
	python3.7 -m pip install -U scikit-learn && \
    python3.7 -m pip install -r requirements.txt
	

ADD common .
ADD foodwinepairing .
RUN echo 'Adding foodwinepairing done in DockerFile!'

CMD ["gunicorn", "app:app", "--config=config.py"]