FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    hashcat \
    hcxtools \
    apache2 \
    php \
    libapache2-mod-php \
    wget \
    && rm -rf /var/lib/apt/lists/*

# إنشاء مجلد لكلمات المرور
RUN mkdir -p /var/www/html/wordlists

# نسخ الملفات
COPY index.html /var/www/html/
COPY upload.php /var/www/html/
COPY hashcat_wrapper.sh /usr/local/bin/
COPY wordlists/ /var/www/html/wordlists/

RUN chmod +x /usr/local/bin/hashcat_wrapper.sh && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# إعداد Apache
RUN a2enmod php8.1
EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]
