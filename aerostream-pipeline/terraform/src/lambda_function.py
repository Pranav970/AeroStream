import json
import logging
import uuid
from datetime import datetime, timezone

# Configure robust logging for CloudWatch
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    records_processed = 0
    
    for record in event.get('Records', []):
        message_id = record.get('messageId')
        try:
            # Parse the incoming JSON from SQS
            payload = json.loads(record['body'])
            logger.info(f"Processing Message ID: {message_id} | Payload: {payload}")
            
            # 1. Validation (Business Logic)
            if "user_id" not in payload or "action" not in payload:
                # Raising an exception flags this specific message as a failure.
                # SQS will retry it, then route it to the Dead Letter Queue (DLQ).
                raise ValueError(f"Malformed payload: Missing required fields 'user_id' or 'action'")
            
            # 2. Data Transformation (Simulated)
            processed_data = {
                "system_id": str(uuid.uuid4()),
                "original_event": payload,
                "processed_at": datetime.now(timezone.utc).isoformat(),
                "status": "CLEANED_AND_VERIFIED"
            }
            
            # Simulate saving to a database (DynamoDB/RDS)
            logger.info(f"Successfully processed and stored data: {json.dumps(processed_data)}")
            records_processed += 1
            
        except json.JSONDecodeError:
            logger.error(f"Failed to decode JSON for Message ID: {message_id}")
            raise
        except Exception as e:
            logger.error(f"Error processing Message ID: {message_id} | Error: {str(e)}")
            raise e # Triggers SQS DLQ routing
            
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully processed {records_processed} records.')
    }
