all: download restore

download:
	echo "This may take a while..."
	aws s3 cp --recursive s3://flight-network-heat-map/legs/grits-net-meteor/ dump/

restore:
	echo "Upserting data dumps..."
	mongoimport -h localhost:3101 --db meteor --collection airports --type json --file ../app/packages/grits-net-meteor/example/tests/mongo/airports.json
	mongoimport -h localhost:3101 --db meteor --collection flights --type json --file ../app/packages/grits-net-meteor/example/tests/mongo/flights.json
	mongoimport -h localhost:3101 --db meteor --collection legs --type json --file ../app/packages/grits-net-meteor/example/tests/mongo/legs.json
	mongoimport -h localhost:3101 --db meteor --collection halunka:i18n --type json --file ../app/packages/grits-net-meteor/example/tests/mongo/i18n.json
	mongorestore -h localhost:3101 -d meteor -c legs dump/legs.bson
