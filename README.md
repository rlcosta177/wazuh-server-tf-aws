connecting to the server via ssh(windows, havent tested it on linux)

ssh -i (path_to_PEM_file) machine_username@machine_ip

ex ssh -i C:\Users\username\Documents\aws_keys/key.pem ubuntu@44.39.157.290 :rage3:                                     

BTW - allways commit the files created after terraform init, plan and apply. Those will track the state of the project and tracks the connections between the resources in the code and in aws(their connections) so we are able to manage the resources from anywhere as long as we have the git project updated with the tfstate files

/////////////////////////   COMMANDS TO REMEMBER:

ssh-keygen <- create the .ssh folder(probably not the best way to do it but w/e, ill look into it later if needed)

I can add the public key of any key-pair(could be the one generated with ssh-keygen) and the owner of the key will be able to connect to the machine if they use their private key(example in line 5, can change the path to .ssh/'private_key')

   ~ .ssh/authorized_keys <- path to the authorized_keys file
    
https://stackoverflow.com/questions/20840012/ssh-remote-host-identification-has-changed <- remove a known host from the 'known_hosts' file 

who -a <- check current active ssh connections and probably other stuff
