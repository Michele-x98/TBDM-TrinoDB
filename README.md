# TrinoDB

This repository is related to an University project for the course "Technology for Big Data Management" (TBDM). The main goal of the project was to analyse and study the potential of Kafka Broker and TrinoDB.

The implemented system for the project is composed of a docker-compose file where all the necessary images are configured, such as Zookeeper, Kafka, MongoDB, Mongo-Express, Kafdrop, and TrinoDB. The docker-compose file sets up the environment required for testing the connection between Kafka, MongoDB, and TrinoDB locally.

In addition to the docker-compose file, the repository contains a bash script called [run.sh](http://run.sh/) that automatically creates and sets up the environment for testing the connection between Kafka, MongoDB, and TrinoDB locally through a docker container.

## Usage

To use the system, follow these steps:

1. Clone this repository to your local machine. You can do this by using the `git clone` command on your terminal or by downloading the repository as a zip file and extracting it to your desired directory.

2. Once you have the repository on your local machine, navigate to the cloned directory. You can do this by opening your terminal and using the `cd` command followed by the path to the repository.

3. Run the `run.sh` script located in the root directory of the repository. This script will set up the necessary environment for the system to run.

4. Wait for the environment to be set up. Depending on your machine's processing power, this may take a few minutes.

5. Once the environment is set up, you can access the TrinoDB web interface by opening your preferred web browser and entering the URL `http://localhost:8080` in the address bar.

By following these steps, you will be able to use the system without any issues. If you encounter any problems, feel free to consult the documentation or seek help from the support team.

## System Components

The following components are included in the system:

- **Zookeeper**: A centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services.

- **Kafka**: A distributed streaming platform that is used to publish and subscribe to streams of records.

- **MongoDB**: A document-oriented NoSQL database used for storing large volumes of unstructured data.

- **Mongo-Express**: A web-based MongoDB administration tool that provides a user interface for managing MongoDB databases.

- **Kafdrop**: A web-based UI for viewing Kafka topics and browsing consumer groups.

- **TrinoDB**: A distributed SQL query engine that is used for querying and analyzing large volumes of data stored in various data sources.

## Conclusion

This project demonstrates the potential of using Kafka Broker and TrinoDB for managing and analyzing big data. By using the implemented system, users can easily set up an environment for testing the connection between Kafka, MongoDB, and TrinoDB.
