# API Doc

## API Domain

- Aggron network: https://api.staging.godwoken.nervina.cn
- Lina nertwork: https://api.godwoken.nervina.cn

## API List
### GET /api/accounts/{account_id | short_script_hash | eth_address}

> 查找账户

|params|type|description|eg.|
|----|----|----|---|
|account_id|integer|账户id| 2|
|short_script_hash|string|短地址| 0x633b14f58a1343aeb43e9c68c8afb4c866ebb649|
|eth_address|sring|以太坊地址| 0x55824f0ed489feaaabd640459373dfb79c187dd2|
|layer1_script_hash|string|ckb链上的script hash| 0xe6c7befcbf4697f1a7f8f04ffb8de71f5304826af7bfce3e4d396483e935820a|

### GET api/txs/{tx_hash}
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

### GET api/home
> 首页数据

- GET api/txs?(account_id={account_id} | eth_address={eth_address})&page={page}
> 查找某个账户下的交易

|params|type|description|eg.|
|----|----|----|---|
|account_id|integer|账户id| 2|
|eth_address|sring|以太坊地址| 0x55824f0ed489feaaabd640459373dfb79c187dd2|

### GET api/search?keyword={block_hash | tx_hash | account_id | short_script_hash | eth_address}
> 聚合搜索

|params|type|description|eg.|
|----|----|----|---|
|block_hash|string|交易哈希| 0x0a79180e50ce745f567ab38a0dc957abace0a8ee8265ffd4ad2bfbb33f9ad09d|
|tx_hash|string|交易哈希| 0x0a79180e50ce745f567ab38a0dc957abace0a8ee8265ffd4ad2bfbb33f9ad09d|
|account_id|integer|账户id| 2|
|short_script_hash|string|短地址| 0x633b14f58a1343aeb43e9c68c8afb4c866ebb649|
|eth_address|sring|以太坊地址| 0x55824f0ed489feaaabd640459373dfb79c187dd2|

### GET api/withdrawal_histories?owner_lock_hash={owner_lock_hash}&page={page}
> 提现记录

#### request params
|params|type|description|eg.|
|----|----|----|---|
|owner_lock_hash|string|交易哈希| 0x0a79180e50ce745f567ab38a0dc957abace0a8ee8265ffd4ad2bfbb33f9ad09d|
|page|integer|分页|default: 1|

#### response
```
{
  data: [
    {
      attributes: {
        # 转账数量
        amount: "111100000000",
        # layer2
        block_hash: "0xb865648238e90d8b2fa753e1821f36a2f30b8390765fcf22d120c34e13ef1187" ,
        # layer 2
        block_number: 99596,
        # layer2
        l2_script_hash: "0x708ffdf8ad4811baba49c0d5c7ac7a988b7302d1769900ec3813d215910ac90e",
        layer1_block_number: 3000099,
        layer1_output_index: 3,
        layer1_tx_hash: "0xe5e3792c663d2478661d4e764e0fcf713ddcb6f811f8a145248262b98626c78f",
        # layer1 block timestamp utc
        timestamp: "2021-10-05T10:03:45.560000Z",
        owner_lock_hash: "0x20cbccb98606bf938d2be5c1db994840852ec29a8fe5b7d955fb97450f4de1ef",
        payment_lock_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        # buyer udt script hash
        udt_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000"
        },
        sell_amount: "0",
        sell_capacity: "50000000000",
        # pending: 提现中 succeed: 成功提现
        state: "pending",
        udt_id: 2,
      id: "1",
      relationships: {
        udt: {
          data: {
            id: "2",
            type: "udt"
          }
        }
      },
      type: "withdrawal_history"
    }
  ],
  included: [
    {
      attributes: {
        decimal: 8,
        id: 1,
        script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        symbol: "CKB"
      },
      id: "1",
      relationships: { },
      type: "udt"
    }
  ],
  meta: {
    current_page: 1,
    total_page: 1
    }
  }
```
|params|type|description|eg.|
|----|----|----|---|
|data|array|主要数据|
|included|array|对应的 udt 信息
|meta|map|分页数据|

## Comment
- account_id can get by godwoken rpc: gw_get_account_id_by_script_hash
