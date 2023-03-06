const git = require("./services/useGithub");
const kafka = require("./services/useKafka");

const userName = "ArmandoXheka";
// Michele-x98, flaviopopoff,ArmandoXheka

let userPropertiesToGet = ["name", "login", "bio", "avatar_url"];
let reposPropertiesToGet = ["name", "description", "url", "created_at", "stars", "forks", "language", "open_issues", "topics", "license"];
let followerPropertiesToGet = ["login", "id", "type"];
let followingPropertiesToGet = ["login", "id", "type"];

// FUNCTION THAT SELECTS ONLY THE FIELD REQUIRED
// IF VALUE ISN'T INSIDE THE OBJECT IT PASS AWAY WITH NO ERRORS
function pickOnlySelectedValue(obj, ...props) {
	return props.reduce(function (result, prop) {
		if (obj[prop]) result[prop] = obj[prop];
		return result;
	}, {});
}

// GETUSER AND SELECT FIELDS REQUESTED
const getUser = async (username) => {
	let res = await git.fetchGetGithubUser(username);
	return pickOnlySelectedValue(res, ...userPropertiesToGet);
};

const getUserRepos = async (username) => {
	let res = await git.fetchGetGithubUserRepos(username);
	return res.map((el) => pickOnlySelectedValue(el, ...reposPropertiesToGet));
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
const init = async (username) => {
	const promises = [getUser(username), getUserRepos(username), getFollowers(username), getFollowings(username)];
	let [user, repos, followers, followings] = await Promise.all(promises);
	repos.forEach((element) => (element.login = user.login));

	let topic = "pippo";
	kafka.runKafka(topic, user, repos, followers, followings);
};

init(userName);
