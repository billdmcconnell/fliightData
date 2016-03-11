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

While the app is running:

```
data/
make download
make restore
```


### Flushing the database

```
cd app/
meteor reset
```
