import boto3
import csv
import argparse

# Initialize AWS session
session = boto3.Session(region_name='eu-west-1')
athena_client = session.client('athena')
glue_client = session.client('glue')

def list_databases():
    paginator = athena_client.get_paginator('list_databases')
    response_iterator = paginator.paginate(CatalogName='AwsDataCatalog')
    databases = []
    for response in response_iterator:
        databases.extend(response['DatabaseList'])
    return databases

def list_tables(database_name):
    paginator = athena_client.get_paginator('list_table_metadata')
    response_iterator = paginator.paginate(
        CatalogName='AwsDataCatalog',
        DatabaseName=database_name
    )
    tables = []
    for response in response_iterator:
        tables.extend(response['TableMetadataList'])
    return tables

def get_table_location(database_name, table_name):
    response = glue_client.get_table(
        DatabaseName=database_name,
        Name=table_name
    )
    return response['Table']['StorageDescriptor']['Location']

def main(database_filter, bucket_filter, output_file):
    databases = list_databases()
    filtered_data = []

    for database in databases:
        db_name = database['Name']
        if database_filter and db_name != database_filter:
            continue
        tables = list_tables(db_name)
        for table in tables:
            table_name = table['Name']
            location = get_table_location(db_name, table_name)
            if bucket_filter and bucket_filter not in location:
                continue
            filtered_data.append([db_name, table_name, location])

    # Write the results to a CSV file
    with open(output_file, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['Database', 'Table', 'S3 Location'])
        writer.writerows(filtered_data)

    print(f"Data written to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='List Athena tables and their S3 data sources.')
    parser.add_argument('--database', type=str, help='Filter by database name')
    parser.add_argument('--bucket', type=str, help='Filter by bucket name')
    parser.add_argument('--output', type=str, default='output.csv', help='Output CSV file name')

    args = parser.parse_args()

    main(args.database, args.bucket, args.output)
