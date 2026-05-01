FROM ubuntu:22.04

# منع الأسئلة التفاعلية أثناء التثبيت
ENV DEBIAN_FRONTEND=noninteractive

# تثبيت Hashcat والأدوات المطلوبة
RUN apt-get update && apt-get install -y \
    hashcat \
    hcxtools \
    apache2 \
    php \
    libapache2-mod-php \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# تحميل ملف كلمات صغير للاختبار
RUN mkdir -p /var/www/html/wordlists && \
    cd /var/www/html/wordlists && \
    wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-100.txt -O small.txt

# نسخ ملفات المشروع
COPY index.html /var/www/html/
COPY upload.php /var/www/html/

# صلاحيات التشغيل
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# إعداد Apache
RUN a2enmod php8.1
EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]
