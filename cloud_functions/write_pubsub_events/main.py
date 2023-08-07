from concurrent.futures import TimeoutError
from google.cloud import pubsub_v1
import requests, json

def write_events(request) -> dict:
    """Write data from pubsub events."""

    api_url =  "https://api.coingecko.com/api/v3/exchanges"
    data = requests.get(api_url)
    event = {
        "type": "exchanges",
        "data": data.json()
    }
    event_str = json.dumps(event).encode("utf-8")
    published_events = {}
    
    try:

        # Write the data from subscription
        project_id = "raghuram-exec"
        topic_id = "raghuram-exec-topic-python-events"
        publisher = pubsub_v1.PublisherClient()
        topic_path = publisher.topic_path(project_id, topic_id)

        future = publisher.publish(topic_path, event_str)
        published_events['future_id'] = future.result()

    except Exception as e:
        raise e

    return published_events