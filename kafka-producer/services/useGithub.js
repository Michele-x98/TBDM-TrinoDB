const fetch = (...args) =>
  import("node-fetch").then(({ default: fetch }) => fetch(...args));
// ACCESS TOKEN
let headers = {
  headers: {
    authorization: "token ${YOUR_SECRET_TOKEN}",
  },
};

let baseUrl = "https://api.github.com/users/";

const fetchGetGithubUser = async (user) => {
  return fetch(`${baseUrl}${user}`, headers).then((response) => {
    return response
      .json()
      .then((data) => data)
      .catch((err) => console.log(err));
  });
};

const fetchGetGithubUserRepos = async (user) => {
  return fetch(`${baseUrl}${user}/repos`, headers).then((response) => {
    return response
      .json()
      .then((data) => data)
      .catch((err) => console.log(err));
  });
};

const fetchGetGithubUserFollowers = async (user) => {
  return fetch(`${baseUrl}${user}/followers`, headers).then((response) => {
    return response
      .json()
      .then((data) => data)
      .catch((err) => console.log(err));
  });
};

const fetchGetGithubUserFollowings = async (user) => {
  return fetch(`${baseUrl}${user}/following`, headers).then((response) => {
    return response
      .json()
      .then((data) => data)
      .catch((err) => console.log(err));
  });
};

module.exports = {
  fetchGetGithubUser,
  fetchGetGithubUserRepos,
  fetchGetGithubUserFollowers,
  fetchGetGithubUserFollowings,
};
