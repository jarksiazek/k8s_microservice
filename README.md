# ks8_microservice
### Steps completed
1. Basic infrastructure - created
   * vpc 
   * public subnet
     * igw
     * route table -> 0.0.0.0
   * private subnet
   * eks cluster
     * cluster role
     * node-group-role
       * "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
       * "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
       * "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
     * node group
       * 1 spot instance t3.small
2. K8s service
   * deployment
   * external-service (load balancer)
   * 
3. 