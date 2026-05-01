FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# تثبيت الحزم
RUN apt-get update && \
    apt-get install -y \
    hashcat \
    hcxtools \
    apache2 \
    php \
    libapache2-mod-php \
    php-cli \
    wget \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# إعداد PHP
RUN echo "memory_limit = 512M" > /etc/php/8.1/apache2/conf.d/99-custom.ini && \
    echo "max_execution_time = 300" >> /etc/php/8.1/apache2/conf.d/99-custom.ini && \
    echo "upload_max_filesize = 100M" >> /etc/php/8.1/apache2/conf.d/99-custom.ini && \
    echo "post_max_size = 100M" >> /etc/php/8.1/apache2/conf.d/99-custom.ini

# إنشاء المجلدات
RUN mkdir -p /var/www/html/wordlists

# نسخ الملفات
COPY index.html /var/www/html/
COPY upload.php /var/www/html/
COPY hashcat_wrapper.sh /usr/local/bin/
COPY wordlists/ /var/www/html/wordlists/

# إعطاء الصلاحيات
RUN chmod +x /usr/local/bin/hashcat_wrapper.sh && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# إعداد Apache - الطريقة المبسطة
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# تعطيل Apachectl الافتراضي واستخدام الأمر المباشر
EXPOSE 80

# بدء Apache في المقدمة (Foreground)
CMD ["apache2ctl", "-D", "FOREGROUND"]
