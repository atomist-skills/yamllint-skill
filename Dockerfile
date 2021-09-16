FROM python:rc@sha256:cfc285ff5313016e64c875f3c7d00da9890f773432ad0936f841e86b5fb11944

RUN apt-get update && apt-get install -y \
   jq \
   && rm -rf /var/lib/apt/lists/*

RUN pip install yamllint

WORKDIR /atm/home

ENTRYPOINT ["/bin/bash", "/app/yamllint.sh"]

COPY yamllint.* /app/
