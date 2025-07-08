import json
import time
import uuid
from datetime import datetime
from kafka import KafkaProducer
from faker import Faker

# Inicializa o Faker para gerar dados fictícios
fake = Faker()

# Configurações do Produtor Kafka
KAFKA_TOPIC = 'clickstream_events'
KAFKA_SERVER = 'localhost:9094'

def generate_click_event():
    """
    Gera um evento de clique simulado em formato JSON.
    """
    return {
        "event_id": str(uuid.uuid4()),
        "user_id": fake.uuid4(),
        "page_url": fake.uri(),
        "ip_address": fake.ipv4(),
        "user_agent": fake.user_agent(),
        "timestamp": datetime.utcnow().isoformat()
    }

def main():
    """
    Função principal que produz mensagens para o Kafka continuamente.
    """
    print("Iniciando produtor de eventos de clickstream...")
    
    try:
        producer = KafkaProducer(
            bootstrap_servers=[KAFKA_SERVER],
            # Codifica o valor da mensagem como JSON e depois para bytes
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            # Melhora a performance em cenários de alta produção
            linger_ms=10, 
            batch_size=16384 # 16KB
        )
        print(f"Conectado ao Kafka em {KAFKA_SERVER}")
    except Exception as e:
        print(f"Erro ao conectar ao Kafka: {e}")
        return
    try:
        while True:
            click_event = generate_click_event()
            # Envia a mensagem para o tópico Kafka
            producer.send(KAFKA_TOPIC, value=click_event)
            
            print("Evento enviado:", json.dumps(click_event, indent=2))
            
            # Espera um curto período antes de enviar o próximo evento
            time.sleep(2)
    except KeyboardInterrupt:
        print("\nProdutor interrompido pelo usuário.")
    finally:
        print("Fechando o produtor Kafka...")
        producer.flush() # Garante que todas as mensagens pendentes sejam enviadas
        producer.close()
        print("Produtor fechado.")

if __name__ == "__main__":
    main()