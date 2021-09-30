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
RUN yum install -y python
RUN python -m pip install -U gensim
RUN python -m pip install -U scikit-learn
RUN python -m pip install -r requirements.txt
	

ADD common .
ADD foodwinepairing .
RUN echo 'Adding foodwinepairing done in DockerFile!'

CMD ["gunicorn", "app:app", "--config=config.py"]