FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# تثبيت الحزم
RUN apt-get update && \
    apt-get install -y \
    hashcat \
    hcxtools \
    php \
    php-cli \
    wget \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# إعداد PHP
RUN echo "memory_limit = 512M" > /etc/php/8.1/cli/conf.d/99-custom.ini && \
    echo "max_execution_time = 300" >> /etc/php/8.1/cli/conf.d/99-custom.ini && \
    echo "upload_max_filesize = 100M" >> /etc/php/8.1/cli/conf.d/99-custom.ini && \
    echo "post_max_size = 100M" >> /etc/php/8.1/cli/conf.d/99-custom.ini

# إنشاء المجلدات
RUN mkdir -p /app/wordlists

# نسخ الملفات
COPY index.html /app/
COPY upload.php /app/
COPY hashcat_wrapper.sh /usr/local/bin/
COPY wordlists/ /app/wordlists/

# إعطاء الصلاحيات
RUN chmod +x /usr/local/bin/hashcat_wrapper.sh && \
    chmod -R 755 /app

# تعيين مجلد العمل
WORKDIR /app

# فتح المنفذ
EXPOSE 8000

# تشغيل خادم PHP المدمج
CMD ["php", "-S", "0.0.0.0:8000"]
