# FLIRT data
The most crucial part of the app: flight data.

### Requirements
 - `awscli`

### Instructions
Simply type and run `make download` to pull the flight data from EHA's AWS S3 bucket.

After the data has been downloaded, while running the meteor application on port
3100 (`cd app/ && make run`), run `make restore` to import the downloaded BSON file
into the database instance accessible on port 3101.

The final step is to restart your application via `make run`.
