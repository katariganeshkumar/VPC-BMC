"""
AWS Glue ETL Job Template for Snowflake Integration
This script demonstrates how to connect to Snowflake and perform ETL operations
"""

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
import boto3
import json

# Initialize Glue context
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'connection_name', 'secret_id'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Get Snowflake credentials from Secrets Manager
secrets_client = boto3.client('secretsmanager')
secret_response = secrets_client.get_secret_value(SecretId=args['secret_id'])
snowflake_creds = json.loads(secret_response['SecretString'])

# Snowflake connection parameters
snowflake_options = {
    "sfURL": f"{snowflake_creds['account']}.snowflakecomputing.com",
    "sfUser": snowflake_creds['user'],
    "sfPassword": snowflake_creds['password'],
    "sfDatabase": snowflake_creds['database'],
    "sfSchema": snowflake_creds['schema'],
    "sfWarehouse": snowflake_creds['warehouse'],
    "sfRole": snowflake_creds.get('role', ''),
    "sfAccount": snowflake_creds['account']
}

# Example: Read data from Snowflake
print("Reading data from Snowflake...")
snowflake_df = spark.read \
    .format("snowflake") \
    .options(**snowflake_options) \
    .option("dbtable", "YOUR_TABLE_NAME") \
    .load()

# Example: Transform data
print("Transforming data...")
transformed_df = snowflake_df.select("*").where("column_name > 100")

# Example: Write data back to Snowflake
print("Writing data to Snowflake...")
transformed_df.write \
    .format("snowflake") \
    .options(**snowflake_options) \
    .option("dbtable", "YOUR_OUTPUT_TABLE") \
    .mode("overwrite") \
    .save()

# Alternative: Write to S3
print("Writing data to S3...")
transformed_df.write \
    .mode("overwrite") \
    .parquet("s3://your-bucket/output/")

# Alternative: Read from S3 and write to Snowflake
print("Reading from S3 and writing to Snowflake...")
s3_df = spark.read.parquet("s3://your-bucket/input/")

s3_df.write \
    .format("snowflake") \
    .options(**snowflake_options) \
    .option("dbtable", "YOUR_TABLE_NAME") \
    .mode("append") \
    .save()

# Commit job
job.commit()

print("Job completed successfully!")
