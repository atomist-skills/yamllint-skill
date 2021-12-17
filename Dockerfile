FROM python:rc@sha256:df22191c9bd11f22464cf78fa71432c7b652193d01e7035bab7ecf0217b010f6

RUN apt-get update && apt-get install -y \
   jq \
   && rm -rf /var/lib/apt/lists/*

RUN pip install yamllint

WORKDIR /atm/home

ENTRYPOINT ["/bin/bash", "/app/yamllint.sh"]

COPY yamllint.* /app/
