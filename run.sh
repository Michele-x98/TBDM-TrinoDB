# Get Host IP.
export HOST_IP="`(ifconfig en0 || ifconfig eth0) | grep inet | grep -oE "inet [0-9]+.[0-9]+.[0-9]+.[0-9]+" | awk '{print $2}'`"


GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NONE='\033[0m'

topics=()

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

add_topic(){
    # Loop to ask for string inputs
    while true; do
        read -p "Enter a topic name (or press Q to continue): " input_string
        
        # Check if the user wants to finish
        if [[ $input_string == "Q" ]]; then
            # if the array is empty, ask again.
            if [[ ${#topics[@]} -eq 0 ]]; then
                echo "❌ You need to add at least one topic."
                continue
            fi
            break
        fi

        # If the input string is empty, ask again
        if [[ -z $input_string ]]; then
            continue
        fi
        
        # Append the input string to the array
        topics+=("$input_string")

        echo "✅ Topic $input_string added successfully."
    done

    echo "Current topics:"

    # Print the array of strings one by one with the indexes.
    for index in "${!topics[@]}"; do
        echo "$index: ${topics[$index]}"
    done

    # Ask the user if he wants to add more topics.
    read -p "Do you want to add more topics? (Y/N): " add_more

    # If the user wants to add more topics, call the script again.
    if [[ $add_more == "Y" ]]; then
        add_topic
    fi
}

create_topics() {
  echo "CREATING TOPICS."

  # print the topics array length.
  echo "Number of topics: ${#topics[@]}"

  # for each topic inside topics array, create a topic.

 for topic in "${topics[@]}"; do
    echo "CREATING TOPIC ${BLUE}$topic${NONE}."
    # Create the topic.
    kafka_bash "\$KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 1 --partitions 1 --topic $topic"
    # # while the topic is not created, wait.
    while [ -z "$(docker exec -it kafka bash -c "\$KAFKA_HOME/bin/kafka-topics.sh --zookeeper zookeeper:2181 --list | grep $topic")" ]; do
      echo "⏳${YELLOW}WAITING FOR TOPIC $topic TO BE CREATED.${NONE}"
      sleep 2
    done
    echo "✅ CREATED TOPIC ${BLUE}$topic${NONE} ${GREEN}SUCCESSFULLY${NONE}."
    sleep 2
  done
}

create_mongodb_connectors() {
  echo "CREATING MONGODB CONNECTOR."
  # for each topic, create a connector.
  for topic in "${topics[@]}"; do
    echo "📡 CREATING MONGODB CONNECTOR FOR TOPIC ${BLUE}$topic${NONE}."
    
    # Delete the connector if it already exists.
    # kafka_bash "curl -X DELETE http://localhost:8083/connectors/mongo-sink-$topic" 2

    # Create the MongoDB connector configuration file and add the content to the file.
    kafka_bash """echo '''{
      \"name\": \"mongo-sink-$topic\",
      \"config\": {
        \"connector.class\": \"com.mongodb.kafka.connect.MongoSinkConnector\",
        \"topics\": \"$topic\",
        \"connection.uri\": \"mongodb://root:example@mongo:27017\",
        \"key.converter\": \"org.apache.kafka.connect.storage.StringConverter\",
        \"value.converter\": \"org.apache.kafka.connect.json.JsonConverter\",
        \"value.converter.schemas.enable\": false,
        \"database\": \"ghdb\",
        \"collection\": \"$topic\"
      }
    }''' >> mongodb_connector_$topic.json"""

    # Create the MongoDB connector.
    kafka_bash "curl -X POST -H \"Content-Type: application/json\" --data @mongodb_connector_$topic.json http://localhost:8083/connectors"

    # # while the connector with name mongo-sink-$topic is not created, wait.
    while [ -z "$(docker exec -it kafka bash -c "curl -X GET http://localhost:8083/connectors | grep -o $topic")" ]; do
      echo "$⏳ {YELLOW}WAITING FOR MONGODB CONNECTOR FOR TOPIC $topic TO BE CREATED.${NONE}"
      sleep 2
    done

    echo "\n✅ CREATED MONGODB CONNECTOR FOR TOPIC ${BLUE}$topic${NONE} ${GREEN}SUCCESSFULLY${NONE}."
    sleep 2

    # Check the status of the connector.
    kafka_bash "curl -s "http://localhost:8083/connectors/mongo-sink-$topic/status""
    sleep

  done    
}

# Check id kafka image is downloaded and if not, download it.
if [ -z "$(docker images | grep wurstmeister/kafka)" ]; then
  echo "${YELLOW}DOWNLOADING KAFKA IMAGE.${NONE}"
  docker pull wurstmeister/kafka:latest
fi

# Check id zookeeper image is downloaded and if not, download it.
if [ -z "$(docker images | grep wurstmeister/zookeeper)" ]; then
  echo "${YELLOW}DOWNLOADING ZOOKEEPER IMAGE.${NONE}"
  docker pull wurstmeister/zookeeper:latest
fi

# Check id mongo image is downloaded and if not, download it.
if [ -z "$(docker images | grep mongo)" ]; then
  echo "${YELLOW}DOWNLOADING MONGO IMAGE.${NONE}"
  docker pull mongo:latest
fi

# Check id mongo-express image is downloaded and if not, download it.
if [ -z "$(docker images | grep mongo-express)" ]; then
  echo "${YELLOW}DOWNLOADING MONGO EXPRESS IMAGE.${NONE}"
  docker pull mongo-express:latest
fi

# Check id trino image is downloaded and if not, download it.
if [ -z "$(docker images | grep trino)" ]; then
  echo "${YELLOW}DOWNLOADING TRINO IMAGE.${NONE}"
  docker pull trinodb/trino:latest
fi

# Check id kafdrop image is downloaded and if not, download it.
if [ -z "$(docker images | grep kafdrop)" ]; then
  echo "${YELLOW}DOWNLOADING KAFDROP IMAGE.${NONE}"
  docker pull obsidiandynamics/kafdrop:latest
fi

# check if docker-compose is running, if yes, down it.
if [ "$(docker-compose ps -q)" ]; then
  echo "❌ ${BLUE}STOPPING THE CONTAINERS.${NONE}"
  docker-compose down
  # while all the containers are not down, wait.
  while [ "$(docker-compose ps -q)" ]; do
    echo "⏳ ${YELLOW}WAITING FOR THE CONTAINERS TO STOP.${NONE}"
    sleep 5
  done
fi


echo "\nHost IP: ${BLUE}$HOST_IP${NONE}\n"
echo "\n${GREEN} Use $HOST_IP IP to navigate through containers.${NONE}\n"
sleep 2

echo "📡 ${YELLOW}STARTING CONTAINERS. ${NONE}\n"
docker-compose up -d

# while all the containers are not up and running, wait.
while [ -z "$(docker-compose ps -q)" ]; do
  echo "⏳ ${YELLOW}WAITING FOR THE CONTAINERS TO START.${NONE}"
  sleep 10
done

#check the status of the containers.
echo "✅ ${GREEN}CONTAINERS STARTED - STATUS ${NONE}"
docker ps
sleep 5

echo "OPENING KAFKA SHELL AND EXPORTING ${BLUE}KAFKA_HOME${NONE}."
# Set KAFKA_HOME variable to the Kafka installation directory.
kafka_bash "export KAFKA_HOME=/opt/kafka"

add_topic

echo "Current topics:"
for index in "${!topics[@]}"; do
    echo "$index: ${topics[$index]}"
done

create_topics

# Check the topics.
echo "🔍 CHECK ${YELLOW}TOPICS${NONE}."
kafka_bash "\$KAFKA_HOME/bin/kafka-topics.sh --zookeeper  zookeeper:2181 --describe"

# Install nano with apt.
echo "📥 ${YELLOW}INSTALLING NANO AND UNZIP.${NONE}"
kafka_bash "apt-get update && apt-get -y install nano && apt-get install unzip" 10


GET_CONNECTOR="wget https://d1i4a15mxbxib1.cloudfront.net/api/plugins/mongodb/kafka-connect-mongodb/versions/1.9.1/mongodb-kafka-connect-mongodb-1.9.1.zip && unzip mongodb-kafka-connect-mongodb-1.9.1.zip"
# Copy the connector to the Kafka Connect plugins directory.
COPY_CONNECTOR="mkdir -p /opt/kafka/plugins/mongodb-connector && cd mongodb-kafka-connect-mongodb-1.9.1/lib && cp -R * /opt/kafka/plugins/mongodb-connector"

# Download the MongoDB connector inside docker, uzip it and copy it inside plugins directory.
echo "${YELLOW}DOWNLOAD MONGODB CONNECTOR ${NONE}."
kafka_bash "$GET_CONNECTOR && $COPY_CONNECTOR"

echo "✅ ${YELLOW}MONGODB CONNECTOR DOWNLOADED AND COPIED SUCCESSFULLY.${NONE}"

# Edit the Kafka Connect configuration file by adding the MongoDB connector plugin path.
KAKFA_PLUGIN="plugin.path=/usr/local/share/java,/usr/local/share/kafka/plugins,/opt/connectors,/opt/kafka/plugins"
kafka_bash "echo $KAKFA_PLUGIN >> /opt/kafka/config/connect-distributed.properties"
echo "KAFKA CONFIG FILE - PLUGIN PATH ${GREEN}SETTED${NONE}.\n"
# kafka_bash "cat /opt/kafka/config/connect-distributed.properties | grep plugin.path"

# Start Kafka Connect.
echo "${YELLOW}START KAFKA CONNECTOR${NONE}.\n"
# run a bash shell inside the kafka container and start the Kafka Connect service.
docker exec kafka bash -c "\$KAFKA_HOME/bin/connect-distributed.sh \$KAFKA_HOME/config/connect-distributed.properties &> /dev/null" &
sleep 10
echo "✅ KAFKA CONNECTOR ${GREEN}UP${NONE} AND ${GREEN}RUNNING${NONE} ON PORT ${BLUE}8083${NONE}.\n"
sleep 2

# Check the Kafka Connect REST API.
# curl localhost:8083/ | jq
# curl localhost:8083/connector-plugins | jq
# curl localhost:8083/connectors

echo "🔍 ${YELLOW}CHECK CONNECTORS${NONE}."
docker exec -it kafka bash -c "curl localhost:8083/connector-plugins | jq"
sleep 5

create_mongodb_connectors

# [OPTIONAL] Consumer to check the data in the topics:
# $KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic users --from-beginning
# $KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic repos --from-beginning

sleep 2
echo "🔍 ${YELLOW}CHECK CONNECTORS${NONE}."
docker exec -it kafka bash -c "curl localhost:8083/connectors" 

echo "\n${GREEN}All Done${NONE} ✅"
