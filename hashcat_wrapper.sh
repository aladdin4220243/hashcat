#!/bin/bash
# hashcat_wrapper.sh - سكريبت مساعد لتشغيل Hashcat مع إعدادات محسنة

echo "[+] Starting Hashcat Wrapper"

INPUT_FILE="$1"
HASH_TYPE="$2"
WORDLIST="$3"
OUTPUT_FILE="$4"

if [ -z "$INPUT_FILE" ] || [ -z "$HASH_TYPE" ] || [ -z "$WORDLIST" ]; then
    echo "Usage: $0 <input_file> <hash_type> <wordlist> [output_file]"
    exit 1
fi

if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="/tmp/hashcat_result_$(date +%s).txt"
fi

# التحقق من وجود الملفات
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

if [ ! -f "$WORDLIST" ]; then
    echo "Error: Wordlist not found: $WORDLIST"
    exit 1
fi

echo "[+] Input file: $INPUT_FILE"
echo "[+] Hash type: $HASH_TYPE"
echo "[+] Wordlist: $WORDLIST"
echo "[+] Output: $OUTPUT_FILE"

# تشغيل Hashcat مع خيارات محسنة
hashcat -m "$HASH_TYPE" \
        -a 0 \
        --force \
        --status \
        --status-timer=1 \
        --potfile-disable \
        -o "$OUTPUT_FILE" \
        "$INPUT_FILE" \
        "$WORDLIST" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
    echo "[+] Success! Cracked hashes saved to: $OUTPUT_FILE"
    echo "[+] Results:"
    cat "$OUTPUT_FILE"
else
    echo "[-] Hashcat failed with exit code: $EXIT_CODE"
fi

exit $EXIT_CODE
