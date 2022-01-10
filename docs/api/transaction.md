# Transaction
## List udt transfer txs
```
GET /txs
```

### Parameters
|Name|Type|In|Description|
|---|---|---|---|
|udt_address|string|query|udt eth address|
|page|integer|query|default is 1|

### Code samples

```console
curl https://api.godwoken.staging.nervina.cn/api/txs?udt_address=0xc5e133e6b01b2c335055576c51a53647b1b9b624
```

### Response

```
Status: 200 OK
```

```json
{
page: "1",
total_count: "8",
txs: [
{
block_hash: "0x88d0b2c105a7a17ab958f421ba71acc5aee475dfd11d0d33ff20b2544d7b5ab1",
block_number: 231666,
fee: "0",
from: "0xf7f6e5f6f0c905cbd385060a8b05d9d5ade91b07",
gas_limit: 12500000,
gas_price: "0",
gas_used: 44483,
hash: "0xc30d26c095b8cc27643ccf2ca8ba5d5c7fd5c11625510ae8a5ea0d104121e797",
method: "Transfer",
nonce: 66,
receive_eth_address: "0x72f411d54643619fb855983383d88a0c7661c3ac",
status: "committed",
timestamp: 1641414025,
to: "0xc5e133e6b01b2c335055576c51a53647b1b9b624",
to_alias: "YOKAI",
transfer_value: "1",
type: "polyjuice",
udt_id: 3014,
value: "0"
}
]
}
```

## List contract's txs of user eth address

```
GET /txs
```

### Parameters
|Name|Type|In|Description|
|---|---|---|---|
|eth_address|string|query|user account eth address|
|contract_address|string|query|contract adddress|
|page|integer|query|default is 1|

### Code samples

```console
curl https://api.godwoken.staging.nervina.cn/api/txs?eth_address=0xbFbE23681D99A158f632e64A31288946770c7A9e&contract_address=0xc5e133e6b01b2c335055576c51a53647b1b9b624&page=1
```

### Response

```
Status: 200 OK
```

```json
{
  page: "1",
  total_count: "24",
  txs: [
    {
    block_hash: "0x8e78f43b38d515eb0dd0b974542d827ebe2bb867ef9b8bcd796a991033d179cd",
    block_number: 199094,
    fee: "0",
    from: "0xbfbe23681d99a158f632e64a31288946770c7a9e",
    gas_limit: 12500000,
    gas_price: "0",
    gas_used: 44483,
    hash: "0x88325e79de93bd54152b79b389060bf68a9357854da100fa82247cd263181eda",
    method: "Transfer",
    nonce: 9,
    receive_eth_address: null,
    status: "finalized",
    timestamp: 1639102099,
    to: "0xc5e133e6b01b2c335055576c51a53647b1b9b624",
    to_alias: "YOKAI",
    transfer_value: "133",
    type: "polyjuice",
    udt_id: 3014,
    value: "0"
    },
  ]
}
```

## List all txs of eth address

```
GET /txs
```

### Parameters
|Name|Type|In|Description|
|---|---|---|---|
|eth_address|string|query|any account type eth address|
|page|integer|query|default is 1|

### Code samples

```console
curl https://api.godwoken.staging.nervina.cn/api/txs?eth_address=0xbFbE23681D99A158f632e64A31288946770c7A9e&page=1
```

### Response

```
Status: 200 OK
```

```json
{
  page: "1",
  total_count: "24",
  txs: [
    {
    block_hash: "0x8e78f43b38d515eb0dd0b974542d827ebe2bb867ef9b8bcd796a991033d179cd",
    block_number: 199094,
    fee: "0",
    from: "0xbfbe23681d99a158f632e64a31288946770c7a9e",
    gas_limit: 12500000,
    gas_price: "0",
    gas_used: 44483,
    hash: "0x88325e79de93bd54152b79b389060bf68a9357854da100fa82247cd263181eda",
    method: "Transfer",
    nonce: 9,
    receive_eth_address: null,
    status: "finalized",
    timestamp: 1639102099,
    to: "0xc5e133e6b01b2c335055576c51a53647b1b9b624",
    to_alias: "YOKAI",
    transfer_value: "133",
    type: "polyjuice",
    udt_id: 3014,
    value: "0"
    },
  ]
}
```

## List udt transfer type txs

```
GET /txs
```

### Parameters
|Name|Type|In|Description|
|---|---|---|---|
|udt_address|string|query|udt account type eth address|
|page|integer|query|default is 1|

### Code samples

```console
curl https://api.godwoken.staging.nervina.cn/api/txs?udt_address=0xc5e133e6b01b2c335055576c51a53647b1b9b624
```

### Response

```
Status: 200 OK
```

```json
{
  page: "1",
  total_count: "24",
  txs: [
{
block_hash: "0x88d0b2c105a7a17ab958f421ba71acc5aee475dfd11d0d33ff20b2544d7b5ab1",
block_number: 231666,
fee: "0",
from: "0xf7f6e5f6f0c905cbd385060a8b05d9d5ade91b07",
gas_limit: 12500000,
gas_price: "0",
gas_used: 44483,
hash: "0xc30d26c095b8cc27643ccf2ca8ba5d5c7fd5c11625510ae8a5ea0d104121e797",
method: "Transfer",
nonce: 66,
receive_eth_address: "0x72f411d54643619fb855983383d88a0c7661c3ac",
status: "committed",
timestamp: 1641414025,
to: "0xc5e133e6b01b2c335055576c51a53647b1b9b624",
to_alias: "YOKAI",
transfer_value: "1",
type: "polyjuice",
udt_id: 3014,
value: "0"
},
  ]
}
```

## List txs of block

```
GET /txs
```

### Parameters
|Name|Type|In|Description|
|---|---|---|---|
|block_hash|string|query|block hash|
|page|integer|query|default is 1|

### Code samples

```console
https://api.godwoken.staging.nervina.cn/api/txs?block_hash=0x88d0b2c105a7a17ab958f421ba71acc5aee475dfd11d0d33ff20b2544d7b5ab1
```

### Response

```
Status: 200 OK
```

```json
{
  page: "1",
  total_count: "24",
  txs: [
{
block_hash: "0x88d0b2c105a7a17ab958f421ba71acc5aee475dfd11d0d33ff20b2544d7b5ab1",
block_number: 231666,
fee: "0",
from: "0xf7f6e5f6f0c905cbd385060a8b05d9d5ade91b07",
gas_limit: 12500000,
gas_price: "0",
gas_used: 44409,
hash: "0x348fa4c9e166caf12abbb74cecc45abcddddf9d11d0fee56969ec3d39ed897d9",
method: null,
nonce: 62,
receive_eth_address: null,
status: "committed",
timestamp: 1641414025,
to: "0x1a0e713d9c91e23c891bdd9e59db2f1a307417fb",
to_alias: "0x1a0e713d9c91e23c891bdd9e59db2f1a307417fb",
transfer_value: "",
type: "polyjuice",
udt_id: null,
value: "0"
},
  ]
}
```

## show polyjuice tx by hash

```
GET /txs
```

### Parameters
|Name|Type|In|Description|
|---|---|---|---|
|hash|string|path|polyjuice type tx hash|

### Code samples

```console
curl https://api.godwoken.staging.nervina.cn/api/txs/ 0xc30d26c095b8cc27643ccf2ca8ba5d5c7fd5c11625510ae8a5ea0d104121e797
```

### Response

```
Status: 200 OK
```

```json
{
  block_hash: "0x88d0b2c105a7a17ab958f421ba71acc5aee475dfd11d0d33ff20b2544d7b5ab1",
  block_number: 231666,
  contract_abi: [],
  fee: "0",
  from: "0xf7f6e5f6f0c905cbd385060a8b05d9d5ade91b07",
  gas_limit: 12500000,
  gas_price: "0",
  gas_used: 44483,
  hash: "0xc30d26c095b8cc27643ccf2ca8ba5d5c7fd5c11625510ae8a5ea0d104121e797",
  nonce: 66,
  receive_eth_address: "0x72f411d54643619fb855983383d88a0c7661c3ac",
  status: "committed",
  timestamp: 1641414025,
  to: "0xc5e133e6b01b2c335055576c51a53647b1b9b624",
  to_alias: "YOKAI",
  transfer_value: "1",
  type: "polyjuice",
  udt_id: 3014,
  value: "0"
}
```

## show polyjuice creator tx by hash

```
GET /txs
```

### Parameters
|Name|Type|In|Description|
|---|---|---|---|
|hash|string|path|polyjuice creator type tx hash|

### Code samples

```console
curl https://api.godwoken.staging.nervina.cn/api/txs/
0x548abac7dd2ca0c9df349a8523e7964887dd3007699ef94665e03caeba9385be
```

### Response

```
Status: 200 OK
```

```json
{
  block_hash: "0xc0fa3dd4938783fce7bb3edd218b548fd2b158011f3a89791c4aaafcd525e1b1",
  block_number: 4,
  code_hash: "0xbeb77e49c6506182ec0c02546aee9908aafc1561ec13beb488d14184c6cd1b79",
  fee: "",
  fee_amount: "0",
  fee_udt: "Nervos Token",
  from: "0x8069d75814b6886ef39a5b3b0e84c3601b033480",
  gas_limit: null,
  gas_price: "",
  gas_used: null,
  hash: "0x548abac7dd2ca0c9df349a8523e7964887dd3007699ef94665e03caeba9385be",
  hash_type: "type",
  nonce: 0,
  receive_eth_address: null,
  script_args: "4cc2e6526204ae6a2e8fcf12f7ad472f41a1606d5b9624beebd215d780809f6a01000000",
  status: "finalized",
  timestamp: 1627705974,
  to: "0x8e77726fdbe272e32848212295435f4eecd966b7",
  to_alias: "0x8e77726fdbe272e32848212295435f4eecd966b7",
  transfer_value: "",
  type: "polyjuice_creator",
  udt_id: null,
  value: ""
}

```
