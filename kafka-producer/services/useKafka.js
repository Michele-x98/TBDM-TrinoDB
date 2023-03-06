const { v4: uuidv4 } = require("uuid");
const { Kafka } = require("kafkajs");

const kafka = new Kafka({
	clientId: "my-app",
	brokers: ["pkc-zpjg0.eu-central-1.aws.confluent.cloud:9092"],
	ssl: true,
	sasl: {
		mechanism: "plain",
		username: "5HCBNTR7HD5PMEVP",
		password: "9JVCyuWbQJHwXJ18CUkZ1RJPARPgGRVvENJ5RRBFqs/jPupHNE1TKKv/bYYF4agz",
	},
});

const producer = kafka.producer();

const runKafka = async (topic, ...newMessages) => {
	let messages = [];

	newMessages.forEach((element) => {
		if (Array.isArray(element)) {
			element.forEach((message) => {
				messages.push({
					key: uuidv4(),
					value: JSON.stringify(message),
				});
			});
		} else {
			messages.push({
				key: uuidv4(),
				value: JSON.stringify(element),
			});
		}
	});
	console.log(messages.length);

	await producer.connect();
	await producer.send({
		topic: topic,
		messages: messages,
	});

	await producer.disconnect();
};

module.exports = { runKafka };
