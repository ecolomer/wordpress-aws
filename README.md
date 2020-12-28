
WordPress on AWS
================

Contents
--------

- [Overview](#overview)
- [Repository layout](#repository-layout)
- [Deploying the project](#deploying-the-project)

Overview
--------

The goal of this project is to experiment with [WordPress](https://wordpress.org/) and [Docker](https://www.docker.com/) on [AWS](https://aws.amazon.com/). It started up as a project for a customer in which we took different approaches to setup the product. Not all of them were finally used by the customer but I kept them in the repository to experiment with technology. This setup could be completely automated, of course. It is broken down into separate steps for learning purposes.

Stand-alone **Docker**, **ECS**, **Fargate**, **EFS**, as well as other supporting **AWS** services, are being used. All infrastructure resources are defined through **CloudFormation**. **Terraform** or **AWS CDK** could also fit the purpose and **Kubernetes** (stand-alone or managed) could offer additional advanced scenarios.

Repository layout
-----------------

This repository has three directories which contain all the required files.

- **cloudformation**: configuration files for supporting services
- **docker**: Dockerfile definitions and supporting configuration files
- **scripts**: project helper scripts

The initial approach (*master* branch) uses **ECS/Fargate** and **EFS**, among other supporting services. There's a specific branch for each of the remaining approaches. Several of these branches enhance the initial approach by adding an *admin* service. This means the original container definition becomes a *browsing* service without administration access. And the new *admin* container provides the *editing* service.

- **fargate/ecs/master**: includes *read-only* root filesystem, **CloudFront** distribution and other small enhancements
- **fargate/ecs/debug**: includes **SSH** container to allow **Fargate** environment debug
- **fargate/ecs/internal-lb**: includes *admin* service
- **ec2/docker/master**: replaces **ECS/Fargate** with stand-alone **Docker**, removes **EFS** and includes other small enhancements
- **ec2/docker/letsencrypt**: includes *admin* service using **letsencrypt**
- **ec2/docker/internal-lb**: includes *admin* service using an **AWS** internal load balancer
- **ec2/ecs/master**: replaces **ECS/Fargate** with **ECS running on EC2**, removes **EFS** and includes other small enhancements
- **ec2/ecs/letsencrypt**: includes *admin* service using **letsencrypt**
- **ec2/ecs/internal-lb**: includes *admin* service using an **AWS** internal load balancer

When using an **EC2** approach you'll find a *packer* directory, as well, which defines the **AMI** to be used for the **AutoScaling Group**.

Deploying the project
---------------------

The tip of each branch is a commit with **CloudFormation** JSON parameter files. This means you can deploy the stacks in each branch by using **AWS CLI** and easily provide specific parameters through those files.

On the other hand, many parameters read the values from **AWS SSM Parameter Store**. Some of these values are automatically provided and some must be supplied manually (usernames, passwords, certificates, etc.)

This deployment procedure is **not** a complete step-by-step sequence of actions. Depending on the branch you choose, you may need to add a slightly different step or skip an existing one.

All deployments start by defining database usernames and passwords.

First define the **RDS** database master username and password.

	$ aws ssm put-parameter --name /wordpress/database/masteruser --type String --value "admin"
	$ aws ssm put-parameter --name /wordpress/database/masterpassword --type SecureString --value "password"

While **CloudFormation** does support **SSM Parameter Store**, it still does not support **SecureString** parameter types. On the other hand, the *AWS::RDS::DBCluster* resource has a *MasterUserPassword* parameter which provides **RDS** database with a password. It would be ideal to supply the value of this parameter using **SSM** in a secure way. But, as I said, it is not supported in **CloudFormation** yet. So, we have to provide this value using plain text in the *database.json* file.

Next, define the **WordPress** database username and password.

	$ aws ssm put-parameter --name /wordpress/database/wpuser --type String --value "wordpress"
	$ aws ssm put-parameter --name /wordpress/database/wppassword --type SecureString --value "wordpress"

And then define the **WordPress** database name.

	$ aws ssm put-parameter --name /wordpress/database/wpdatabase --type String --value "wordpress"

We can now begin launching **CloudFormation** stacks. Let's start with the network.

	$ aws cloudformation create-stack --cli-input-json file://cloudformation/vpc.json --template-body file://cloudformation/vpc.yml

Continue with the database stack.

	$ aws cloudformation create-stack --cli-input-json file://cloudformation/database.json --template-body file://cloudformation/database.yml

For the next step you will need to create a TLS certificate using **ACM**. This certificate should be available in the same **AWS** region as the load balancer. I assume you know how to do this. Once you have the certificate *ARN*, initialize **SSM**.

	$ aws ssm put-parameter --name /wordpress/alb/certificate --type String --value <ARN>

Deploy **AWS** application load balancer(s).

	$ aws cloudformation create-stack --cli-input-json file://cloudformation/balancer.json --template-body file://cloudformation/balancer.yml

Create **ECR** repositories.

	$ aws cloudformation create-stack --cli-input-json file://cloudformation/registry.json --template-body file://cloudformation/registry.yml

And now, before deploying the remaining stacks, we must create the **Docker** images supporting our containers.

	$ ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
	$ REGION=$(aws configure get default.region)
	$ ECR_ENDPOINT="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
	$ aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_ENDPOINT

For each subdirectory inside *docker*, build and push the image to **ECR**. For example, for the *wordpress-service* container, use the following.

	$ cd docker/service
	$ docker build -t wordpress-service .
	$ docker tag wordpress-service "$ECR_ENDPOINT/wordpress-service"
	$ docker push "$ECR_ENDPOINT/wordpress-service"

Deploy **S3** buckets if needed.

	$ aws cloudformation create-stack --cli-input-json file://cloudformation/bucket.json --template-body file://cloudformation/bucket.yml

If using **EC2**, generate the base **AMI** using [Packer](https://www.packer.io/).

	$ cd packer
	$ packer build <ubuntu/amzn2>-setup.json
	$ IMAGEID=$(aws ec2 describe-images --owners $ACCOUNT --filters "Name=name,Values=wordpress*" --query "reverse(sort_by(Images, &CreationDate))[:1].ImageId" --output text)
	$ aws ssm put-parameter --name /wordpress/ec2/image-id --type String --value $IMAGEID

Initialize public domain names.

	$ aws ssm put-parameter --name /wordpress/primary-domain --type String --value "mydomain.net"
	$ aws ssm put-parameter --name /wordpress/domain-names --type StringList --value "mydomain.net,www.mydomain.net"

Create the **ECS/EC2** container stack.

	$ aws cloudformation create-stack --cli-input-json file://cloudformation/containers.json --template-body file://cloudformation/containers.yml

For the next step you will need to create a TLS certificate using **ACM**. This certificate should be available in the *us-east-1* region. This is an **AWS** requirement to be able to use the certificate with **CloudFront**. I assume you know how to do this. Once you have the certificate *ARN*, initialize **SSM**.

	$ aws ssm put-parameter --name /wordpress/cdn/certificate --type String --value <ARN>

Finally, create the **CloudFront** distribution pointing to your current infrastructure.

	$ aws cloudformation create-stack --cli-input-json file://cloudformation/cdn.json --template-body file://cloudformation/cdn.yml

You can now point your DNS entries accordingly. Either point to the **CloudFront** distribution endpoint or the internet-facing application load balancer endpoint.

This deployment process will leave a new (blank) **WordPress** setup. If you want to migrate your previous setup, you  need to restore database and content files from backup.

The *mysql-setup.sh* script in the *scripts* directory can help you restore the database easily and setup the required permissions.

