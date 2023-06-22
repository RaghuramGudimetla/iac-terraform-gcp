from google.cloud import storage
import pandas as pd
import requests
import json
from datetime import datetime
import pytz

def upload_blob(event, context):
    """Uploads a file to the bucket."""
    nzd_currency_api = "https://cdn.jsdelivr.net/gh/fawazahmed0/currency-api@1/latest/currencies/nzd.json"
    print(f"URL: {nzd_currency_api}")

    response = requests.get(nzd_currency_api)
    json_response = json.loads(response.text)
    nzd_conversion = json_response['nzd']
    df = pd.DataFrame.from_dict(nzd_conversion, orient='index')
    file_name = '/tmp/'+'sample.json'
    df.to_json(file_name)

    # Uploading to bucket
    bucket_name = 'raghuram-exec-data-extraction'
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    bucket_filename = datetime.now(pytz.timezone("Pacific/Auckland")).strftime('%Y%m%d') + '-nzd-currency.json'
    blob = bucket.blob(bucket_filename)
    blob.upload_from_filename(file_name)