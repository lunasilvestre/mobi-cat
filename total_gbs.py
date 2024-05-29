import xml.etree.ElementTree as ET
import requests

def fetch_file_size(url):
    """Fetch size of the file from the URL using the HEAD request to minimize data transfer."""
    try:
        response = requests.head(url)
        size = int(response.headers.get('content-length', 0))
        return size
    except Exception as e:
        print(f"Error fetching size for {url}: {e}")
        return 0

def calculate_total_size(xml_file):
    """Parse XML and calculate the total size of the files."""
    tree = ET.parse(xml_file)
    root = tree.getroot()
    namespace = {'content': 'http://purl.org/rss/1.0/modules/content/'}
    total_size = 0
    
    for item in root.findall('.//item/link', namespaces=namespace):
        url = item.text
        file_size = fetch_file_size(url)
        total_size += file_size
        print(f"Size of {url} is {file_size} bytes.")
    
    return total_size

# Path to your RSS XML file
xml_file = 'RSS.xml'
total_size = calculate_total_size(xml_file)
print(f"Total size of files to download: {total_size / (1024 ** 3)} GB")
