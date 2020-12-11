const Pool = require('pg').Pool

const pool = new Pool({
  user: process.env.PHUB_DB_USERNAME,
  host: process.env.PHUB_DB_HOST,
  database: process.env.PHUB_DB_NAME,
  password: process.env.PHUB_DB_PASSWORD
});

class TokenRepository {
  getNonExpiringTokens(){
    return new Promise((resolve, reject) => {
      pool.query(`SELECT users.name, kubernetes_tokens.kind, kubernetes_tokens.uid
      FROM users
      LEFT JOIN project_memberships ON users.id=project_memberships.user_id
      LEFT JOIN kubernetes_tokens ON project_memberships.project_id=kubernetes_tokens.project_id
      WHERE(CASE
        WHEN kubernetes_tokens.kind ='user' THEN kubernetes_tokens.expire_token_at IS NULL
        AND
        project_memberships.project_id=kubernetes_tokens.project_id
        AND
        users.email=kubernetes_tokens.name
        ELSE
        kubernetes_tokens.expire_token_at IS NULL
        AND
        project_memberships.project_id=kubernetes_tokens.project_id
        AND
        project_memberships.role='admin'
        END);`, (error, results) => {
          if (error) {
            return reject(error)
          }
          return resolve(results.rows)
        })
      })
      .catch(console.error)
    }
  }

  module.exports =  TokenRepository;
