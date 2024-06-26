input_file_path = '../logs/url_size.csv'
output_daily_counts_path = '../logs/daily_counts.txt'
output_monthly_counts_path = '../logs/monthly_counts.txt'

# Function to extract key for daily files
def extract_daily_key(filename):
    parts = filename.split('_')
    if len(parts) < 3:
        print(f"Unexpected filename format: {filename}")
        return None
    year_month = parts[0][:6]
    variable = '_'.join(parts[1:-1])
    aggregation = parts[-1].replace('.csv.gz', '').replace('.csv', '')
    if aggregation in ["distritos", "GAU", "municipios"]:
        return f"{year_month}_{variable}_{aggregation}"
    elif aggregation.endswith('descartados'):
        return f"{year_month}_{variable}_descartados"
    else:
        print(f"Unexpected aggregation: {filename}")
        return None

# Function to extract key for monthly files
def extract_monthly_key(filename):
    parts = filename.split('_')
    if len(parts) < 3:
        print(f"Unexpected filename format: {filename}")
        return None
    year = parts[0][:4]
    variable = '_'.join(parts[1:-1])
    aggregation = parts[-1].replace('.tar', '')
    if aggregation in ["distritos", "GAU", "municipios"]:
        return f"{year}_{variable}_{aggregation}"
    elif aggregation.endswith('descartados'):
        return f"{year}_{variable}_descartados"
    else:
        print(f"Unexpected aggregation: {filename}")
        return None

# Read the input file
with open(input_file_path, 'r') as file:
    lines = file.readlines()

# Initialize dictionaries to store counts
daily_counts = {}
monthly_counts = {}

# Parse the input file
for line in lines:
    url, _ = line.strip().split()

    filename = url.split('/')[-1]
    if filename.endswith('.tar'):
        key = extract_monthly_key(filename)
        if not key:
            continue
        if key in monthly_counts:
            monthly_counts[key] += 1
        else:
            monthly_counts[key] = 1
    elif filename.endswith('.csv.gz') or filename.endswith('.csv'):
        key = extract_daily_key(filename)
        if not key:
            continue
        if key in daily_counts:
            daily_counts[key] += 1
        else:
            daily_counts[key] = 1

# Write daily counts to the output file
with open(output_daily_counts_path, 'w') as output_file:
    for key, count in daily_counts.items():
        output_file.write(f"{key}: {count} files\n")

# Write monthly counts to the output file
with open(output_monthly_counts_path, 'w') as output_file:
    for key, count in monthly_counts.items():
        output_file.write(f"{key}: {count} files\n")

print(f"Daily counts have been written to {output_daily_counts_path}")
print(f"Monthly counts have been written to {output_monthly_counts_path}")
