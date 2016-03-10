# FLIRT

Network analysis tool that enables users to examine flight networks to identify where infected travelers and contaminated goods are likely to travel too. Connectedness between airports using passenger, cargo, and network data is calculated.

### Installation

```
cd app/
make install
```

### Running

```
cd app/
make run
```

### Updating

```
cd app/
make update
```

### Populating the database

After doing `make run` run:

```
make data
cd ../tools/grits-net-consume/
virtualenv grits-net-consume-env
source grits-net-consume-env/bin/activate
pip install -r requirements.txt
MONGO_HOST=localhost:3101 python grits_consume.py -d meteor --type DiioAirport tests/data/MiExpressAllAirportCodes.tsv
MONGO_HOST=localhost:3101 python grits_consume.py -d meteor --type FlightGlobal tests/data/GlobalDirectsSample_20150728.csv
```

### Flushing the database

```
cd app/
meteor reset
```
