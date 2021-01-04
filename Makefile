build-base:
	docker-compose build --build-arg USER_ID=$$(id -u) --build-arg GROUP_ID=$$(id -g) base

# Just for poking around...
run-base:
	docker-compose run --rm base
