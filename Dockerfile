FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# تثبيت Nginx, PHP-FPM, Hashcat
RUN apt-get update && \
    apt-get install -y \
    nginx \
    php-fpm \
    php-cli \
    hashcat \
    hcxtools \
    wget \
    curl \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# إعداد PHP
RUN echo "memory_limit = 512M" > /etc/php/8.1/fpm/conf.d/99-custom.ini && \
    echo "max_execution_time = 300" >> /etc/php/8.1/fpm/conf.d/99-custom.ini && \
    echo "upload_max_filesize = 100M" >> /etc/php/8.1/fpm/conf.d/99-custom.ini && \
    echo "post_max_size = 100M" >> /etc/php/8.1/fpm/conf.d/99-custom.ini && \
    echo "max_input_time = 300" >> /etc/php/8.1/fpm/conf.d/99-custom.ini

# إعداد Nginx
RUN rm /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# إنشاء المجلدات
RUN mkdir -p /app/wordlists
RUN mkdir -p /var/www/html

# نسخ الملفات
COPY index.html /app/
COPY upload.php /app/
COPY hashcat_wrapper.sh /usr/local/bin/
COPY wordlists/ /app/wordlists/

# إعطاء الصلاحيات
RUN chmod +x /usr/local/bin/hashcat_wrapper.sh && \
    chmod -R 755 /app && \
    chown -R www-data:www-data /app /var/www/html

# إعداد Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# فتح المنفذ
EXPOSE 80

# تشغيل Supervisor (يدير Nginx و PHP-FPM)
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
