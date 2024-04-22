# FROM oraclelinux:7-slim
FROM container-registry.oracle.com/os/oraclelinux:7-slim

ARG release=19
ARG update=9

RUN  yum -y install oracle-release-el7 && \
     yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install oracle-instantclient${release}.${update}-basiclite && \
     yum install -y oracle-epel-release-el7

WORKDIR /app
COPY inventory/requirements.txt .
RUN yum install -y tar && \
    yum install -y python36 && \
    rm -rf /var/cache/yum && \
    python3.6 -m pip install -U pip setuptools && \
    python3.6 -m pip install -r requirements.txt

ADD inventory .
ADD common .
RUN echo 'done!'

CMD ["gunicorn", "app:app", "--config=config.py"]
