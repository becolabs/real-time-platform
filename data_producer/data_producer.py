import json
import time
import uuid
import random # Importamos a biblioteca random
from datetime import datetime
from kafka import KafkaProducer
from faker import Faker

# Inicializa o Faker para gerar dados fictícios que ainda precisamos (user_id, etc.)
fake = Faker()

# --- Configurações ---
KAFKA_TOPIC = 'clickstream_events'
KAFKA_SERVER = 'localhost:9094'

# --- SIMULAÇÃO DE NEGÓCIO: PÁGINAS E PESOS DE ACESSO ---
# O princípio aqui é simular um padrão de acesso realista.
# Algumas páginas são muito mais populares que outras.
PAGES = [
    {"url": "/home", "weight": 25},
    {"url": "/products/electronics", "weight": 15},
    {"url": "/products/books", "weight": 10},
    {"url": "/products/item/B08H75RTZ8", "weight": 7}, # Produto popular
    {"url": "/products/item/B09V3Z4X4X", "weight": 5},
    {"url": "/cart", "weight": 8},
    {"url": "/checkout", "weight": 4},
    {"url": "/login", "weight": 10},
    {"url": "/signup", "weight": 3},
    {"url": "/blog/top-10-gadgets", "weight": 5},
    {"url": "/blog/why-we-love-reading", "weight": 3},
    {"url": "/contact-us", "weight": 2},
    {"url": "/about-us", "weight": 3},
]

# Extraímos as URLs e os pesos em listas separadas para usar com random.choices
PAGE_URLS = [page["url"] for page in PAGES]
PAGE_WEIGHTS = [page["weight"] for page in PAGES]
BASE_URL = "http://www.e-commerce-example.com"

def get_random_page():
    """
    Seleciona uma URL da lista com base nos pesos definidos.
    Isso simula que algumas páginas são mais visitadas que outras.
    """
    # random.choices retorna uma lista, então pegamos o primeiro elemento [0]
    return random.choices(PAGE_URLS, weights=PAGE_WEIGHTS, k=1)[0]

def generate_click_event():
    """
    Gera um evento de clique simulado com uma URL realista.
    """
    page_path = get_random_page()
    return {
        "event_id": str(uuid.uuid4()),
        "user_id": fake.uuid4(),
        # Em vez de fake.uri(), usamos nossa lógica de negócio
        "page_url": f"{BASE_URL}{page_path}",
        "ip_address": fake.ipv4(),
        "user_agent": fake.user_agent(),
        "timestamp": datetime.utcnow().isoformat()
    }

def main():
    """
    Função principal que produz mensagens para o Kafka continuamente.
    """
    print("Iniciando produtor de eventos de clickstream (com lógica de negócio)...")
    
    try:
        producer = KafkaProducer(
            bootstrap_servers=[KAFKA_SERVER],
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            linger_ms=10, 
            batch_size=16384
        )
        print(f"Conectado ao Kafka em {KAFKA_SERVER}")
    except Exception as e:
        print(f"Erro ao conectar ao Kafka: {e}")
        return

    try:
        while True:
            click_event = generate_click_event()
            producer.send(KAFKA_TOPIC, value=click_event)
            print(f"Evento enviado: {click_event['page_url']}")
            # Reduzimos o tempo de espera para gerar mais dados e ver agregações mais rápido
            time.sleep(0.5) 
    except KeyboardInterrupt:
        print("\nProdutor interrompido pelo usuário.")
    finally:
        print("Fechando o produtor Kafka...")
        producer.flush()
        producer.close()
        print("Produtor fechado.")

if __name__ == "__main__":
    main()