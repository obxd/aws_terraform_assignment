## Terraform connecting aws gateway to aws lambda and aws lambda to aws sns to send email assignment 

*note* change the email address in variables.tf

*run*:  
```
git clone https://github.com/obxd/aws_terraform_assignment
cd aws_terraform_assignment
terraform init
terraform apply
```  

This will print the `[url]` to which we can send requests  

*requests example: *:    

```

curl --header "Content-Type: application/json" \
  --request POST \
  --data '[1,2,3,4,5]' \
  [url]
  
```

This will send you the sum of the numbers via email ( you need to accept subscription first) and in the response json.
