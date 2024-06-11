import aiohttp
import asyncio
from tqdm import tqdm
import logging
from xml.etree import ElementTree
import os

# Setup persistent logging
log_directory = './logs'
os.makedirs(log_directory, exist_ok=True)
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    handlers=[logging.FileHandler(f"{log_directory}/download.log"), logging.StreamHandler()])

# Ensure data directory exists
data_directory = './data'
os.makedirs(data_directory, exist_ok=True)

# Semaphore for concurrency control
semaphore = asyncio.Semaphore(8)

async def get_file_size(session, url):
    async with session.head(url) as response:
        size = response.headers.get('Content-Length', 0)
        return int(size)

async def download_file(session, url, retries=3):
    file_name = os.path.join(data_directory, url.split('/')[-1])
    if os.path.exists(file_name):
        local_size = os.path.getsize(file_name)
        remote_size = await get_file_size(session, url)
        if local_size == remote_size:
            logging.info(f"Skipping download, file already complete: {file_name}")
            return

    async with semaphore:
        try:
            async with session.get(url) as response:
                if response.status == 200:
                    temp_file = file_name + '.part'
                    with open(temp_file, 'wb') as f:
                        total = response.content_length
                        with tqdm(total=total, desc=file_name, unit='B', unit_scale=True, unit_divisor=1024, file=sys.stdout) as progress:
                            async for chunk in response.content.iter_chunked(1024):
                                f.write(chunk)
                                progress.update(len(chunk))
                    os.rename(temp_file, file_name)
                    logging.info(f"Downloaded {file_name}")
                else:
                    logging.error(f"Failed to download {file_name} with status: {response.status}")
                    if retries > 0:
                        logging.info(f"Retrying {file_name}, {retries} retries left")
                        await download_file(session, url, retries-1)
                    else:
                        logging.error(f"Failed to download {file_name} after retries")
        except Exception as e:
            logging.error(f"Error downloading {file_name}: {str(e)}")
            if retries > 0:
                logging.info(f"Retrying {file_name}, {retries} retries left")
                await download_file(session, url, retries-1)
            else:
                logging.error(f"Failed to download {file_name} after retries")

async def heartbeat(interval=300):
    while True:
        logging.info("Heartbeat: The system is still alive.")
        await asyncio.sleep(interval)

async def download_files_from_rss(rss_content):
    root = ElementTree.fromstring(rss_content)
    items = root.findall('.//item')
    queue = asyncio.PriorityQueue()

    async with aiohttp.ClientSession() as session:
        # Retrieve sizes and prioritize downloads
        for item in items:
            url = item.find('link').text
            file_size = await get_file_size(session, url)  # Retrieve size correctly with session
            await queue.put((file_size, url))

        # Start the heartbeat
        asyncio.create_task(heartbeat())

        # Process downloads
        while not queue.empty():
            _, url = await queue.get()
            await download_file(session, url)

def main(rss_path):
    try:
        with open('RSS.xml', 'r') as file:
            rss_content = file.read()
        asyncio.run(download_files_from_rss(rss_content))
    except Exception as e:
        logging.error(f"Failed to load and process RSS.xml: {str(e)}")

if __name__ == "__main__":
   logging.info("Script started")
   main('RSS.xml')
