const { Kafka } = require("kafkajs");

const kafka = new Kafka({
  clientId: "my-app",
  brokers: ["pkc-zpjg0.eu-central-1.aws.confluent.cloud:9092"],
  ssl: true,
  sasl: {
    mechanism: "plain",
    username: "username",
    password: "password",
  },
});

const body = {
  name: "amrando",
  surname: "xheka",
  age: "22",
  city: "Prishtina",
  country: "Kosovo",
  complex: {
    name: "amrando",
    surname: "xheka",
    age: "22",
    city: "Prishtina",
    country: "Kosovo",
  },
};
const producer = kafka.producer();
async function run() {
  await producer.connect();
  await producer.send({
    topic: "test",
    messages: [{ key: "22", value: JSON.stringify(body) }],
  });

  await producer.disconnect();
}

run().catch(console.error);
