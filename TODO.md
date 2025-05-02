### Delete graphs from Influx on device or port delete;

### create install.pl 



### &#x2611; use the input in main form for quicksearch ports

<details>

eg: &#9746; ~~select from ports where name like %name%;~~

&#9746; ~~^!might not work(SQL injection),~~

&#9745; workaround: select all ports and filther by name;

&#9745; then use predefined dashboard func to select by port_ids from inluxdb and show graphs

</details>

### &#9745; Curl and js fetch queries are the same no need to write them twice

### &#9745; finish curl method

### &#9745; delete port from dash has no confirm

### &#9745; When threshold limit reached, collector will rise alert on every run

<details>

insert alerts file in tmp tbl;

check for port_id,alert_type_id,active in alerts tbl if found do nothing, else insert as new active

disable active?

after insert tmp: select from alerts where active check if exists in tmp if not disable;

</details>

## 