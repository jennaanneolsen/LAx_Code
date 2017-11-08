import pandas as pd
from pyspark.sql import *
from pyspark.ml import Pipeline
from pyspark.ml.feature import OneHotEncoder, StringIndexer, VectorAssembler

#Connect to Oracle db
usr="wgubi"
pwd="st4ts4r34Ws0me"
url = "jdbc:oracle:thin:"+usr+"/"+pwd+"@//10.9.8.82:1521/users_prd"

#Import data from oracle (python)
# enrollPy=spark.read.format("jdbc").option("url", url).option("dbtable", "(select * from LAX_CRS_ENROLL where c_id <> 'ORA1')").option("driver","oracle.jdbc.OracleDriver").option("user", usr).option("password", pwd).option("lowerBound",1).option("fetchSize",10000).option("numPartitions",20000).load()

#pull the data into a Python dataframe
df_enroll_py = spark.sql("select t.*, s.students_enrolled from crs_enroll_test t join crs_enroll_count_sql s on t.c_id = s.c_id and t.month_end_date = s.month_end_date where t.c_id <> 'ORA1' limit 100")

categoricalColumns = ["C_DIVS", "C_DEPT","C_SUBJ","C_COLLEGE", "C_LEVEL","C_COLL_LEV","S_PROGRAM","S_COLLEGE","S_LEVEL","S_COLL_LEV"]
stages = [] #stages in the pipeline -- handled later

for categoricalCol in categoricalColumns:
  #Index with StringIndexer
  stringIndexer = StringIndexer(inputCol=categoricalCol, outputCol=categoricalCol+"Index")
  #Use OneHotEncoder to convert categorical variables to binary sparseVectors
  encoder = OneHotEncoder(inputCol=categoricalCol+"Index", outputCol=categoricalCol+"classVec")
  #add stages -- not run here but will be needed later
  stages += [stringIndexer, encoder]

#convert label into indices using StringIndexer  
label_stringIdx = StringIndexer(inputCol = "students_enrolled", outputCol="label")
stages += [label_stringIdx]

#Transform features into vector using VectorAssembler
numericCols = ["MONTH_END_DATE","C_ID","C_VERSION","C_CREDITS","C_PATH_ORDER","S_ID","TERM_CODE","DAYS_INTO_TERM","S_TERM_SEQ"]
assemblerInputs = map(lambda c: c+ "classVec", categoricalColumns) + numericCols
assembler = VectorAssembler(inputCols=assemblerInputs, outputCol="features")
stages += [assembler]

#Create a pipeline
pipeline = Pipeline(stages=stages)
#Run features transformations
#  - fit() computes feature statistics as needed.
#  - transform() actually transforms the features.
pipelineModel = pipeline.fit(df_enroll_py)
dataset = pipelineModel.transform(df_enroll_py)

# Keep relevant columns
selectedcols = ["label", "features"] + cols
dataset = dataset.select(selectedcols)
display(dataset)


