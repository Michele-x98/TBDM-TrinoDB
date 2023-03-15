const { v4: uuidv4 } = require("uuid");
const { Kafka } = require("kafkajs");

const kafka = new Kafka({
  clientId: "my-app",
  brokers: ["192.168.1.3:9092"],
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

  if (messages.length > 100) {
    let i,
      j,
      temparray,
      chunk = 100;
    for (i = 0, j = messages.length; i < j; i += chunk) {
      temparray = messages.slice(i, i + chunk);
      await producer.send({
        topic: topic,
        messages: temparray,
      });
    }
  } else {
    await producer.send({
      topic: topic,
      messages: messages,
    });
  }

  await producer.disconnect();
};

module.exports = { runKafka };
