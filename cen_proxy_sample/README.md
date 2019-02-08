# MultiRegion Connection with CEN example
This is a sample code to create MultiRegion Connection using CEN.
This sample code creates following resource.

1. VPC in region-A
2. VPC in region-B
3. VSwitch in region-A
4. ECS in region-A
5. VPN Gateway(OpenVPN) in region-B
6. CEN instanse and connect region-A and region-B
7. publish routing to OpenVPN

## How to use

```
cp terraform.tfvars.sample terraform.tfvars
vim terraform.tfvars
```

and Deploy to AlibabaCloud

```
terraform apply -var-file="terraform.tfvars"
```
