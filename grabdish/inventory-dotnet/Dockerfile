FROM mcr.microsoft.com/dotnet/sdk:5.0.300-alpine3.13-amd64 AS build
#FROM mcr.microsoft.com/dotnet/sdk:5.0.102-ca-patch-buster-slim-amd64 AS build
# FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
# FROM mcr.microsoft.com/dotnet/sdk:5.0-focal AS build-env

WORKDIR /src
COPY inventory-dotnet.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:5.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "inventory-dotnet.dll"]

#FROM mcr.microsoft.com/dotnet/aspnet:5.0
#WORKDIR /app
#COPY /app /app
#ENTRYPOINT ["dotnet", "inventory-dotnet.dll"]
