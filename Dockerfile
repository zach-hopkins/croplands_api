# Builder
FROM usgsastro/debian:8

ENV PIP_CERT /etc/ssl/certs/ca-certificates.crt
ENV REQUESTS_CA_BUNDLE /etc/ssl/certs/ca-certificates.crt

SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    apt-get install -y \
        gfortran \
        libffi-dev \
        libgeos-dev \
        libjpeg-dev \
        liblapack-dev \
        libopenjp2-7-dev \
        libopenblas-dev \
        libpq-dev \
        libtiff-dev \
        libzip-dev \
        proj-bin \
        python \
        python-dev \
        python-pip \
    && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

RUN useradd -m appuser

WORKDIR /home/appuser
COPY . app
RUN chown -R appuser:appuser app

WORKDIR app
USER appuser

ENV PATH "/home/appuser/.local/bin:$PATH"
RUN pip install --user -U pip 'setuptools<45' && \
    pip install --user Cython cffi==1.3.0 virtualenv 'zipp<2' && \
    virtualenv .env
RUN source .env/bin/activate && \
    pip install -r requirements.txt

# Runner
FROM usgsastro/debian:8

SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    apt-get install -y \
        libffi6 \
        libgeos-c1 \
        libjpeg62 \
        liblapack3 \
        libopenjp2-7 \
        libopenblas-base \
        libpq5 \
        libtiff5 \
        libzip2 \
        proj-bin \
        python \
        python-pip \
    && rm -rf /var/cache/apt/* /var/lib/apt/lists/*


RUN useradd -m appuser
USER appuser
COPY --from=0 /home/appuser/app /home/appuser/app
WORKDIR /home/appuser/app/croplands-api

ENV PATH="/home/appuser/app/.env/bin:$PATH"

EXPOSE 8000
CMD gunicorn herokuapp:app -b :8000 --workers=2 -k gevent -t 45 --log-level=DEBUG
