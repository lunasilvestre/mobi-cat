import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Load CSV data from the Glue Data Catalog
datasource0 = glueContext.create_dynamic_frame.from_catalog(database = "mitma", table_name = "ficheros_diarios_74d2c4f431342d28a33fa3a79d36a123", transformation_ctx = "datasource0")

# Convert to Parquet
applymapping1 = ApplyMapping.apply(frame = datasource0, mappings = [
    ("fecha", "long", "fecha", "long"),
    ("periodo", "long", "periodo", "long"),
    ("origen", "string", "origen", "string"),
    ("destino", "string", "destino", "string"),
    ("distancia", "string", "distancia", "string"),
    ("actividad_origen", "string", "actividad_origen", "string"),
    ("actividad_destino", "string", "actividad_destino", "string"),
    ("estudio_origen_posible", "string", "estudio_origen_posible", "string"),
    ("estudio_destino_posible", "string", "estudio_destino_posible", "string"),
    ("residencia", "long", "residencia", "long"),
    ("renta", "string", "renta", "string"),
    ("edad", "string", "edad", "string"),
    ("sexo", "string", "sexo", "string"),
    ("viajes", "double", "viajes", "double"),
    ("viajes_km", "double", "viajes_km", "double"),
    ("partition_0", "string", "partition_0", "string")
], transformation_ctx = "applymapping1")

# Write to S3 as Parquet
sink = glueContext.write_dynamic_frame.from_options(frame = applymapping1, connection_type = "s3", connection_options = {"path": "s3://mobi-cat/mitma/parquet/"}, format = "parquet", transformation_ctx = "sink")

job.commit()
