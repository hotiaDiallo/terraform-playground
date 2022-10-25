# Terraform & AWS EKS : Provision an EKS cluster

In [this previous project](https://github.com/hotiaDiallo/devops-java-maven-app/tree/eks-cluster-with-node-group) we create an EKS cluster using the Amazon management console and CloudFormation to create the VPC with all required configurations. 

Here we are going to use Terraform to do the same thing.

## Architecture 

![Image](/images/archi.png)

### 1 - Create a VPC 

we use an [existing VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)

Best practices :
- one private and one public subnet in each AZ
- set AZ's dynamically depending on the region : do not hardcoded
    - use data resources to query AZ : it will return the AZ of the region set on the provider block. 
- add tags : it's important, for example the Cloud Controller Mananger that comes from AWS, orchestrate connecting to the VPC, subnet, worker nodes... So he needs to know which resource in our account he should talk to. 

See the configuration for creating the VPC and Subnet : [vpc.tf]()

### 2 - Create an EKS cluster and associated resources

we use an [existing eks module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)

See the configuration for eks cluster with the minimum configuration : [eks-cluster.tf]()

### Outputs

- VCP and subnet 

![Image](/images/vpc.png)

![Image](/images/subnet.png)

- cluster 

![Image](/images/cluster.png)

![Image](/images/sg.png)

### 3 - Let's connect to the cluster and deploy nginx docker container using kubectl

![Image](/images/cluster-kubectl.png)

Prerequities:
- AWS CLI installed 
- kubectl installed 
- aws-iam-authenticator installed (Amazon EKS uses IAM to provide authentication to your Kubernetes cluster through the AWS IAM authenticator for Kubernetes. You can configure the stock kubectl client to work with Amazon EKS by installing the AWS IAM authenticator for Kubernetes and modifying your kubectl configuration file to use it for authentication)

Command: 
    aws eks update-kubeconfig --name myapp-eks-cluster --region eu-west-3

Deploy nginx 

