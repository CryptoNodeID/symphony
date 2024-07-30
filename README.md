### Prerequisite :
#### Ensure 'git' already installed
    apt-get update -y && apt-get install git -y
### Steps
#### Clone this repository :
    git clone https://github.com/CryptoNodeID/symphony.git
#### run setup command : 
    cd symphony && chmod ug+x *.sh && ./setup.sh
#### follow the instruction and then run below command to start the node :
    ./start_symphonyd.sh && ./check_log.sh
### Available helper tools :
    ./start_symphonyd.sh
    ./stop_symphonyd.sh
    ./check_log.sh
    
    ./create_validator.sh
    ./unjail_validator.sh
    ./check_validator.sh

    ./list_keys.sh
    ./check_balance.sh
    ./get_address.sh
