FROM ubuntu:18.04

ARG release=19
ARG update=9

WORKDIR /app
COPY foodwinepairing/requirements.txt .

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

# Add 3.7 to the available alternatives
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1

# Set python3.7 as the default python
RUN update-alternatives --set python /usr/bin/python3.7

# Install pip
RUN apt install python3-pip -y
RUN python -m pip install --upgrade pip

#wine-pairing dependencies
RUN python -m pip install -U gensim
RUN python -m pip install -U scikit-learn
RUN python -m pip install -r requirements.txt

#to locate if/where gunicorn is
RUN find / -name "gunicorn"

ADD common .
ADD foodwinepairing .
RUN echo 'Adding foodwinepairing done in DockerFile!'

CMD ["gunicorn", "app:app", "--config=config.py"]