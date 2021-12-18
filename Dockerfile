FROM python:rc@sha256:532e860a95afb13562603d2b84db1fe6ca164112a2b99e45fa451bd2c683f90d

RUN apt-get update && apt-get install -y \
   jq \
   && rm -rf /var/lib/apt/lists/*

RUN pip install yamllint

WORKDIR /atm/home

ENTRYPOINT ["/bin/bash", "/app/yamllint.sh"]

COPY yamllint.* /app/
