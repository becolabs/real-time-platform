from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.functions import from_json, col, window, when
from pyspark.sql.types import StructType, StructField, StringType, TimestampType
import os

# --- Constantes de Configuração ---
# É uma boa prática definir todas as configurações no topo do arquivo.
KAFKA_TOPIC = "clickstream_events"
KAFKA_SERVER = "kafka:9092"
CLICKHOUSE_SERVER = "clickhouse-server"
CLICKHOUSE_PORT = "8123"
CLICKHOUSE_DB = "real_time_analytics"
CLICKHOUSE_TABLE = "clickstream_aggregates"
CLICKHOUSE_USER = os.getenv("CLICKHOUSE_USER", "default")
CLICKHOUSE_PASSWORD = os.getenv("CLICKHOUSE_PASSWORD", "your_secret_password")

def write_to_clickhouse(batch_df: DataFrame, batch_id: int):
    """
    Função para escrever um micro-lote (DataFrame) no ClickHouse.
    Esta função é chamada para cada lote pela query de streaming via foreachBatch.
    """
    # Renomeia as colunas para corresponder à tabela do ClickHouse
    # e seleciona apenas as colunas necessárias.
    output_df = batch_df.select(
        col("window.start").alias("window_start"),
        col("window.end").alias("window_end"),
        col("page_url"),
        col("count").alias("click_count")
    )

    print(f"--- Escrevendo Lote #{batch_id} no ClickHouse ---")
    # Imprime os dados que serão escritos para fins de depuração
    output_df.show(truncate=False)

    # Escreve o DataFrame no ClickHouse usando o formato JDBC
    (
        output_df.write.format("jdbc")
        .mode("append")
        .option("url", f"jdbc:clickhouse://{CLICKHOUSE_SERVER}:{CLICKHOUSE_PORT}/{CLICKHOUSE_DB}")
        .option("dbtable", CLICKHOUSE_TABLE)
        .option("user", CLICKHOUSE_USER)
        .option("password", CLICKHOUSE_PASSWORD)
        .option("driver", "com.clickhouse.jdbc.ClickHouseDriver")
        .save()
    )
    print(f"--- Lote #{batch_id} escrito com sucesso! ---")


def main():
    """
    Função principal da aplicação Spark Streaming.
    """
    spark = SparkSession.builder \
        .appName("RealTimeClickstreamProcessor") \
        .getOrCreate()

    spark.sparkContext.setLogLevel("WARN")
    print("Aplicação Spark iniciada.")

    # 1. Ler os dados brutos do Kafka
    df_kafka = spark.readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", KAFKA_SERVER) \
        .option("subscribe", KAFKA_TOPIC) \
        .option("startingOffsets", "earliest") \
        .load()

    # 2. Parse e transformação inicial
    json_schema = StructType([
        StructField("event_id", StringType(), True),
        StructField("user_id", StringType(), True),
        StructField("page_url", StringType(), True),
        StructField("ip_address", StringType(), True),
        StructField("user_agent", StringType(), True),
        StructField("timestamp", StringType(), True)
    ])

    df_processed = df_kafka.select(col("value").cast("string").alias("json_string")) \
        .select(from_json(col("json_string"), json_schema).alias("data")) \
        .select("data.*") \
        .withColumn("timestamp", col("timestamp").cast(TimestampType()))

    # 3. Validação de Qualidade de Dados
    # Filtramos diretamente os dados válidos para simplificar o fluxo.
    # A lógica de quarentena foi removida para focar na persistência.
    # Podemos reintroduzi-la se necessário.
    df_valid_events = df_processed.filter(
        col("user_id").isNotNull() & (col("user_id") != "") &
        col("page_url").isNotNull() & (col("page_url") != "")
    )

    # 4. Processar Dados Válidos (Agregação)
    df_with_watermark = df_valid_events.withWatermark("timestamp", "2 minutes")
    df_aggregated = df_with_watermark.groupBy(
        window(col("timestamp"), "1 minute"),
        col("page_url")
    ).count()

    # 5. Escrever o stream agregado no ClickHouse usando foreachBatch
    # foreachBatch é o padrão ouro para escrever em sinks que não são nativamente de streaming.
    query = (
        df_aggregated.writeStream.outputMode("update")
        .foreachBatch(write_to_clickhouse)
        .queryName("WriteAggregatesToClickHouse")
        .start()
    )

    print("Query de escrita para o ClickHouse iniciada. Aguardando dados...")
    query.awaitTermination()

if __name__ == "__main__":
    main()