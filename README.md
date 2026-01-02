# Prerequisites
* Ensure Docker is installed and running.
* Clone this repository.

# First Setup

Open a terminal inside the `tesserae` folder and run:
```sh
docker compose up -d
```
Then open the container's shell
```sh
docker compose exec -u www-data web bash
```
Run the initialization scripts in order (this may take some time):
```sh
perl scripts/configure.pl
perl scripts/install.pl
perl scripts/init.pl
``` 
When finished, type `exit` to close the shell.
Open your browser and visit: http://localhost:8000/html

# Daily Usage
To start the application after a restart, simply ensure Docker is running and execute:
```sh
docker compose up -d
``` 
Then you can open your browser and visit http://localhost:8000/html

