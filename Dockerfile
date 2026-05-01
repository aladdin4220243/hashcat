FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# تثبيت الحزم المطلوبة
RUN apt-get update && apt-get install -y \
    hashcat \
    hcxtools \
    apache2 \
    php \
    libapache2-mod-php \
    php-cli \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# إعداد PHP
RUN echo "memory_limit = 512M" > /etc/php/8.1/apache2/conf.d/99-custom.ini && \
    echo "max_execution_time = 300" >> /etc/php/8.1/apache2/conf.d/99-custom.ini && \
    echo "upload_max_filesize = 100M" >> /etc/php/8.1/apache2/conf.d/99-custom.ini && \
    echo "post_max_size = 100M" >> /etc/php/8.1/apache2/conf.d/99-custom.ini

# إنشاء مجلد لكلمات المرور
RUN mkdir -p /var/www/html/wordlists

# نسخ ملفات المشروع (تأكد من وجودها في المستودع)
COPY index.html /var/www/html/
COPY upload.php /var/www/html/
COPY hashcat_wrapper.sh /usr/local/bin/
COPY wordlists/ /var/www/html/wordlists/

# إعطاء الصلاحيات
RUN chmod +x /usr/local/bin/hashcat_wrapper.sh && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# تعطيل مواقع Apache الافتراضية وتمكين موقعنا
RUN a2dissite 000-default.conf && \
    a2ensite 000-default.conf

# إعداد Apache للاستماع على جميع الواجهات
RUN echo "Listen 0.0.0.0:80" >> /etc/apache2/ports.conf

# فتح المنفذ 80
EXPOSE 80

# بدء Apache في المقدمة (foreground)
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
