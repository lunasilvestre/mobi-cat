import xml.etree.ElementTree as ET

def parse_rss_to_directory_mapping(rss_content):
    root = ET.fromstring(rss_content)
    file_directory_mapping = {}

    for item in root.findall('.//item'):
        file_name = item.find('.//title').text.strip()
        link = item.find('.//link').text.strip()
        # Extract the directory structure from the URL, excluding the domain and filename
        path_segments = link.split('/')[3:-1]  # This excludes 'https://' (first 3 segments) and the last segment (filename)
        file_directory = '/'.join(path_segments)
        file_directory_mapping[file_name] = file_directory

    return file_directory_mapping

# Sample RSS content to test with
rss_content = '''
<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
  <channel>
    <item>
      <title><![CDATA[202403_Viajes_distritos.tar]]></title>
      <link>https://movilidad-opendata.mitma.es/estudios_basicos/por-distritos/viajes/meses-completos/202403_Viajes_distritos.tar</link>
    </item>
    <item>
      <title><![CDATA[202403_Personas_dia_distritos.tar]]></title>
      <link>https://movilidad-opendata.mitma.es/estudios_basicos/por-distritos/personas/meses-completos/202403_Personas_dia_distritos.tar</link>
    </item>
  </channel>
</rss>
'''

# Test the function
mapping = parse_rss_to_directory_mapping(rss_content)
print(mapping)
