FROM debian:jessie
MAINTAINER Byron Zhang <xiaoqi_2591@outlook.com>

ENV NGROK_GIT https://github.com/inconshreveable/ngrok.git
ENV NGROK_BASE_DOMAIN tunnel.merrychris.com
ENV NGROK_DIR /ngrok
ENV NGROK_TMP /tmp/ngrok
ENV TMP /tmp

# darwin linux windows
ENV GOOS linux
# 386 amd64 arm
ENV GOARCH amd64

ENV NGROK_CA_KEY assets/client/tls/ngrokroot.key
ENV NGROK_CA_CRT assets/client/tls/ngrokroot.crt
ENV NGROK_SERVER_KEY assets/server/tls/snakeoil.key
ENV NGROK_SERVER_CSR assets/server/tls/snakeoil.csr
ENV NGROK_SERVER_CRT assets/server/tls/snakeoil.crt

WORKDIR $NGROK_DIR

RUN apt-get update \
    && apt-get install -y build-essential \
                          curl \
                          git \
                          mercurial \
    && cd ${TMP} \
    && curl -O https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz \
    && tar -xvf go1.6.linux-amd64.tar.gz \
    && mv go /usr/local \
    && export PATH=$PATH:/usr/local/go/bin \
    && git clone ${NGROK_GIT} ${NGROK_TMP} \
    && cd ${NGROK_TMP} \
    && openssl genrsa -out ${NGROK_CA_KEY} 2048 \
    && openssl req -new -x509 -nodes -key ${NGROK_CA_KEY} -subj "/CN=${NGROK_BASE_DOMAIN}" -days 365 -out ${NGROK_CA_CRT} \
    && openssl genrsa -out ${NGROK_SERVER_KEY} 2048 \
    && openssl req -new -key ${NGROK_SERVER_KEY} -subj "/CN=${NGROK_BASE_DOMAIN}" -out ${NGROK_SERVER_CSR} \
    && openssl x509 -req -in ${NGROK_SERVER_CSR} -CA ${NGROK_CA_CRT} -CAkey ${NGROK_CA_KEY} -CAcreateserial -days 365 -out ${NGROK_SERVER_CRT} \
    && echo "=== $GOOS-$GOARCH ==="; \
       make release-server release-client; \
       echo "=== done ===" \
    && mv ${NGROK_CA_KEY} \
          ${NGROK_CA_CRT} \
          ${NGROK_SERVER_KEY} \
          ${NGROK_SERVER_CSR} \
          ${NGROK_SERVER_CRT} \
          ./bin/* \
          ${NGROK_DIR} \
    && apt-get purge --auto-remove -y build-essential \
                                      curl \
                                      git \
                                      mercurial \
    && cd ${NGROK_DIR} \
    && rm -rf ${NGROK_TMP}

VOLUME $NGROK_DIR
EXPOSE 5000 5001 4443

CMD /bin/bash -c './ngrokd -domain="${NGROK_BASE_DOMAIN}" -httpAddr=":5000" -httpsAddr=":5001"'
