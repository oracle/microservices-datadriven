dotnet run

curl -k https://localhost:5001/inventory

docker build -t inventory-dotnet .
    "applicationUrl": "https://localhost:5001;http://localhost:5000",
    
docker run -it --rm -p 3000:80 --name inventory-dotnetcontainer inventory-dotnet


docker images
REPOSITORY                                                                                    TAG                                                     IMAGE ID       CREATED         SIZE
inventory-dotnet                                                                              latest                                                  a2606792fe72   2 minutes ago   215MB

docker ps
CONTAINER ID   IMAGE              COMMAND                  CREATED          STATUS          PORTS                  NAMES
68bfc99b0fd7   inventory-dotnet   "dotnet inventory-do…"   28 seconds ago   Up 27 seconds   0.0.0.0:3000->80/tcp   inventory-dotnetcontainer

