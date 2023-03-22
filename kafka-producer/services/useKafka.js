const { v4: uuidv4 } = require("uuid");
const { Kafka } = require("kafkajs");

const kafka = new Kafka({
  clientId: "my-app",
  brokers: ["localhost:9092"],
});

const producer = kafka.producer();

const runKafka = async (topic, n, ...newMessages) => {
  let messages = [];

  // ADDING KEY VALUE AS UUID
  newMessages.forEach((element) => {
    element.forEach((message) => {
      messages.push({
        key: uuidv4(),
        value: JSON.stringify(message),
      });
    });
  });

  console.log(messages.length);

  await producer.connect();

  if (topic === "repos") {
    for (let index = 0; index < n; index++) {
      if (messages.length > 100) {
        let i;
        let j;
        let temparray;
        let chunk = 100;

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
