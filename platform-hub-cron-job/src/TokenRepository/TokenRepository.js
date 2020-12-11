const Pool = require('pg').Pool

const pool = new Pool({
  user: process.env.PHUB_DB_USERNAME,
  host: process.env.PHUB_DB_HOST,
  database: process.env.PHUB_DB_NAME,
  password: process.env.PHUB_DB_PASSWORD
});

class TokenRepository {
  getExpiringTokens(){
  console.log('getting expiring tokens');
  return new Promise((resolve, reject) => {
    pool.query(`SELECT users.name, projects.name AS project_name, kubernetes_clusters.name AS cluster_name, kubernetes_tokens.kind, kubernetes_tokens.uid, date_trunc('day', kubernetes_tokens.expire_token_at)
    FROM users
    LEFT JOIN project_memberships ON users.id=project_memberships.user_id
    LEFT JOIN kubernetes_tokens ON project_memberships.project_id=kubernetes_tokens.project_id
    LEFT JOIN kubernetes_clusters ON kubernetes_clusters.id=kubernetes_tokens.cluster_id
    LEFT JOIN projects ON projects.id=kubernetes_tokens.project_id
    WHERE(CASE
      WHEN kubernetes_tokens.kind ='user' THEN (date_trunc('day', kubernetes_tokens.expire_token_at) = current_date + interval '1 days'
      OR date_trunc('day', kubernetes_tokens.expire_token_at) = current_date + interval '3 days'
      OR date_trunc('day', kubernetes_tokens.expire_token_at) = current_date + interval '7 days')
      AND
      project_memberships.project_id=kubernetes_tokens.project_id
      AND
      users.email=kubernetes_tokens.name
      ELSE
      (date_trunc('day', kubernetes_tokens.expire_token_at) = current_date + interval '1 days'
      OR date_trunc('day', kubernetes_tokens.expire_token_at) = current_date + interval '3 days'
      OR date_trunc('day', kubernetes_tokens.expire_token_at) = current_date + interval '7 days')
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
  
  getExpiredTokens(){
      console.log('getting expired tokens');
    return new Promise((resolve, reject) => {
      pool.query(`SELECT users.name, projects.name AS project_name, kubernetes_clusters.name AS cluster_name,kubernetes_tokens.kind, kubernetes_tokens.uid, kubernetes_clusters.s3_bucket_name, kubernetes_clusters.s3_object_key, date_trunc('day', kubernetes_tokens.expire_token_at)
      FROM users
      LEFT JOIN project_memberships ON users.id=project_memberships.user_id
      LEFT JOIN kubernetes_tokens ON project_memberships.project_id=kubernetes_tokens.project_id
      LEFT JOIN kubernetes_clusters ON kubernetes_clusters.id=kubernetes_tokens.cluster_id
      LEFT JOIN projects ON projects.id=kubernetes_tokens.project_id
      WHERE(CASE
        WHEN kubernetes_tokens.kind ='user' THEN (expire_token_at < NOW())
        AND
        project_memberships.project_id=kubernetes_tokens.project_id
        AND
        users.email=kubernetes_tokens.name
        ELSE
        (expire_token_at < NOW())
        AND
        project_memberships.project_id=kubernetes_tokens.project_id
        AND
        project_memberships.role='admin'
        END)`, (error, results) => {
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
