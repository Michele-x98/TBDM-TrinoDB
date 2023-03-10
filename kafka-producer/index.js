const git = require("./services/useGithub");
const kafka = require("./services/useKafka");
const { Kafka } = require("kafkajs");

const mainUsers = ["ArmandoXheka", "Michele-x98", "flaviopopoff"];

let userPropertiesToGet = ["name", "login", "avatar_url", "type"];
let reposPropertiesToGet = ["name", "description", "url", "created_at", "stars", "forks", "language", "open_issues", "topics", "license"];
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
	return await git.fetchGetGithubUserRepos(username);
};

const getFollowers = async (username) => {
	let res = await git.fetchGetGithubUserFollowers(username);
	return res.map((el) => pickOnlySelectedValue(el, ...followerPropertiesToGet));
};

const getFollowings = async (username) => {
	let res = await git.fetchGetGithubUserFollowings(username);
	return res.map((el) => pickOnlySelectedValue(el, ...followingPropertiesToGet));
};

// INIT
const init = async () => {
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
	// console.log("Profiles  --> ", profiles.length);

	// GET ALL REPOS OF EVERY USERS AND TRANSFORM THE ARRAYS OF OBJECTS IN A SINGLE ARRAY OF OBJECTS
	let reposPromises = users.map((name) => getUserRepos(name));
	let repos = (await Promise.all(reposPromises)).flat(Infinity);
	console.log("Repos --> ", repos.length);

	console.timeEnd();

	// FIRST ARGUMENT TOPIC NAME, SECOND ONE ARRAY OF OBJJECTS
	// kafka.runKafka("users", profiles);
	// kafka.runKafka("repos", repos);
};

init();
