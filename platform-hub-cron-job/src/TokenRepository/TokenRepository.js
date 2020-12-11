const Pool = require('pg').Pool

const pool = new Pool({
  user: process.env.PHUB_DB_USERNAME,
  host: process.env.PHUB_DB_HOST,
  database: process.env.PHUB_DB_NAME,
  password: process.env.PHUB_DB_PASSWORD
});

class TokenRepository {
  getExpiringTokens(){
    return new Promise((resolve, reject) => {
      pool.query(`SELECT name, date_trunc('day', expire_token_at)
      FROM kubernetes_tokens
      WHERE date_trunc('day', expire_token_at) = current_date + interval '1 days'
      OR date_trunc('day', expire_token_at) = current_date + interval '3 days'
      OR date_trunc('day', expire_token_at) = current_date + interval '7 days';`, (error, results) => {
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
