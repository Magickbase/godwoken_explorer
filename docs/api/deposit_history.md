# DepositHistory
## List by eth address
```
GET /deposit_histories
```

### Parameters
|Name|Type|In|Description|
|---|---|---|---|
|eth_address|string|query|user eth address|
|page|integer|query|default is 1|

### Code samples

```console
curl https://api.gwscan.com/api/deposit_histories?eth_address=0x3657e473b62a5f3265f5a5a8bf640351199e2f3f
```

### Response

```
Status: 200 OK
```

```json
{
  data: [
    {
      attributes: {
        ckb_lock_hash: "0xf539266ebeebbc2084071b18e2659c6a46a21842ba60ec1e4f7787545be0c949",
        layer1_block_number: 4115268,
        layer1_output_index: 0,
        layer1_tx_hash: "0x16a32708d06ede268f562580cd597f8bf957564efde166d53a6f1968b3358631",
        timestamp: "2022-01-19T00:34:03.755000Z",
        udt_id: 1,
        value: "300"
        },
      id: "414500",
      relationships: {
        udt: {
          data: {
          id: "1",
          type: "udt"
          }
        }
      },
      type: "deposit_history"
    }
  ],
  included: [
    {
      attributes: {
        decimal: 8,
        description: null,
        holder_count: 23388,
        icon: null,
        id: 1,
        name: "Nervos Token",
        official_site: null,
        script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        eth_address: null,
        supply: "240000000000",
        symbol: "CKB",
        transfer_count: 0,
        type: "bridge",
        type_script: {
          args: "",
          code_hash: "",
          hash_type: ""
        },
        value: null
      },
      id: "1",
      relationships: { },
      type: "udt"
    }
  ],
  meta: {
    current_page: 1,
    total_page: 78
    }
}
