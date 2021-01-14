# Getting Started

## Docker

To get started with the docker, run the following commands (after cloning repo).

```sh
docker-compose up
```

### Connect to running container's shell.

```sh
docker exec -it tesserae_web_1 bash
```

### Install Term:UI

#### Launch pearl shell

```sh
perl -MCPAN -e shell
```

#### Install Term:UI

```sh
cpan[2]> install Term::UI
```

### Set $url_base (line 159)

In an editor (outside of container shell is fine).

```pl
my $url_base = 'http://localhost:8000';
```

### Run configure.pl

```sh
perl scripts/configure.pl
```

### Run install.pl

```sh
perl scripts/install.pl
```

### Browser

On your browser, visit localhost:8000/html to view the site.