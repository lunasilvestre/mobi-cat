# check_and_destroy.sh
if gcloud pubsub subscriptions pull --auto-ack "$PUBSUB_SUBSCRIPTION_NAME" --limit=1; then
  echo "Messages still in queue."
else
  echo "Queue empty, destroying cluster."
  terraform destroy
fi
