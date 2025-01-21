#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <file_path> <aes_encrypted_file_url> <aes_password>"
  exit 1
fi

# Assign arguments to variables
FILE_PATH=$1
AES_URL=$2
AES_PASSWORD=$3

# Check if OpenSSL is installed
if ! command -v openssl >/dev/null 2>&1; then
  echo "Error: OpenSSL is not installed. Please install it and try again."
  exit 1
fi

# Temporary file for the downloaded encrypted file
TEMP_FILE=$(mktemp)

# Download the encrypted file
echo "Downloading encrypted file from $AES_URL..."
curl -s -o "$TEMP_FILE" "$AES_URL"
if [ $? -ne 0 ]; then
  echo "Failed to download the encrypted file."
  rm -f "$TEMP_FILE"
  exit 1
fi

# Decrypt the file using OpenSSL
echo "Decrypting the file..."
openssl enc -aes-256-cbc -d -in "$TEMP_FILE" -out "$FILE_PATH" -pass pass:"$AES_PASSWORD"
if [ $? -ne 0 ]; then
  echo "Failed to decrypt the file. Please check the password or the file format."
  rm -f "$TEMP_FILE"
  exit 1
fi

# Clean up temporary file
rm -f "$TEMP_FILE"

echo "File successfully decrypted and saved to $FILE_PATH."
