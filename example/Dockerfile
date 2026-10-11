# Example: a virtual Pi that runs a web server on port 8080.
# Build the base image first: docker build -t vpi ..
ARG BASE=vpi
FROM ${BASE}

COPY server.py setup.sh /vpi/setup/

ENV PORTS=8080
EXPOSE 8080
