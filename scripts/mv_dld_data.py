import os
import shutil
import xml.etree.ElementTree as ET
import argparse

# Parse command line arguments
parser = argparse.ArgumentParser(description='Organize downloaded files based on RSS and log information.')
parser.add_argument('--dry-run', action='store_true', help='Run the script in dry-run mode to see what actions would be taken without making any changes.')
args = parser.parse_args()

# Paths
base_path = '/home/nls/dev/mobilitat/data'  # Path where the flat files are stored
dest_base_path = '/home/nls/data/mitma'  # Destination path for organized files
rss_file = 'RSS.xml'
success_log_file = './logs/success.log'

# Parse the RSS XML to build a mapping of file names to directories
def parse_rss_to_directory_mapping(rss_file):
    tree = ET.parse(rss_file)
    root = tree.getroot()
    file_directory_mapping = {}

    for item in root.findall('.//item'):
        title = item.find('.//title').text.strip()
        file_name = title.split(']]')[0].split('[[')[-1]  # Extract filename from CDATA
        link = item.find('.//link').text.strip()
        file_directory = '/'.join(link.split('/')[3:-1])  # Create directory path from URL
        file_directory_mapping[file_name] = file_directory

    return file_directory_mapping

# Read the success log to get a list of successfully downloaded files
def read_success_log(success_log_file):
    with open(success_log_file, 'r') as file:
        return [line.strip().split('/')[-1] for line in file.readlines()]  # Extract filenames from URLs

# Main function to organize files
def organize_files(dry_run):
    file_directory_mapping = parse_rss_to_directory_mapping(rss_file)
    downloaded_files = read_success_log(success_log_file)

    for file_name in downloaded_files:
        src_file_path = os.path.join(base_path, file_name)
        if file_name in file_directory_mapping:
            dest_directory = os.path.join(dest_base_path, file_directory_mapping[file_name])
            dest_file_path = os.path.join(dest_directory, file_name)
            
            if dry_run:
                print(f"Dry Run: Would move {src_file_path} to {dest_file_path}")
            else:
                os.makedirs(dest_directory, exist_ok=True)
                shutil.move(src_file_path, dest_file_path)
                print(f"Moved {src_file_path} to {dest_file_path}")
        else:
            print(f"No directory mapping found for {file_name}, skipping...")

# Run the script
organize_files(args.dry_run)
