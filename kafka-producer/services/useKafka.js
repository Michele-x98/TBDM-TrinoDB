const { v4: uuidv4 } = require("uuid");
const { Kafka } = require("kafkajs");

const kafka = new Kafka({
  clientId: "my-app",
  brokers: ["51.103.220.68:9092"],
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
