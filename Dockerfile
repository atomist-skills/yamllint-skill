FROM python:rc

RUN apt-get update && apt-get install -y \
   jq \
   && rm -rf /var/lib/apt/lists/*

RUN pip install yamllint

WORKDIR /atm/home

ENTRYPOINT ["/bin/bash", "/app/yamllint.sh"]

COPY yamllint.* /app/
