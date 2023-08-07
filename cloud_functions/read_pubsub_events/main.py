from concurrent.futures import TimeoutError
from google.cloud import pubsub_v1, storage
import requests, json, datetime, pytz, pandas

def callback(message: pubsub_v1.subscriber.message.Message) -> None:
    print(f"Received {message}.")
    message.ack()

def read_events_to_bucket(request) -> dict:
    """Read data from pubsub events."""

    events = {}

    try:
        # Read the data from subscription
        project_id = "raghuram-exec"
        subscription_id = "raghuram-exec-subscription-python-events"
        timeout = 5.0
        subscriber = pubsub_v1.SubscriberClient()
        subscription_path = subscriber.subscription_path(project_id, subscription_id)
        streaming_pull_future = subscriber.subscribe(subscription_path, callback=callback)
        print(f"Listening for messages on {subscription_path}")

        """
        df = pandas.DataFrame.from_dict(nzd_conversion, orient='index')
        file_name = '/tmp/'+'sample.json'
        df.to_json(file_name)

        # Uploading to bucket
        bucket_name = 'raghuram-exec-data-extraction'
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        bucket_filename = datetime.datetime.now(pytz.timezone("Pacific/Auckland")).strftime('%Y%m%d') + '-exchanges.json'
        blob = bucket.blob(f'crypto/{bucket_filename}')
        blob.upload_from_filename(file_name)
        """

        # Wrap subscriber in a 'with' block to automatically call close() when done.
        with subscriber:
            try:
                message = streaming_pull_future.result(timeout=timeout)
                print(f'In subscriber: {message}')
            except TimeoutError:
                streaming_pull_future.cancel()
                streaming_pull_future.result() 

    except Exception as e:
        raise e

    return events