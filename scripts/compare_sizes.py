input_file_path = '../logs/url_size.csv'
output_file_path = '../logs/size_comp_final.txt'

# Function to extract key based on the filename
def extract_key(filename):
    parts = filename.split('_')
    if len(parts) < 3:
        print(f"Unexpected filename format: {filename}")
        return None
    year_month = parts[0][:6]
    variable = parts[1]
    aggregation = parts[2].replace('.tar', '').replace('.csv.gz', '').replace('.csv', '')
    return f"{year_month}_{variable}_{aggregation}"

# Read the input file
with open(input_file_path, 'r') as file:
    lines = file.readlines()

# Initialize dictionaries to store sizes
daily_sizes = {}
monthly_sizes = {}

# Parse the input file
for line in lines:
    url, size = line.strip().split()
    size = int(size)

    filename = url.split('/')[-1]
    key = extract_key(filename)

    if not key:
        continue

    if filename.endswith('.tar'):
        monthly_sizes[key] = size
    elif filename.endswith('.csv.gz') or filename.endswith('.csv'):
        if key in daily_sizes:
            daily_sizes[key] += size
        else:
            daily_sizes[key] = size

# Compare the sizes and write the results to the output file
with open(output_file_path, 'w') as output_file:
    for key in monthly_sizes:
        monthly_size = monthly_sizes[key]
        daily_size = daily_sizes.get(key, 0)
        output_file.write(f"{key}\n")
        output_file.write(f"Monthly Size (tar): {monthly_size} bytes\n")
        output_file.write(f"Total Daily Size (csv.gz): {daily_size} bytes\n")
        output_file.write(f"Difference: {monthly_size - daily_size} bytes\n\n")

print(f"Comparison results have been written to {output_file_path}")
