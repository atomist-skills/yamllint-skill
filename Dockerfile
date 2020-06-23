FROM python:rc

RUN apt-get update && apt-get install -y \
   jq \
   && rm -rf /var/lib/apt/lists/*

RUN pip install --user yamllint \
   && ln -s /root/.local/bin/yamllint /usr/local/bin/yamllint

WORKDIR /app
COPY yamllint.* /app/

WORKDIR /atm/home
ENTRYPOINT ["bash", "/app/yamllint.sh"]