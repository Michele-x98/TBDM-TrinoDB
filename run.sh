#Start the docker containers
docker-compose up -d

#Go to the Kafka Connect container
docker exec -it kafka bash

#Set KAFKA_HOME variable to the Kafka installation directory
KAFKA_HOME=/opt/kafka

#Create users topic in Kafka
$KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper 51.103.220.68:2181 --replication-factor 1 --partitions 1 --topic users

#Create repos topic in Kafka
$KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper 51.103.220.68:2181 --replication-factor 1 --partitions 1 --topic repos

#Check the topics
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper  51.103.220.68:2181 --describe

#Download the MongoDB connector
wget https://d1i4a15mxbxib1.cloudfront.net/api/plugins/mongodb/kafka-connect-mongodb/versions/1.9.1/mongodb-kafka-connect-mongodb-1.9.1.zip

#Unzip the connector
unzip mongodb-kafka-connect-mongodb-1.9.1.zip

#Copy the connector to the Kafka Connect plugins directory
mkdir -p /opt/kafka/plugins/mongodb-connector
cd mongodb-kafka-connect-mongodb-1.9.1/lib
cp -R *  /opt/kafka/plugins/mongodb-connector

#Install nano
apk update
apk add nano

#Edit the Kafka Connect configuration file
nano /opt/kafka/config/connect-distributed.properties
uncomment plugins..
add plugin.path=/opt/kafka/plugins

#Start Kafka Connect
$KAFKA_HOME/bin/connect-distributed.sh $KAFKA_HOME/config/connect-distributed.properties

#Check the Kafka Connect REST API
curl localhost:8083/ | jq
curl localhost:8083/connector-plugins | jq
curl localhost:8083/connectors

#Create the MongoDB connector configuration file
nano mongodb_connector_user.json

#Add the following content to the file
{
  "name": "mongo-sink-users",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSinkConnector",
    "topics": "users",
    "connection.uri": "mongodb://root:example@mongo:27017",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": false,
    "database": "ghdb",
    "collection": "users"
  }
}

#Create the MongoDB connector
curl -s -X POST -H 'Content-Type: application/json' http://localhost:8083/connectors -d @mongodb_connector_user.json

#Check the status of the connector
curl -s "http://localhost:8083/connectors/mongo-sink-users/status"

#Create the MongoDB connector configuration file
nano mongodb_connector_repos.json

#Add the following content to the file
{
  "name": "mongo-sink-repos",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSinkConnector",
    "topics": "repos",
    "connection.uri": "mongodb://root:example@mongo:27017",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": false,
    "database": "ghdb",
    "collection": "repos"
  }
}

#Create the MongoDB connector
curl -s -X POST -H 'Content-Type: application/json' http://localhost:8083/connectors -d @mongodb_connector_repos.json

#Check the status of the connector
curl -s "http://localhost:8083/connectors/mongo-sink-repos/status"

# [OPTIONAL] Consumer to check the data in the topics:
$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic users --from-beginning
$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic repos --from-beginning
