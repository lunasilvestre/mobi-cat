CREATE EXTERNAL TABLE `mitma`.`viajes_distritos`(
  `fecha` bigint, 
  `periodo` bigint, 
  `origen` string, 
  `destino` string, 
  `distancia` string, 
  `actividad_origen` string, 
  `actividad_destino` string, 
  `estudio_origen_posible` string, 
  `estudio_destino_posible` string, 
  `residencia` bigint, 
  `renta` string, 
  `edad` string, 
  `sexo` string, 
  `viajes` double, 
  `viajes_km` double)
PARTITIONED BY ( 
  `partition_0` string)
ROW FORMAT DELIMITED 
  FIELDS TERMINATED BY '|' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  's3://mobi-cat/mitma/raw/estudios_basicos/por-distritos/viajes/ficheros-diarios/'
TBLPROPERTIES (
  'CrawlerSchemaDeserializerVersion'='1.0', 
  'CrawlerSchemaSerializerVersion'='1.0', 
  'UPDATED_BY_CRAWLER'='mitma-crawler', 
  'areColumnsQuoted'='false', 
  'averageRecordSize'='104', 
  'classification'='csv', 
  'columnsOrdered'='true', 
  'compressionType'='gzip', 
  'delimiter'='|', 
  'objectCount'='814', 
  'partition_filtering.enabled'='true', 
  'recordCount'='2566294721', 
  'sizeKey'='145486548663', 
  'skip.header.line.count'='1', 
  'typeOfData'='file')

