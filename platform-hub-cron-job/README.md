# Platform Hub – Expiring Tokens Email Notification Job

## Dev

### Prerequisites

#### Node v10.16.3

To set up:
- `npm install`


#### Expiring Tokens
To retrieve expiring tokens locally, you'll need to create/copy a `local/.env.local` file for the database related config. This file must export the following environment variables:
- PHUB_DB_NAME=phub_development
- PHUB_DB_USERNAME=phub
- PHUB_DB_PASSWORD=phub_password


#### Email delivery

To set up local email delivery, ensure you have the following env variables set (either in `.env.local` or passed through your environment):

Your AWS IAM credentials which you can find under Amazon ECR on the ACP Hub’s Connected Identities page:
- `SES_ACCESS_KEY_ID`
- `SES_SECRET_ACCESS_KEY`

The address from which emails will be sent:
- `SES_MAIL_FROM_ADDRESS`

**As usual, be careful when sending out emails from your local development environment!**

## General workflow

Note: make sure you run scripts from the root of platform-hub-cron- job.

- Send an email for expiring tokens
  - `node index.js`
