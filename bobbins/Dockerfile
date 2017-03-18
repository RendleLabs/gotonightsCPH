FROM microsoft/dotnet:latest

EXPOSE 5000
CMD ["dotnet", "run", "--server.urls", "http://*:5000"]

COPY bobbins.csproj /app/
WORKDIR /app
RUN ["dotnet", "restore"]

COPY . /app
RUN ["dotnet", "restore"]
RUN ["dotnet", "build"]
