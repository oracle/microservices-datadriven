FROM oraclelinux:7-slim

ARG release=19
ARG update=3

WORKDIR /app
COPY ./inventory/* /app/
ADD ./common /app

RUN  yum -y install oracle-release-el7 && \
     yum-config-manager --enable ol7_oracle_instantclient && \
     yum -y install oracle-instantclient${release}.${update}-basiclite && \
     yum install -y oracle-epel-release-el7 && \
     yum install -y python36 && \
     yum install -y tar && \
     rm -rf /var/cache/yum && \
     python3.6 -m pip install -r requirements.txt

CMD ["gunicorn", "app:app", "--config=config.py"]
