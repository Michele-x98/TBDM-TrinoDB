GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NONE='\033[0m'


kafka_bash(){
  COMMAND=$1
  SLEEP_AMOUNT=$2
  # Execute the given command inside the Kafka container.
  docker exec -it kafka bash -c "$COMMAND"
  # If the second argument is not empty, sleep for the given amount of time.
  if [ ! -z "$SLEEP_AMOUNT" ]; then
    sleep $SLEEP_AMOUNT
  fi
}

# check if docker-compose is running, if yes, down it.
if [ "$(docker-compose ps -q)" ]; then
  echo "${BLUE}STOPPING THE CONTAINERS.${NONE}"
  docker-compose down
fi


# Get host ip address.
export HOST_IP="`(ifconfig en0 || ifconfig eth0) | grep inet | grep -oE "inet [0-9]+.[0-9]+.[0-9]+.[0-9]+" | awk '{print $2}'`"
echo "\nHost IP: ${BLUE}$HOST_IP ${NONE}\n"

echo "${YELLOW}STARTING CONTAINERS. ${NONE}"
docker-compose up -d
sleep 10

#check the status of the containers.
echo "${GREEN}CONTAINERS STARTED - STATUS ${NONE}"
docker ps
sleep 5

echo "OPENING KAFKA SHELL AND EXPORTING ${BLUE}KAFKA_HOME${NONE}."
# Set KAFKA_HOME variable to the Kafka installation directory.
kafka_bash "export KAFKA_HOME=/opt/kafka"

# Create user topic.
kafka_bash "\$KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 1 --partitions 1 --topic users" 10
echo "CREATED TOPIC USER ${GREEN}SUCCESSFULLY${NONE}."

# Create repos topic.
kafka_bash "\$KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 1 --partitions 1 --topic repos" 10
echo "CREATED TOPIC REPOS ${GREEN}SUCCESSFULLY${NONE}."

# Check the topics.
echo "CHECK ${YELLOW}TOPICS${NONE}."
kafka_bash "\$KAFKA_HOME/bin/kafka-topics.sh --zookeeper  zookeeper:2181 --describe"


GET_CONNECTOR="wget https://d1i4a15mxbxib1.cloudfront.net/api/plugins/mongodb/kafka-connect-mongodb/versions/1.9.1/mongodb-kafka-connect-mongodb-1.9.1.zip && unzip mongodb-kafka-connect-mongodb-1.9.1.zip"
# Copy the connector to the Kafka Connect plugins directory.
COPY_CONNECTOR="mkdir -p /opt/kafka/plugins/mongodb-connector && cd mongodb-kafka-connect-mongodb-1.9.1/lib && cp -R * /opt/kafka/plugins/mongodb-connector"

# Download the MongoDB connector inside docker, uzip it and copy it inside plugins directory.
echo "${YELLOW}DOWNLOAD MONGODB CONNECTOR ${NONE}."
kafka_bash "$GET_CONNECTOR && $COPY_CONNECTOR" 10

# Install nano with apt.
kafka_bash "apk update && apk add nano" 10

# Edit the Kafka Connect configuration file by adding the MongoDB connector plugin path.
KAKFA_PLUGIN="plugin.path=/usr/local/share/java,/usr/local/share/kafka/plugins,/opt/connectors,/opt/kafka/plugins"
kafka_bash "echo $KAKFA_PLUGIN >> /opt/kafka/config/connect-distributed.properties"
echo "KAFKA CONFIG FILE - PLUGIN PATH ${GREEN}SETTED${NONE}.\n"
# kafka_bash "cat /opt/kafka/config/connect-distributed.properties | grep plugin.path"

# Start Kafka Connect.
echo "${YELLOW}START KAFKA CONNECTOR${NONE}.\n"
# run a bash shell inside the kafka container and start the Kafka Connect service.
docker exec kafka bash -c "\$KAFKA_HOME/bin/connect-distributed.sh \$KAFKA_HOME/config/connect-distributed.properties" &


sleep 50


# Check the Kafka Connect REST API.
# curl localhost:8083/ | jq
# curl localhost:8083/connector-plugins | jq
# curl localhost:8083/connectors
docker exec -it kafka bash -c "curl localhost:8083/connector-plugins | jq"


# Create the MongoDB connector configuration file and add the content to the file.
kafka_bash """echo '''{
  \"name\": \"mongo-sink-users\",
  \"config\": {
    \"connector.class\": \"com.mongodb.kafka.connect.MongoSinkConnector\",
    \"topics\": \"users\",
    \"connection.uri\": \"mongodb://root:example@mongo:27017\",
    \"key.converter\": \"org.apache.kafka.connect.storage.StringConverter\",
    \"value.converter\": \"org.apache.kafka.connect.json.JsonConverter\",
    \"value.converter.schemas.enable\": false,
    \"database\": \"ghdb\",
    \"collection\": \"users\"
  }
}''' >> mongodb_connector_users.json"""

# Create the MongoDB connector.
kafka_bash "curl -s -X POST -H 'Content-Type: application/json' http://localhost:8083/connectors -d @mongodb_connector_users.json"
sleep 5

# Check the status of the connector.
kafka_bash "curl -s "http://localhost:8083/connectors/mongo-sink-users/status""
sleep 5


# Create the MongoDB connector configuration file.
kafka_bash """echo '''{
  \"name\": \"mongo-sink-repos\",
  \"config\": {
    \"connector.class\": \"com.mongodb.kafka.connect.MongoSinkConnector\",
    \"topics\": \"repos\",
    \"connection.uri\": \"mongodb://root:example@mongo:27017\",
    \"key.converter\": \"org.apache.kafka.connect.storage.StringConverter\",
    \"value.converter\": \"org.apache.kafka.connect.json.JsonConverter\",
    \"value.converter.schemas.enable\": false,
    \"database\": \"ghdb\",
    \"collection\": \"repos\"
  }
}''' >> mongodb_connector_repos.json"""

# Create the MongoDB connector.
kafka_bash "curl -s -X POST -H 'Content-Type: application/json' http://localhost:8083/connectors -d @mongodb_connector_repos.json"
sleep 5

# Check the status of the connector.
kafka_bash "curl -s "http://localhost:8083/connectors/mongo-sink-repos/status""

# [OPTIONAL] Consumer to check the data in the topics:
# $KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic users --from-beginning
# $KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic repos --from-beginning

echo "${GREEN}Done${NONE} ✅"
