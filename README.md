connecting to the server via ssh(windows, havent tested it on linux)

ssh -i (path_to_PEM_file) machine_username@machine_ip

ex ssh -i C:\Users\username\Documents\aws_keys/key.pem ubuntu@44.39.157.290 :rage3:                                     

BTW - allways commit the files created after terraform init, plan and apply. Those will track the state of the project and tracks the connections between the resources in the code and in aws(their connections) so we are able to manage the resources from anywhere as long as we have the git project updated with the tfstate files
