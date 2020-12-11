require('dotenv').config();
const _ = require('lodash');
const csv = require("papaparse");


const AWS = require('aws-sdk');

class S3Client {

  constructor() {
    AWS.config.update({region: 'eu-west-2', accessKeyId: process.env.FILESTORE_S3_ACCESS_KEY_ID,
    secretAccessKey: process.env.FILESTORE_S3_SECRET_ACCESS_KEY});
    this.s3 = new AWS.S3();
  }


  getAndUpdateFile(uid, s3_object_key){
    var params = {
      Bucket : process.env.FILESTORE_S3_BUCKET_NAME,
      Key: s3_object_key
    };

    // Call S3 to obtain a list of the objects in the bucket
    this.s3.getObject(params).promise()
    .then((data) => {
      const csvWithHeaders = "token,email,uid\n" + data.Body.toString().trim();
      const tokens = csv.parse(csvWithHeaders, {header: true}).data
      
       _.remove(tokens, function(tokenData) {
        return tokenData.uid === uid;
    })
    
    console.log('New tokens array', tokens);
    
    const unparsedTokens = csv.unparse(tokens, {header: false})
    
    var params = {
       Bucket: process.env.FILESTORE_S3_BUCKET_NAME,
       Key: s3_object_key,
       Body: unparsedTokens,
       ACL: "private",
       ServerSideEncryption: 'aws:kms'
     };
     
     this.s3.putObject(params).promise()
     .then((data) => {
       console.log(data);
     })
    })
}

}
module.exports =  S3Client;
