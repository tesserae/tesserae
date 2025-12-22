FROM perl:5.30

RUN apt-get update && \
    apt-get install -y apache2 libapache2-mod-php dos2unix && \
    rm -rf /var/lib/apt/lists/*

RUN cpanm Term::UI CGI Lingua::Stem

RUN a2enmod cgi

RUN a2disconf serve-cgi-bin || true

WORKDIR /app

RUN sed -i 's|/var/www/html|/app|g' /etc/apache2/sites-available/000-default.conf

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    echo "<Directory /app>" >> /etc/apache2/apache2.conf && \
    echo "    Options +ExecCGI +Indexes +FollowSymLinks" >> /etc/apache2/apache2.conf && \
    echo "    AllowOverride All" >> /etc/apache2/apache2.conf && \
    echo "    Require all granted" >> /etc/apache2/apache2.conf && \
    echo "    AddHandler cgi-script .pl" >> /etc/apache2/apache2.conf && \
    echo "    DirectoryIndex index.php index.pl index.html" >> /etc/apache2/apache2.conf && \
    echo "</Directory>" >> /etc/apache2/apache2.conf

EXPOSE 80

RUN echo '#!/bin/bash' > /start.sh && \
    echo 'find /app -name "*.pl" -exec dos2unix {} \;' >> /start.sh && \
    echo 'find /app -name "*.pl" -exec chmod +x {} +' >> /start.sh && \
    echo 'exec apachectl -D FOREGROUND' >> /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]
