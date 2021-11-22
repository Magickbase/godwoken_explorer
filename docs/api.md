# API Doc

## API Domain

- Aggron network: https://api.staging.godwoken.nervina.cn
- Lina nertwork: https://api.godwoken.nervina.cn

## API List
- GET /api/accounts/{account_id | short_script_hash | eth_address | layer1_script_hash}

> 查找账户

|params|type|description|eg.|
|----|----|----|---|
|account_id|integer|账户id| 2|
|short_script_hash|string|短地址| 0x633b14f58a1343aeb43e9c68c8afb4c866ebb649|
|eth_address|sring|以太坊地址| 0x55824f0ed489feaaabd640459373dfb79c187dd2|
|layer1_script_hash|string|ckb链上的script hash| 0xe6c7befcbf4697f1a7f8f04ffb8de71f5304826af7bfce3e4d396483e935820a|

- GET api/txs/{tx_hash}
> 查找交易

|params|type|description|eg.|
|----|----|----|---|
|tx_hash|string|交易哈希| 0x0a79180e50ce745f567ab38a0dc957abace0a8ee8265ffd4ad2bfbb33f9ad09d|

- GET api/blocks/{block_id | block_hash}

> 查找块

|params|type|description|eg.|
|------|----|----|---|
|block_hash|string|交易哈希| 0x0a79180e50ce745f567ab38a0dc957abace0a8ee8265ffd4ad2bfbb33f9ad09d|
|block_id| integer|块高| 131|

- GET api/home
> 首页数据

- GET api/txs?account_id={account_id}&page={page}
> 查找某个账户下的交易

|params|type|description|eg.|
|----|----|----|---|
|account_id|integer|账户id| 2|

- GET api/search?keyword={layer1_lock_script | block_hash | tx_hash | account_id | short_script_hash | eth_address | layer1_script_hash | account_id}
> 聚合搜索

|params|type|description|eg.|
|----|----|----|---|
|layer1_lock_script|string| ckb链的lock script, code_hash + hash_type +args 用"_"拼接|0x0000000000000000000000000000000000000000000000000000000000000001_data_0x06820f679f7c9c6e399dcb25ab88a5babaf7d5db |
|block_hash|string|交易哈希| 0x0a79180e50ce745f567ab38a0dc957abace0a8ee8265ffd4ad2bfbb33f9ad09d|
|tx_hash|string|交易哈希| 0x0a79180e50ce745f567ab38a0dc957abace0a8ee8265ffd4ad2bfbb33f9ad09d|
|account_id|integer|账户id| 2|
|short_script_hash|string|短地址| 0x633b14f58a1343aeb43e9c68c8afb4c866ebb649|
|eth_address|sring|以太坊地址| 0x55824f0ed489feaaabd640459373dfb79c187dd2|
|layer1_script_hash|string|ckb链上的script hash| 0xe6c7befcbf4697f1a7f8f04ffb8de71f5304826af7bfce3e4d396483e935820a|

## Comment
- account_id can get by godwoken rpc: gw_get_account_id_by_script_hash
