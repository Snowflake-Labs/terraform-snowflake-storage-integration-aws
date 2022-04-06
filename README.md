# _Snowflake Storage Integration Terraform Module_


This Storage Integration terraform module creates the base infrastructure to build storage only pipelines that load data from S3 to Snowflake. The resources created are:

Snowflake Storage Integration
1. S3 Bucket
2. S3 Bucket Event
3. AWS SNS topic
4. AWS IAM Role with perms required to access the bucket, and publish/subscribe to SNS topic
5. Trust relationship between the Snowflake Storage integration and AWS IAM Role

![image](https://user-images.githubusercontent.com/72515998/152404729-2c08806f-c474-41f0-bedb-0afcaddb04e6.png)
