const axios = require("axios");

class UserEmail{
  getEmail(name){
    return axios.get(`https://${process.env.X_PROXY_NAME}/rest/api/2/groupuserpicker?query=${name}`, {
      auth: {
        username: `${process.env.JIRA_USERNAME}`,
        password: `${process.env.JIRA_PASSWORD}`
      },
      headers: {
        'Content-Type': 'application/json'
      }
    })
    .then(response => {
      console.log(
        `Response: ${response.status} ${response.statusText}`
      );
      return response.data.users.users;
    })
    .catch(err => console.error(err));
  }
  
}

module.exports = UserEmail;
