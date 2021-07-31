#!/bin/bash
#Author: Rameshkumar
#Purpose; Install the Docker

PS3='Please enter your choice:'
options=("Install Docker and Run the ElasticSearch" "Uninstall the Docker and ElasticSearch" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install Docker and Run the ElasticSearch")
            echo "We are installing the Docker, Start running the ElasticSearch and Checking the health of ElasticSearch"
                        #Set up the Docker

                        sudo apt-get -y update

                        sudo apt-get -y install apt-transport-https ca-certificates curl gnupg lsb-release

                        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

                        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                        sudo apt-get -y update

                        sudo apt-get -y install docker-ce docker-ce-cli containerd.io

                        sleep 10
                        
                        #Setup the Elastic Search

                        sudo docker pull docker.elastic.co/elasticsearch/elasticsearch:7.13.4

                        sudo docker run -d --name myes -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.13.4
                        
                        sleep 20
                        echo "============================"
                        echo "ElasticSearch Health"
                        echo "============================"
                        #curl http://localhost:9200/_cat/health
                        curl -X GET "localhost:9200/_cat/health?v=true&ts=false&pretty"
                        echo "============================"
                        echo "if you see the connection reset by peer error, Please run below command check the ElasticSearch Health"
                        echo "curl -X GET localhost:9200/_cat/health?v=true"
                        break
            ;;
        "Uninstall the Docker and ElasticSearch")
            echo "Uninstall the Docker and ElasticSearch from Server"
                        #Uninstall

                        sudo docker stop myes

                        sudo apt-get -y purge docker-ce docker-ce-cli containerd.io

                        sudo rm -rf /var/lib/docker

                        sudo rm -rf /var/lib/containerd

                        break
            ;;
                "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
