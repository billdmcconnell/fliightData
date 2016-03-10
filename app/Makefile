run:
	meteor -p 3100 --settings settings.json

install:
	git submodule init

update:
	git submodule update

data:
	mongoimport -h localhost:3101 --db meteor --collection airports --type json --file packages/grits-net-meteor/example/tests/mongo/airports.json
	mongoimport -h localhost:3101 --db meteor --collection flights --type json --file packages/grits-net-meteor/example/tests/mongo/flights.json
	mongoimport -h localhost:3101 --db meteor --collection legs --type json --file packages/grits-net-meteor/example/tests/mongo/legs.json
	mongoimport -h localhost:3101 --db meteor --collection halunka:i18n --type json --file packages/grits-net-meteor/example/tests/mongo/i18n.json
