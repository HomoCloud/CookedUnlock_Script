#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <original_file_path> <aes_password>"
  exit 1
fi

# Assign arguments to variables
FILE_PATH=$1
AES_PASSWORD=$2
OUTPUT_FILE="${FILE_PATH}.aes256cbc"

# Check if OpenSSL is installed
if ! command -v openssl >/dev/null 2>&1; then
  echo "Error: OpenSSL is not installed. Please install it and try again."
  exit 1
fi

# Check if the original file exists
if [ ! -f "$FILE_PATH" ]; then
  echo "Error: File '$FILE_PATH' does not exist."
  exit 1
fi

# Encrypt the file using OpenSSL
echo "Encrypting the file..."
openssl enc -aes-256-cbc -salt -in "$FILE_PATH" -out "$OUTPUT_FILE" -pass pass:"$AES_PASSWORD"
if [ $? -ne 0 ]; then
  echo "Failed to encrypt the file. Please check the input file and password."
  exit 1
fi

echo "File successfully encrypted and saved as $OUTPUT_FILE."
