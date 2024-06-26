import re
from collections import defaultdict

# Define the input file paths
size_log_path = '../logs/url_size.csv'
output_file_path = '../logs/comparison_results.txt'

# Initialize dictionaries to store sizes
monthly_sizes = defaultdict(int)
daily_sizes = defaultdict(int)

# Define a function to convert human-readable sizes to bytes
def size_to_bytes(size):
    if size.endswith('G'):
        return float(size[:-1]) * 1024**3
    elif size.endswith('M'):
        return float(size[:-1]) * 1024**2
    else:
        return float(size)  # assuming size is already in bytes if no unit provided

# Read the size log file and process the content
with open(size_log_path, 'r') as file:
    for line in file:
        if "Size of" in line:
            parts = line.split()
            url = parts[2]
            size_bytes = int(parts[-2])
            month_match = re.search(r'/(\d{6})_', url)
            if month_match:
                month = month_match.group(1)
                if 'meses-completos' in url:
                    monthly_sizes[month] += size_bytes
                elif 'ficheiros-diarios' in url:
                    daily_sizes[month] += size_bytes

# Compare the sizes and write the results to a file
with open(output_file_path, 'w') as file:
    file.write("Month,Monthly TAR Size (Bytes),Summed Daily Size (Bytes),Difference (Bytes)\n")
    for month in sorted(monthly_sizes.keys()):
        monthly_size = monthly_sizes[month]
        daily_size = daily_sizes[month]
        difference = monthly_size - daily_size
        file.write(f"{month},{monthly_size},{daily_size},{difference}\n")

print(f"Comparison results saved to: {output_file_path}")
