const git = require("./services/useGithub");
const kafka = require("./services/useKafka");
const { Kafka } = require("kafkajs");
const prompt = require("prompt-sync")();

const mainUsers = ["ArmandoXheka", "Michele-x98", "flaviopopoff"];

let userPropertiesToGet = ["name", "login", "avatar_url", "type"];
let reposPropertiesToGet = [
  "name",
  "description",
  "url",
  "created_at",
  "stars",
  "forks",
  "language",
  "open_issues",
  "topics",
  "license",
];
let followerPropertiesToGet = ["login"];
let followingPropertiesToGet = ["login"];

// FUNCTION THAT SELECTS ONLY THE FIELD REQUIRED
// IF VALUE ISN'T INSIDE THE OBJECT IT PASS AWAY WITH NO ERRORS
function pickOnlySelectedValue(obj) {
  return obj.login;
}

// GETUSER AND SELECT FIELDS REQUESTED
const getUser = async (username) => {
  return await git.fetchGetGithubUser(username);
};

const getUserRepos = async (username) => {
  let repos = await git.fetchGetGithubUserRepos(username);
  for (let index = 0; index < repos.length; index++) {
    repos[index].login = username;
    repos[index].license = repos[index].license?.name ?? null;
  }
  return repos;
};

const getFollowers = async (username) => {
  let res = await git.fetchGetGithubUserFollowers(username);
  return res.map((el) => pickOnlySelectedValue(el, ...followerPropertiesToGet));
};

const getFollowings = async (username) => {
  let res = await git.fetchGetGithubUserFollowings(username);
  return res.map((el) =>
    pickOnlySelectedValue(el, ...followingPropertiesToGet)
  );
};

const getTopics = () => {
  let topic = prompt("Insert topic name between users and repos: ");
  return ["users", "repos"].includes(topic) ? topic : getTopics();
};

const getN = () => {
  let n = prompt("Insert the number of replication: ");
  return n > 0 ? n : getN();
};

// INIT
const init = async () => {
  // GET TOPIC NAME FROM USER INPUT AND CHECK IF IT'S CORRECT, otherwise ask again
  const topic = getTopics();

  console.time();

  let users = mainUsers;
  // GET ALL FOLLOWERS FOR ALL THE USERS ON LIST AND TRANSFORM ALL IN AN ARRAY OF OBJECTS
  const followersPromises = users.map((name) => getFollowers(name));
  let followers = (await Promise.all(followersPromises)).flat(Infinity);
  console.log("Followers  --> ", followers.length);

  // GET ALL FOLLOWINGS FOR ALL THE USERS ON LIST AND TRANSFORM ALL IN AN ARRAY OF OBJECTS
  const followingsPromises = users.map((name) => getFollowings(name));
  let followings = (await Promise.all(followingsPromises)).flat(Infinity);
  console.log("Followings  --> ", followings.length);

  // REMOVE REDUNDANCY. DELETE ALLA USERS THAT APPEAR MORE THAN ONCE
  users = [...new Set([...users, ...followers, ...followings])];
  console.log("Filtered  --> ", users.length);

  // GET THE PROFILE OF ALL USERS
  let profilesPromises = users.map((name) => getUser(name));
  let profiles = await Promise.all(profilesPromises);

  if (topic === "users") {
    console.log("Profiles --> ", profiles.length);
    kafka.runKafka("users", 1, profiles);
  }

  // FIRST ARGUMENT TOPIC NAME, SECOND ONE ARRAY OF OBJJECTS
  if (topic === "repos") {
    // ask for the number of repos to fetch
    let n = getN();

    // GET ALL REPOS OF EVERY USERS AND TRANSFORM THE ARRAYS OF OBJECTS IN A SINGLE ARRAY OF OBJECTS
    let reposPromises = users.map((name) => getUserRepos(name));
    let repos = (await Promise.all(reposPromises)).flat(Infinity);
    console.log("Repos --> ", repos.length);
    console.log("Replication --> ", n);

    kafka.runKafka("repos", n, repos);
  }

  console.timeEnd();
};

init();
