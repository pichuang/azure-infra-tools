#!/bin/bash

FILENAME="1-vm-protect.example.csv"
UPLOAD_DIR="~/"
REPLACE_DIR="~/azure-infra-tools/azure-vm-maintenance/"


check_csv_file_exists() {
    if [ ! -f "$UPLOAD_DIR/$FILENAME" ]; then
        echo "File $FILENAME does not exist in $UPLOAD_DIR."
        exit 1
    fi
}

check_csv_file_exists

show_csv_file_content() {
    cat $UPLOAD_DIR/$FILENAME
}

show_csv_file_content

read -p "Do you want to copy and replace the csv file? (Y/n): " confirm
if [ "$confirm" != "Y" ]; then
    echo "Exiting."
    exit 1
fi

cp $UPLOAD_DIR/$FILENAME $REPLACE_DIR

echo "================================================"
echo "File $FILENAME copied to $REPLACE_DIR"
echo "================================================"
