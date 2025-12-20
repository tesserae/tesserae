FROM perl:5.30

RUN apt-get update && \
    apt-get install -y php && \
    rm -rf /var/lib/apt/lists/*

RUN cpanm Term::UI

WORKDIR /app

EXPOSE 8000

ENTRYPOINT ["php", "-S", "0.0.0.0:8000"]
